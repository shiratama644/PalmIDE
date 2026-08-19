# Rule 02: 不変値（絶対に変更しない定数・識別子）

> 優先度: **CRITICAL**。これらの値を変える変更は「壊れた diff」として REVIEW で差し戻される。

## 1. 不変値リスト

### 暗号化・セキュリティ
- `AES-GCM-256`、`PBKDF2`、`600,000 iterations` / `600000`、`SHA-256`
- `256-bit Salt`（32 bytes）、`96-bit IV`（12 bytes）、`OperationError`
- セッション破棄: 5分無操作でメモリ参照を `null` 化
- Web Crypto API のみ（外部暗号ライブラリは使用しない）

### DB / ストレージ
- DB名 `UnifiedAgentIDE_DB`、現行 v4（v5移行は `maxReviseRetries` 追加のみで計画済み）
- 5ストア: `files` / `snapshots` / `security` / `contextCaches` / `preferences`
- `navigator.storage.persist()`、`StorageManager.estimate()`
- `security` キー: `"gemini_api_key"` / `"github_pat"`

### Sandbox / 通信
- `iframe sandbox="allow-scripts"`（`allow-same-origin` なし → `null origin`）
- WebContainers は別オリジン `crossOriginIsolated` iframe（`allow="cross-origin-isolated"` + COOP `same-origin` + COEP `require-corp`）
- `postMessage` / JSON-RPC 2.0 / `event.origin === "null"` 検証 / `crypto.randomUUID()`
- 排他: `navigator.locks.request("scribe-wal", { mode: "exclusive" })`、フォールバック `BroadcastChannel`

### Gemini・コスト
- 5モデル: `gemini-3.7-flash` / `gemini-3.6-flash` / `gemini-3.5-flash` / `gemini-3.5-flash-lite` / `gemini-3.1-pro`
- `GEMINI_TIER_ORDER` の順序: 3.7 → 3.6 → 3.5 → 3.5-lite
- コストレートの正は **`new/14_shared-contracts.md` §4 `RATE_TABLE` のみ**。コード・文書におけるレートのハードコード禁止
- cached は「cache hit 単価（≈10%）+ storage 時間課金」のみ（旧仮定 `flexFactor * cached` を復活させない）

### ワークフロー・パッチ
- TDD 4フェーズ固定: `Contract → Test → Impl → Approval`
- エラー種別: `"NO_MATCH" | "AMBIGUOUS_MATCH" | "SYNTAX_ERROR" | "VALIDATION_FAILED"`
- 前後5行ルール、300行閾値、`maxReviseRetries` デフォルト 3
- 確定メソッド6件: `typeCheck` / `runTests` / `validateOutput` / `extractSkeleton` / `applyPatch` / `lint`

## 2. 変更時の機械検証（必須実行）

変更を加えたコミットの前に、必ず以下を実行し結果を0件で報告する。

```bash
# (1) 許容外の 🆕/⚠️ が new/ にないこと（引用ブロック形式のみ対象。
#     本文見出し（例: `## ⚠️ 発生したエラー`）は正当な仕様なので誤検出させない）
grep -nH '^>[^>]*\(🆕\|⚠️\)' new/*.md | grep -v 'new/README.md'   # → 0件であること

# (2) 主要識別子がすべて残っていること（代表例。PR本文に「全保持」あれば確認省略可）
for k in AES-GCM-256 PBKDF2 600,000 96-bit\ IV 256-bit\ Salt UnifiedAgentIDE_DB \
          allow-scripts "null origin" crossOriginIsolated JSON-RPC navigator.locks scribe-wal \
          AMBIGUOUS_MATCH NO_MATCH SYNTAX_ERROR VALIDATION_FAILED maxReviseRetries \
          RATE_TABLE estimateCostWithCache GEMINI_TIER_ORDER StrictFuzzyPatch \
          ContractPhaseOutput TestPhaseOutput ImplPhaseOutput ApprovalGatePayload TDDState \
          typeCheck runTests validateOutput extractSkeleton applyPatch; do
  grep -lq "$k" new/*.md || echo "MISSING: $k"
done
```
