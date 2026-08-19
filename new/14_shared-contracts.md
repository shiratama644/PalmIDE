<!-- 統合版: docs/14_shared-contracts.md の Phase 5 追記（R2/R3/R4/R5）を本文にマージ（Phase 4新規 → 統合） -->
# 14 共通契約 — 横断的インターフェース集約

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local%20AI%20Agent.md)（元ファイルには本章は存在しない。Phase 4 で新設した横断契約集約ファイルの統合版）
> **インデックス**: [README.md](./README.md)
> **関連ファイル**: [05_sandbox.md](./05_sandbox.md) | [06_model-selection.md](./06_model-selection.md) | [07_model-caching-tier.md](./07_model-caching-tier.md) | [08_ui-ux-workflow.md](./08_ui-ux-workflow.md) | [09_patch-engine.md](./09_patch-engine.md) | [10_logging-scribe.md](./10_logging-scribe.md) | [12_db-schema.md](./12_db-schema.md)

> **要約**: 本ファイルは横断的な契約（postMessage JSON-RPC 2.0、TDD各Phaseの型、GoogleGenAIクライアント初期化、コストレート定数、WebContainers分離アーキテクチャ、永続化状態型）の**単一ソース**である。各ファイルからは本ファイルを参照し、本ファイルの型定義を正とする。

> **ナビゲーション**: ← [13_roadmap.md](./13_roadmap.md) | [README.md](./README.md) →

---

## 1. postMessage JSON-RPC 2.0 契約

> 対象: [05_sandbox.md](./05_sandbox.md) §4、[09_patch-engine.md](./09_patch-engine.md) §7 が参照する `postMessage` 通信

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

### 1.4 メソッド一覧（確定版 — 承認済み）

| method | 方向 | params | result | 対応元 |
|---|---|---|---|---|
| `typeCheck` | Host→Sandbox | `TypeCheckParams` | `{ diagnostics: TsDiagnostic[] }` | §4 Wasm TS Service |
| `runTests` | Host→Sandbox | `{ files, testCommand: "vitest" \| "jest" }` | `{ passed: boolean; output: string }` | §4 Test Runner |
| `validateOutput` | Host→Sandbox | `{ json: unknown; schemaName: string }` | `{ valid: boolean; errors?: string[] }` | §4 Zod/AJV |
| `extractSkeleton` | Host→Sandbox | `{ files }` | `{ skeletons: Record<string, string> }` | §5.5 AST Skeleton |
| `applyPatch` | Host→Sandbox | `{ original, searchBlock, replaceBlock }` | `PatchResult`（§7.1） | §7.1 |
| `lint` | Host→Sandbox | `{ files }` | `{ lintErrors: string[] }` | §4 ESLint/Prettier |

> 本メソッド名は **レビューで承認・確定** 済み（`extractSkeleton` は `ASTContextRouter` との命名整合が取れているため採用）。実装時に追加・削除する必要がある場合は本ファイルのみを更新する。

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

## 2. TDD ワークフロー型契約

> 対象: [08_ui-ux-workflow.md](./08_ui-ux-workflow.md) §6.4 の Contract→Test→Impl→Approval の受け渡し

