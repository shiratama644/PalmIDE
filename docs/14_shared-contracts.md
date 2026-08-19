<!-- 元ファイル: 新規（Phase 4 共通契約） — Local_AI_Agent.md には存在しない横断的契約を集約 -->
# 14 共通契約 — 横断的インターフェース集約（Phase 4 新規）

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local_AI_Agent.md)（元ファイルには本章は存在しない）
> **インデックス**: [README.md](../README.md) | [Phase0設計書](../PHASE0_design.md) | [Phase4-0ギャップ一覧](../PHASE4_0_gaplist.md)
> **関連ファイル**: [05_sandbox.md](./05_sandbox.md) | [06_model-selection.md](./06_model-selection.md) | [07_model-caching-tier.md](./07_model-caching-tier.md) | [08_ui-ux-workflow.md](./08_ui-ux-workflow.md) | [09_patch-engine.md](./09_patch-engine.md) | [10_logging-scribe.md](./10_logging-scribe.md) | [12_db-schema.md](./12_db-schema.md)
> **元セクション**: 新規（Phase 4でG04/G06/G08/G14/G15の横断的欠落を解消するため新設）

> **要約**: 本ファイルは、従来どのファイルにも定義がなかった横断的な契約（postMessage JSON-RPC 2.0、TDD各Phaseの型、GoogleGenAIクライアント初期化、コストレート定数）を単一ソースとして集約する。各ファイルの `> 🆕` 補足から本ファイルへリンクすることで、重複と矛盾を防ぐ。**本ファイル自体も `> 🆕` として作成されたものであり、原文の上書きではない。**

> **ナビゲーション**: ← [13_roadmap.md](./13_roadmap.md) | [README.md](../README.md) →

---

## 0. 本ファイルの位置づけ

- **作成理由**: G04（JSON-RPC未定義）、G08（TDD型契約未定義）、G14（genAI/cacheName未定義）、G15（コスト式未定義）は複数ファイルにまたがるため、分散して補足すると将来の変更で再び矛盾が生じる。単一ソースに集約する。
- **原文との関係**: 元仕様書 `Local_AI_Agent.md` には本章は存在しない。Phase 4で新規追加した共通契約であり、既存13ファイルの原文は一切書き換えていない。
- **運用**: 本ファイルの型定義が正とする。各ファイルの補足は本ファイルへの参照（リンク）で完結させる。

---

## 1. postMessage JSON-RPC 2.0 契約（G04）

> 対象: `05_sandbox.md` §4、`07_model-caching-tier.md` §5.4-5.5、`09_patch-engine.md` §7 が参照する `postMessage` 通信

### 1.1 基本ルール

