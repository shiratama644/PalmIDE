<!-- 統合版: docs/06_model-selection.md の Phase 4 追記（G06 Interactions API GA / G14 genAI初期化）を本文にマージ（元: Local_AI_Agent.md §5.1-5.3 Lines 163-187） -->
# 06 Geminiモデルオーケストレーション — モデル選定・Interactions API・CORS

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local%20AI%20Agent.md)（§5.1-5.3 Lines 163-187）
> **インデックス**: [README.md](./README.md)
> **関連ファイル**: [07_model-caching-tier.md](./07_model-caching-tier.md)（§5.4-5.5 バックオフ・キャッシュ） | [02_architecture.md](./02_architecture.md) | [08_ui-ux-workflow.md](./08_ui-ux-workflow.md) | [14_shared-contracts.md](./14_shared-contracts.md)（§3 GenAI初期化）

> **要約**: 本ファイルはGemini 3.xファミリー統一（3.7 Flash主軸 / 3.6 Flash / 3.5 Flash / 3.5 Flash-Lite / 3.1 Pro、コスト単価表）、Interactions API（2026-06-22 GA）対応と `GoogleGenAI` クライアント初期化、BYOK直接通信とCORS対策（Direct Fetch / Local Proxy）を定義する。

> **ナビゲーション**: ← [05_sandbox.md](./05_sandbox.md) | [07_model-caching-tier.md](./07_model-caching-tier.md) →

---

## 5. Google Gemini 3.x モデルオーケストレーション

### 5.1 使用モデル一覧（Gemini 3.x ファミリー統一）
推論の癖やFunction Callingの挙動破綻を防ぐため、モデルはGoogle Gemini 3.xファミリーに統一します。
(※Gemini 2.x系は2026年6月1日にシャットダウン済みのため一切使用しない)

| モデル | 主な役割 | 特徴・コスト (per 1M tokens) |
| :--- | :--- | :--- |
| Gemini 3.7 Flash | メイン推論・コード生成・修正・プランニング | 最新のコーディング特化モデル。思考モード対応。紹介価格適用中（〜2026/12/31） |
| Gemini 3.6 Flash | フォールバック 1 / 複雑な型エラー解決 | 高速・安定したコード生成（Antigravity等でも実績多数）。1.50 in / 7.50 out |
| Gemini 3.5 Flash | フォールバック 2 / エージェントワークフロー | 標準エージェントモデル（1.50 in / 9.00 out） |
| Gemini 3.5 Flash-Lite | Scribe Agent（ログ生成）/ AST抽出 | 超軽量・極小レイテンシ（0.15 in / 0.60 out） |
| Gemini 3.1 Pro | 巨大設計・難関リファクタリング | 200万トークン対応・最上位推論（2.00/12.00 @200K以下） |

### 5.2 Interactions API への対応
- Google公式の最新標準である Interactions API を通信プロトコルとして採用（**2026-06-22 にGA済み**。エンドポイントは `POST /v1beta/interactions`）。
- 単一の対話ストリーム内で、ツールの呼び出し（`tool_calls`）とステップ実行（`steps`）をスムーズに処理。
- 従来の `GenerateContent` も併用可能とし、段階的移行を可能にする。

SDK の呼び出し形状は以下の通り。`genAI.models.generateContent({model, contents})` はレガシー `generateContent` API の形状であり、新規コードは `interactions.create` を推奨とする（互換のため旧APIも維持）。

```typescript
import { GoogleGenAI } from "@google/genai";
// BYOK復号後の鍵で初期化（03_security-byok.md の decryptApiKey の戻り値）
const genAI = new GoogleGenAI({ apiKey: decryptedKey });
// 新（推奨）: Interactions API
const interaction = await genAI.interactions.create({
  model: "gemini-3.7-flash",
  input: prompt,
  // store: false で履歴保存を無効化可能（デフォルトは paid:55日保存）
});
// 旧（互換）: generateContent — 既存コードのフォールバックとして維持
// const res = await genAI.models.generateContent({ model: "gemini-3.7-flash", contents: prompt });
```

`store: false`（履歴保存の無効化）はプライバシー重視の設定として採用可否をユーザー設定で切り替え可能とする。

### 5.3 BYOK 直接通信と CORS 対策
- 基本通信路: `@google/genai` (公式 JavaScript SDK) を使用。Gemini API エンドポイントはブラウザからの直接 CORS リクエストを公式にサポートしている。
- フォールバック設計: 万が一の企業内プロキシ制限や将来のCORS仕様変更に備え、以下の拡張ポイントを設ける。
  - `Direct Fetch Mode`（デフォルト・標準）
  - `Local Proxy Mode`（ユーザーが手元で起動した `localhost:PORT` 経由へのルーティング設定）

`Direct Fetch Mode`（デフォルト）と `Local Proxy Mode` の切り替えは [14_shared-contracts.md](./14_shared-contracts.md) §3 の `GenAIClientConfig` 型を参照。

---

> **出典**: `Local_AI_Agent.md` §5.1-5.3（Lines 163-187）。Interactions API のGA裏付けとクライアント初期化形状（G06/G14補足）を本文に統合した統合版である。
> **相互参照**: [07_model-caching-tier.md](./07_model-caching-tier.md)（§5.4-5.5 バックオフ・キャッシュ） | [02_architecture.md](./02_architecture.md) | [08_ui-ux-workflow.md](./08_ui-ux-workflow.md) | [14_shared-contracts.md](./14_shared-contracts.md) | [README.md](./README.md)
