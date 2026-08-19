<!-- 統合版: docs/07_model-caching-tier.md の Phase 4〜5 追記（G07 レート外部化 / G15 コスト式 / R5 cached課金モデル）を本文にマージ（元: Local_AI_Agent.md §5.4-5.5 Lines 188-275） -->
# 07 Geminiオーケストレーション — レート制限・Tierフォールバック・Context Caching

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local%20AI%20Agent.md)（§5.4-5.5 Lines 188-275）
> **インデックス**: [README.md](./README.md)
> **関連ファイル**: [06_model-selection.md](./06_model-selection.md)（§5.1-5.3） | [09_patch-engine.md](./09_patch-engine.md)（§7.2でCache推奨） | [10_logging-scribe.md](./10_logging-scribe.md)（ScribeはFlex Tier） | [14_shared-contracts.md](./14_shared-contracts.md)（§3 Cache型 / §4 コストレート）

> **要約**: 本ファイルは429/RESOURCE_EXHAUSTED時の指数バックオフ（1s→2s→4s→8s）・Tierフォールバック（3.7F→3.6F→3.5F→3.5FL）、Context Caching（75〜90%削減、ttlSeconds最大3600）、Flex/Priority Tier、およびコスト推計式（cache hit 別単価＋storage時間課金、公式料金表準拠）を定義する。

> **ナビゲーション**: ← [06_model-selection.md](./06_model-selection.md) | [08_ui-ux-workflow.md](./08_ui-ux-workflow.md) →

---

### 5.4 レート制限（429 / RESOURCE_EXHAUSTED）バックオフ ＆ コスト最適化
1. 指数バックオフ: 429 エラー検知時は、ジッター付き指数バックオフ（1s → 2s → 4s → 8s）で同一モデル内で再試行。
2. Tier フォールバック: 上限到達時は `3.7 Flash` → `3.6 Flash` → `3.5 Flash` → `3.5 Flash-Lite` へ自動切り替え。
3. Context Caching: システムプロンプトやプロジェクト共通の型定義（AST Skeleton）をキャッシュし、通信コストを 75〜90% 削減。
4. Flex / Priority Tier: 2026年4月に導入された Flex Tier と Priority Tier を活用。
   - Priority: 緊急のリアルタイムタスク。標準レート、最優先処理。
   - Flex: バッチ処理・非緊急タスク（Scribeログ等）。最大50%割引、キューイング許容。

```typescript
const GEMINI_TIER_ORDER = [
  "gemini-3.7-flash",
  "gemini-3.6-flash",
  "gemini-3.5-flash",
  "gemini-3.5-flash-lite"
];

async function callGeminiWithRetry(
  prompt: any,
  tierIndex = 0,
  options?: { useCache?: boolean; tier?: "flex" | "priority" }
): Promise<any> {
  const model = GEMINI_TIER_ORDER[tierIndex];
  const MAX_RETRIES = 3;

  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    try {
      return await genAI.models.generateContent({
        model,
        contents: prompt,
        config: {
          responseMimeType: "application/json",
          ...(options?.tier && { tier: options.tier }),
          ...(options?.useCache && { cachedContent: cacheName }),
        },
      });
    } catch (error: any) {
      const isRateLimit = error.status === 429 
        || error.message?.includes("RESOURCE_EXHAUSTED");

      if (isRateLimit && attempt < MAX_RETRIES) {
        const delay = Math.pow(2, attempt) * 1000 + Math.random() * 1000;
        await new Promise(r => setTimeout(r, delay));
        continue;
      }

      if (isRateLimit && tierIndex < GEMINI_TIER_ORDER.length - 1) {
        console.warn(`[Tier Fallback] ${model} 制限。${GEMINI_TIER_ORDER[tierIndex + 1]} にフォールバック。`);
        return callGeminiWithRetry(prompt, tierIndex + 1, options);
      }
      throw error;
    }
  }
}
```