```typescript
// Phase 1: Contract（型定義・インターフェース）
interface ContractPhaseOutput {
  interfaces: string;          // 生成された .d.ts 相当の型定義コード
  skeleton: Record<string, string>; // AST Skeleton（ファイルパス→シグネチャJSON）
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

**`skeleton` の粒度（確定版）**: `skeleton` は **Tree-sitter 由来の JSON（型・シグネチャのみ）を文字列として保持**する（ランタイム分担決定に連動。Tree-sitter の言語横断性と増分パース性能を活かすため）。Babel 由来の文字列は QuickJS での軽量パース用に `skeletonText` として別フィールドで保持可能だが、主は JSON とする。QuickJS 側では `JSON.parse(skeleton)` で利用する。

### 2.1 StrictFuzzyPatch（厳密版 Fuzzy Patch ユーティリティ）

[09_patch-engine.md](./09_patch-engine.md) §7.1 の簡易版 `applyFuzzyPatch` のオフセットズレを解消する厳密版。正規化前後のオフセットマッピング表を保持し、正規化で文字数が変わっても元ファイルの正確な置換範囲を復元できる。

```typescript
interface OffsetMap { normalizedOffset: number; originalOffset: number; }
function buildOffsetMap(original: string, normalized: string): OffsetMap[] { /* 正規化前後の対応表を生成 */ return []; }
function strictApplyFuzzyPatch(original: string, searchBlock: string, replaceBlock: string): string {
  const normOrig = normalizeWhitespace(original);
  const normSearch = normalizeWhitespace(searchBlock);
  const idx = normOrig.indexOf(normSearch);
  if (idx === -1) return original;
  const map = buildOffsetMap(original, normOrig);
  const origIdx = map.find(m => m.normalizedOffset === idx)?.originalOffset ?? idx;
  return original.slice(0, origIdx) + replaceBlock + original.slice(origIdx + searchBlock.length);
}
```

検証に必須のテストケース5パターン（連続空白・タブ・CRLF・全角空白・空行の空白）は [09_patch-engine.md](./09_patch-engine.md) §7.1 を参照。

---

## 3. GoogleGenAI クライアントと Context Caching 契約

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

## 4. コストレート定数

```typescript
// 1M tokens あたりの USD（§5.1 表の値を定数化。将来の価格改定時は本テーブルのみ更新）
// `cached` は公式の cache hit 単価（標準入力の約10%）
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
```

Context Caching を利用する場合の確定版推計は、cache hit 単価に加えて **storage の時間課金** を加算する（公式 `ai.google.dev/gemini-api/docs/caching`: 課金要因は Cache token count + Storage duration）。

```typescript
function estimateCostWithCache(
  model: keyof typeof RATE_TABLE, input: number, output: number, cached: number,
  hours: number, tier: "flex"|"priority"
): number {
  const r = RATE_TABLE[model];
  const flexFactor = tier === "flex" ? 0.5 : 1.0;
  const storagePerHour = model === "gemini-3.1-pro" ? 4.50 : 1.00; // 公式の storage 価格（3.7/3.5は1.00、Proは4.50）
  return (input*r.input + output*r.output + cached*r.cached)/1e6 * flexFactor + (cached/1e6 * storagePerHour * hours);
}
// `hours` は ttlSeconds/3600。表示は toFixed(4)、ログでは estimated_usd と actual_usd を分離して記録
```

この式により、「75〜90%削減」の内訳（hit 割引約90% − storage 費）が明確になる。参考: 公式 `ai.google.dev/gemini-api/docs/pricing`（Context caching 価格表）を正とする。

> **レート管理**: 2026/12/31 以降は本テーブルを公式料金表に合わせて更新すること。コード内のハードコードを避けるため、将来的には `preferences` または外部JSONで上書き可能にする設計とする。

---

## 5. WebContainers 分離アーキテクチャ（決定済み）

2層化（A案）が正式採用された構成。全体図は [02_architecture.md](./02_architecture.md) §2.1 を正とする。

```
[Host (null origin sandbox)]  <--postMessage--> [WebContainers iframe (crossOriginIsolated)]
  - typeCheck, lint, etc.                    - npm install, node run, vite build
  - allow-scripts のみ                       - allow="cross-origin-isolated", COOP/COEP ヘッダ配信
```

- Host側のサンドボックスは `null origin` のまま（XSS耐性維持）
- WebContainers側は別オリジン（例: `https://wc.example.com`）で `Cross-Origin-Opener-Policy: same-origin` + `Cross-Origin-Embedder-Policy: require-corp` を配信
- 両iframe間の通信は Host を経由した `postMessage` リレーとする

---

## 6. 永続化状態型

> 対象: [04_storage-persist.md](./04_storage-persist.md) §3.2.1 の persist() フォールバック

```typescript
type PersistState = "granted" | "denied" | "prompt";
interface PersistCheckResult {
  state: PersistState;
  persisted: boolean; // navigator.storage.persist() の戻り値
}
```

---

## 7. 更新ルール

- 本ファイルが横断契約の単一ソース。新しい `method` や型を追加する際は、本ファイルのみを更新し、各ファイルは本ファイルを参照（リンク）する。
- 本ファイルの変更はレビューで横断的整合性を確認すること。

---

> **出典**: 本ファイルは横断的契約（G04/G06/G08/G14/G15/G05/G18）の集約として Phase 4 で新規作成され、Phase 5 の確定事項（R2 メソッド名 / R3 skeleton型 / R4 StrictFuzzyPatch / R5 コスト式）を本文に統合した統合版である。
