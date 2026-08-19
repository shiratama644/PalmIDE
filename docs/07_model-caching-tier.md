<!-- 元ファイル: Local_AI_Agent.md §5.4-5.5 Lines 188-275 -->
# 07 Geminiオーケストレーション — レート制限・Tierフォールバック・Context Caching

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local_AI_Agent.md)
> **インデックス**: [README.md](../README.md) | [Phase0設計書](../PHASE0_design.md)
> **関連ファイル**: [06_model-selection.md](./06_model-selection.md)（§5.1-5.3） | [09_patch-engine.md](./09_patch-engine.md)（§7.2でCache推奨） | [10_logging-scribe.md](./10_logging-scribe.md)（ScribeはFlex Tier） | [README.md](../README.md)
> **元セクション**: §5.4-5.5（Lines 188-275）

> **要約**: 本ファイルは429/RESOURCE_EXHAUSTED時の指数バックオフ（1s→2s→4s→8s）・Tierフォールバック（3.7F→3.6F→3.5F→3.5FL）、Context Caching（75〜90%削減、ttlSeconds最大3600）、Flex/Priority Tierを定義する。

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

---


> 🆕 **詳細化補足（Phase 4）— G07 紹介価格終了後**
> - **対象**: Gemini 3.7 Flash 紹介価格終了後（2026/12/31以降）の単価未記載
> - **種別**: 🟢補足
> - **内容**: 2027年以降の単価は未公表のため、本仕様では**単価をハードコードせず** `preferences` または `14_shared-contracts.md` §4 の `RATE_TABLE` を設定可能にすることを推奨。UIのコスト推計は `RATE_TABLE` を参照し、公式料金表更新時は設定ファイルのみ差し替え可能にする。
> - **根拠**: 推測で単価を書くと誤情報になるため。将来の価格改定に耐える設計とするため。

> 🆕 **詳細化補足（Phase 4）— G15 コスト計算式**
> - **対象**: コスト推計（tokens→USD）の計算式未定義
> - **種別**: 🟡要確認の解消
> - **内容**: 以下の叩き台式を提案する。
>   ```typescript
>   // レートは 14_shared-contracts.md §4 RATE_TABLE を参照（例: 3.7 Flash想定）
>   const rate = RATE_TABLE[model]; // { input: 1.50, output: 7.50, cached: 0.15 } per 1M
>   const estimated_usd = (input_tokens * rate.input + output_tokens * rate.output + cached_tokens * rate.cached) / 1_000_000;
>   // 表示は小数4桁、Approval Gateでは見積（estimated）、Logでは確定（actual）を記録
>   ```
>   `cached_tokens` は Context Caching 適用時の割引後トークン。`Flex` Tierは `rate * 0.5` で再計算。`08_ui-ux-workflow.md` の Approval Gateでは見積、`10_logging-scribe.md` のログでは確定値を `cost_estimate.estimated_usd` に記録するライフサイクルとする。
> - **根拠**: 仕様書 §5.1 表の単価と §5.5 の 75〜90%削減記述を数式化したもの。レートを外部定数化することで将来の価格変更に対応。

> 🆕 **詳細化補足（Phase 4）— 横断契約への参照（G04/G14）**
> - **対象**: `cacheName` / `genAI` 未定義、postMessageスキーマ
> - **種別**: 🔴Blocker解消（参照）
> - **内容**: `cacheName` は `createContextCache` の戻り値 `cachedContents/...` であり、初期化は [14_shared-contracts.md](./14_shared-contracts.md) §3 の `ContextCacheManager` 型を参照。postMessage詳細も同ファイル §1 を参照。
> - **根拠**: 単一ソース化のため。

> 🆕 **詳細化補足（Phase 5・レビュー反映）— R5 cached_tokens課金モデル再確認**
> - **指摘元**: REVIEW_DESIGN.md R5
> - **内容**: Web検索（2026-08-18）で **公式** `ai.google.dev/gemini-api/docs/pricing` を確認した。
>   - **Gemini 3.7 Flash（公式）**: 標準入力 $0.75/1M（〜2026-12-31）→ $1.50/1M（2027-01-01〜）、出力 $3.75→$7.50、Context caching（cache hit）$0.075→$0.15、Storage $0.50/h→$1.00/h（1Mあたり）
>   - **Gemini 3.5 Flash（公式）**: 標準入力 $1.50/1M、出力 $9.00/1M、Context caching $0.15/1M、Storage $1.00/1M/h
>   - **Gemini 3.1 Pro相当**: 標準入力 $2.00/1M、cached $0.20/1M（90%割引）、Storage $4.50/1M/h（第三者サイトでも同値を示すが、公式の3.7/3.5表を正とする）
>   従来の `flexFactor * cached` という推測は不正確で、正しくは **「cache hit は別単価（標準の約10%）＋ storageの時間課金」** が正しい。`estimateCost` は `RATE_TABLE` の `cached` を **cache hit 単価** として扱い、別途 `storageCost = tokenCount/1e6 * hourlyRate * hours` を加算する形に修正する。本補足をもって「要検証」は公式ソースで解消。
> - **根拠**: **公式** `https://ai.google.dev/gemini-api/docs/pricing`（Gemini 3.7 Flash / 3.5 Flash の Context caching 価格表）および `https://ai.google.dev/gemini-api/docs/caching`（Explicit caching の課金要因: Cache token count + Storage duration）。第三者サイト `evolink.ai` 等の90%割引の記述も公式の10% hit単価と一致することを確認。

---

> **出典**: `Local_AI_Agent.md` §5.4-5.5（Lines 188-275）を一字一句維持して分割
> **相互参照**: [06_model-selection.md](./06_model-selection.md)（§5.1-5.3） | [09_patch-engine.md](./09_patch-engine.md)（§7.2でCache推奨） | [10_logging-scribe.md](./10_logging-scribe.md)（ScribeはFlex Tier） | [README.md](../README.md)