上記コード中の `genAI` / `cacheName` の初期化は共通契約に集約する。`cacheName` は `createContextCache` の戻り値（`cachedContents/...`）であり、初期化と `ContextCacheManager` 型は [14_shared-contracts.md](./14_shared-contracts.md) §3 を参照。postMessage 通信のスキーマは同 §1 を参照。

### 5.5 Context Caching（コンテキストキャッシュ）によるコスト最適化
システムプロンプト、プロジェクトのAST Skeleton、参照ドキュメントなど、頻繁に再利用されるコンテキストをキャッシュし、75〜90%のコスト削減 を実現する。

```typescript
interface CacheConfig {
  ttlSeconds: number;      // キャッシュ有効期限（最大3600秒）
  displayName: string;     // キャッシュ識別名
}

async function createContextCache(
  systemPrompt: string,
  referenceDocs: string[],
  config: CacheConfig
): Promise<string> {
  const contents = [
    { role: "user", parts: [{ text: systemPrompt }] },
    ...referenceDocs.map(doc => ({ role: "user", parts: [{ text: doc }] }))
  ];

  const cache = await genAI.caches.create({
    model: "gemini-3.6-flash",
    config: {
      contents,
      ttlSeconds: config.ttlSeconds,
      displayName: config.displayName,
    },
  });
  return cache.name; // 例: "cachedContents/abc123"
}
```

### 5.6 コスト推計式とレート管理

**レートはコードにハードコードせず**、[14_shared-contracts.md](./14_shared-contracts.md) §4 の `RATE_TABLE` を参照する。Gemini 3.7 Flash の紹介価格終了後（2026/12/31以降）の単価は未公表のため、UIのコスト推計は `RATE_TABLE` を参照し、公式料金表の更新時はテーブル（将来は `preferences` または外部JSON）のみ差し替えられる設計とする。

**cached_tokens の課金モデル（公式確認済み）**: cache hit は「割引率」ではなく **「別単価（標準入力の約10%）＋ storage の時間課金」** である。公式料金表（`ai.google.dev/gemini-api/docs/pricing`、2026-08-18確認）によると、例えば Gemini 3.7 Flash は Context caching $0.075/1M（紹介期間）→ $0.15/1M（通常）、Storage $0.50→$1.00/1M tokens/h。課金要因は **Cache token count** と **Storage duration (TTL)** の2軸（`ai.google.dev/gemini-api/docs/caching`）。従来の `flexFactor * cached` という仮定はこの公式モデルで訂正された。

```typescript
// レートは 14_shared-contracts.md §4 RATE_TABLE を参照（例: 3.7 Flash想定）
const rate = RATE_TABLE[model]; // { input: 1.50, output: 7.50, cached: 0.15 } per 1M — cached は cache hit 単価
const estimated_usd =
  ((input_tokens * rate.input + output_tokens * rate.output + cached_tokens * rate.cached) / 1_000_000) * flexFactor
  + (cached_tokens / 1_000_000 * storagePerHour * hours); // storage の時間課金を加算
// 表示は小数4桁。Flex Tier は rate 部分に flexFactor (0.5) を適用
```

**ライフサイクル**: `08_ui-ux-workflow.md` の Approval Gate では見積（`estimated_usd`）を表示し、`10_logging-scribe.md` の Scribe ログ確定時に確定値（`actual_usd`）を再計算して `cost_estimate` に記録する。`tier_used: "flex" | "priority"` に応じてレートを切り替える詳細は [14_shared-contracts.md](./14_shared-contracts.md) §4 の `estimateCostWithCache` を参照。

---

> **出典**: `Local_AI_Agent.md` §5.4-5.5（Lines 188-275）。レート外部化（G07）、コスト式（G15）、cached課金モデルの公式訂正（R5）を本文に統合した統合版である。
> **相互参照**: [06_model-selection.md](./06_model-selection.md)（§5.1-5.3） | [09_patch-engine.md](./09_patch-engine.md)（§7.2でCache推奨） | [10_logging-scribe.md](./10_logging-scribe.md)（ScribeはFlex Tier） | [14_shared-contracts.md](./14_shared-contracts.md) | [README.md](./README.md)