- プロトコル: [JSON-RPC 2.0](https://www.jsonrpc.org/specification) に準拠
- トランスポート: `window.postMessage`（`iframe sandbox="allow-scripts"` → `null origin`）
- 検証: ホスト側は `event.origin === "null"` を必須チェック。`event.data` が JSON-RPC 形状でなければ破棄。
- `id` はホスト側で `crypto.randomUUID()` で生成し、Sandbox側は同一 `id` をレスポンスで返す。

### 1.2 リクエスト型（Host → Sandbox）

```typescript
interface JsonRpcRequest<P = unknown> {
  jsonrpc: "2.0";
  id: string;        // UUID
  method: string;    // 下記 §1.4 参照
  params: P;
}

// 例: 型チェック要求
type TypeCheckParams = {
  files: Record<string, string>; // path → content（差分適用後の仮想FS）
  tsConfig?: Record<string, unknown>;
};
type TypeCheckRequest = JsonRpcRequest<TypeCheckParams> & { method: "typeCheck" };
```

### 1.3 レスポンス型（Sandbox → Host）

```typescript
interface JsonRpcSuccess<R = unknown> {
  jsonrpc: "2.0";
  id: string;
  result: R;
}
interface JsonRpcError {
  jsonrpc: "2.0";
  id: string | null;
  error: { code: number; message: string; data?: unknown };
}
type JsonRpcResponse<R> = JsonRpcSuccess<R> | JsonRpcError;
```

### 1.4 想定メソッド一覧（叩き台）

| method | 方向 | params | result | 対応元 |
|---|---|---|---|---|
| `typeCheck` | Host→Sandbox | `TypeCheckParams` | `{ diagnostics: TsDiagnostic[] }` | §4 Wasm TS Service |
| `runTests` | Host→Sandbox | `{ files, testCommand: "vitest" \| "jest" }` | `{ passed: boolean; output: string }` | §4 Test Runner |
| `validateOutput` | Host→Sandbox | `{ json: unknown; schemaName: string }` | `{ valid: boolean; errors?: string[] }` | §4 Zod/AJV |
| `extractSkeleton` | Host→Sandbox | `{ files }` | `{ skeletons: Record<string, string> }` | §5.5 AST Skeleton |
| `applyPatch` | Host→Sandbox | `{ original, searchBlock, replaceBlock }` | `PatchResult`（§7.1） | §7.1 |
| `lint` | Host→Sandbox | `{ files }` | `{ lintErrors: string[] }` | §4 ESLint/Prettier |

> **注意**: 本メソッド一覧は叩き台。実装時に必要に応じて追加・削除してよいが、追加時は本ファイルのみを更新し、各ファイルの補足はリンクのままにする。

### 1.5 エラーコード

```typescript
const RPC_ERROR = {
  PARSE_ERROR: -32700,
  INVALID_REQUEST: -32600,
  METHOD_NOT_FOUND: -32601,
  INVALID_PARAMS: -32602,
  INTERNAL_ERROR: -32603,
  // アプリ固有
  TYPE_CHECK_FAILED: -32001,
  TESTS_FAILED: -32002,
} as const;
```

---

## 2. TDD ワークフロー型契約（G08）

> 対象: `08_ui-ux-workflow.md` §6.4 の Contract→Test→Impl→Approval の受け渡し

```typescript
// Phase 1: Contract（型定義・インターフェース）
interface ContractPhaseOutput {
  interfaces: string;          // 生成された .d.ts 相当の型定義コード
  skeleton: Record<string, string>; // AST Skeleton（ファイルパス→シグネチャ）
  notes?: string;              // 設計メモ
}

// Phase 2: Test（テストコード生成）— Red
interface TestPhaseOutput {
  testCode: string;            // 生成されたテストファイル内容
  testPath: string;            // 例: "src/components/Header.test.tsx"
  runResult: { passed: false; output: string }; // Red であること（失敗）が期待値
}

// Phase 3: Implementation（実装コード生成）— Green
interface ImplPhaseOutput {
  patch: { searchBlock: string; replaceBlock: string }; // §7.1 の SEARCH/REPLACE
  files: Record<string, string>; // パッチ適用後の全ファイル（検証用）
  runResult: { passed: boolean; output: string };
}

// Phase 4: Approval Gate
interface ApprovalGatePayload {
  diff: { path: string; searchBlock: string; replaceBlock: string }[];
  testResult: { passed: boolean; output: string };
  diagnostics: { message: string; severity: "error"|"warning" }[];
  cost: { input_tokens: number; output_tokens: number; cached_tokens: number; estimated_usd: number };
  model_used: string; // 例: "gemini-3.7-flash"
  tier_used: "flex" | "priority";
}

type TDDState = "contract" | "test" | "impl" | "approval" | "approved" | "rejected";
```

**状態遷移（08 §6.4 の図の型付き版）**:

```
[ユーザー指示: string] → ContractPhaseOutput → TestPhaseOutput → ImplPhaseOutput → ApprovalGatePayload → ("Approve" → commit / "Revise" → Implへ / "Reject" → discard)
```

各Phaseの出力は次のPhaseの入力としてそのまま `postMessage`（§1）でSandboxへ渡すことを想定。

---

## 3. GoogleGenAI クライアントと Context Caching 契約（G06 / G14）

### 3.1 クライアント初期化

```typescript
import { GoogleGenAI } from "@google/genai";

// 03_security-byok.md の decryptApiKey の戻り値を用いる
const genAI = new GoogleGenAI({ apiKey: decryptedApiKey });

// レガシー GenerateContent（互換）と Interactions API（推奨）の併用
// 既存コードの genAI.models.generateContent はそのまま動作するが、新規は interactions を推奨
```

### 3.2 設定型

```typescript
interface GenAIClientConfig {
  mode: "direct" | "localProxy"; // §5.3 Direct Fetch / Local Proxy
  proxyUrl?: string;             // mode==="localProxy" のとき必須（例: "http://localhost:8787"）
  tier: "flex" | "priority";     // §5.4 Flex/Priority
  useCache?: boolean;
  cachedContent?: string;        // cacheName（下記）
}
```

### 3.3 Context Caching 型

```typescript
interface CacheConfig {
  ttlSeconds: number;    // 最大3600
  displayName: string;
}
interface ContextCache {
  name: string;          // "cachedContents/abc123"
  model: string;
  displayName: string;
  ttlSeconds: number;
  createdAt: number;
  expiresAt: number;
  tokenCount: number;
}

async function createContextCache(
  systemPrompt: string,
  referenceDocs: string[],
  config: CacheConfig
): Promise<string>; // returns cache.name
// 呼び出し側で const cacheName = await createContextCache(...)
// その後 callGeminiWithRetry(prompt, 0, { useCache: true, cachedContent: cacheName })
```

### 3.4 Tier 順序

```typescript
const GEMINI_TIER_ORDER = ["gemini-3.7-flash","gemini-3.6-flash","gemini-3.5-flash","gemini-3.5-flash-lite"] as const;
```

---

## 4. コストレート定数（G07 / G15）

```typescript
// 1M tokens あたりの USD（§5.1 表の値を定数化。将来の価格改定時は本テーブルのみ更新）
const RATE_TABLE = {
  "gemini-3.7-flash":      { input: 1.50, output: 7.50, cached: 0.15 }, // 紹介価格（〜2026/12/31）
  "gemini-3.6-flash":      { input: 1.50, output: 7.50, cached: 0.15 },
  "gemini-3.5-flash":      { input: 1.50, output: 9.00, cached: 0.15 },
  "gemini-3.5-flash-lite": { input: 0.15, output: 0.60, cached: 0.04 },
  "gemini-3.1-pro":        { input: 2.00, output: 12.00, cached: 0.20 },
} as const;

function estimateCost(
  model: keyof typeof RATE_TABLE,
  input_tokens: number, output_tokens: number, cached_tokens: number,
  tier: "flex"|"priority" = "priority"
): number {
  const r = RATE_TABLE[model];
  const flexFactor = tier === "flex" ? 0.5 : 1.0;
  return (input_tokens * r.input + output_tokens * r.output + cached_tokens * r.cached) / 1_000_000 * flexFactor;
}
// 表示は toFixed(4)、ログでは estimated_usd と actual_usd を分離して記録
```

> **G07への対応**: 2026/12/31以降は本テーブルを公式料金表に合わせて更新すること。コード内のハードコードを避けるため、将来的には `preferences` または外部JSONで上書き可能にする設計を推奨。

---

## 5. WebContainers 分離アーキテクチャ（G05）

> G05の2層化案（推奨）の補足。`02_architecture.md` の図に将来反映する際の叩き台。

```
[Host (null origin sandbox)]  <--postMessage--> [WebContainers iframe (crossOriginIsolated)]
  - typeCheck, lint, etc.                    - npm install, node run, vite build
  - allow-scripts のみ                       - allow="cross-origin-isolated", COOP/COEP ヘッダ配信
```

- Host側の `05_sandbox.md` は `null origin` のまま（XSS耐性維持）
- WebContainers側は別オリジン（例: `https://wc.example.com`）で `Cross-Origin-Opener-Policy: same-origin` + `Cross-Origin-Embedder-Policy: require-corp` を配信
- 両iframe間の通信は Host を経由した `postMessage` リレーとする

---

## 6. 永続化状態型（G18）

```typescript
type PersistState = "granted" | "denied" | "prompt";
interface PersistCheckResult {
  state: PersistState;
  persisted: boolean; // navigator.storage.persist() の戻り値
}
```

---

## 7. 今後の更新ルール

- 本ファイルが横断契約の単一ソース。新しい `method` や型を追加する際は、本ファイルのみを更新し、各ファイルの `> 🆕` からリンクする。
- 本ファイルの変更は `PHASE4_report.md` に記録し、レビューで横断的整合性を確認すること。

> 🆕 **詳細化補足（Phase 5・決定反映）— R2 メソッド名確定**
> - **決定**: 現行案 `typeCheck` / `runTests` / `validateOutput` / `extractSkeleton` / `applyPatch` / `lint` を **承認・確定** する。
> - **不採用案**: 名称変更案はなし。`extractSkeleton` は `ASTContextRouter` との命名整合が取れており、他候補（`getSkeleton`/`parseAST`）よりも意図が明確なため現行維持。
> - **影響**: 本決定により `14` §1.4 のメソッド一覧が正式版となる。各ファイルの `> 🆕（Phase 4）` で参照しているリンクは変更不要。

> 🆕 **詳細化補足（Phase 5・決定反映）— R3 skeleton型**
> - **決定**: G03の A案（分担）決定に連動し、`skeleton` は **Tree-sitter 由来の JSON（型・シグネチャのみ）** を正とする。Babel 文字列は QuickJS での軽量パース用に `skeletonText` として別フィールドで保持可能だが、主は JSON。
> - **不採用案**: Babel文字列一本化は、Tree-sitterの言語横断性（TS/JS/Python）と増分パース性能を活かせないため不採用。
> - **影響**: `14` §2 の `ContractPhaseOutput.skeleton: Record<string,string>` は JSON文字列を値に持つものとして扱う。QuickJS 側では `JSON.parse(skeleton)` で利用。

> 🆕 **詳細化補足（Phase 5・レビュー反映）— R4 StrictFuzzyPatch**
> - **指摘元**: REVIEW_DESIGN.md R4
> - **内容**: 以下の厳密版ユーティリティを本ファイル §2 に追加する（叩き台）。
>   ```typescript
>   interface OffsetMap { normalizedOffset: number; originalOffset: number; }
>   function buildOffsetMap(original: string, normalized: string): OffsetMap[] { /* 正規化前後の対応表を生成 */ return []; }
>   function strictApplyFuzzyPatch(original: string, searchBlock: string, replaceBlock: string): string {
>     const normOrig = normalizeWhitespace(original);
>     const normSearch = normalizeWhitespace(searchBlock);
>     const idx = normOrig.indexOf(normSearch);
>     if (idx === -1) return original;
>     const map = buildOffsetMap(original, normOrig);
>     const origIdx = map.find(m => m.normalizedOffset === idx)?.originalOffset ?? idx;
>     return original.slice(0, origIdx) + replaceBlock + original.slice(origIdx + searchBlock.length);
>   }
>   ```
>   本関数は `09_patch-engine.md` から参照されることを想定。

> 🆕 **詳細化補足（Phase 5・レビュー反映）— R5 RATE_TABLE 修正**
> - **指摘元**: REVIEW_DESIGN.md R5
> - **内容**: `RATE_TABLE` の `cached` は **公式の cache hit 単価（標準の約10%）** として定義し直す。公式 `ai.google.dev/gemini-api/docs/pricing` によれば、例: 3.7 Flash $0.075→$0.15/1M、3.5 Flash $0.15/1M、Storage $0.50→$1.00/h（1Mあたり）。`estimateCost` は以下の式に修正する。
>   ```typescript
>   function estimateCostWithCache(model: keyof typeof RATE_TABLE, input: number, output: number, cached: number, hours: number, tier: "flex"|"priority"): number {
>     const r = RATE_TABLE[model];
>     const flexFactor = tier==="flex"?0.5:1.0;
>     const storagePerHour = model==="gemini-3.1-pro" ? 4.50 : 1.00; // 公式の storage 価格（3.7/3.5は1.00、Proは4.50）
>     return (input*r.input + output*r.output + cached*r.cached)/1e6 * flexFactor + (cached/1e6 * storagePerHour * hours);
>   }
>   ```
>   `hours` は `ttlSeconds/3600`。本修正により、従来の `75〜90%削減` という記述の内訳（hit割引90% - storage費）が明確になる。
> - **根拠**: **公式** `https://ai.google.dev/gemini-api/docs/pricing`（Context caching 価格表）および `https://ai.google.dev/gemini-api/docs/caching`（課金要因: Cache token count + Storage duration）。第三者サイトの90%割引も公式の10%単価と一致。

---

> **出典**: 本ファイルは Phase 4 で新規作成（G04/G06/G08/G14/G15/G05/G18 の横断的契約を集約）。元ファイル `Local_AI_Agent.md` には存在しない。
