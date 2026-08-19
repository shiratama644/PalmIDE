<!-- 元ファイル: Local_AI_Agent.md §5.1-5.3 Lines 163-187 -->
# 06 Geminiモデルオーケストレーション — モデル選定・Interactions API・CORS

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local_AI_Agent.md)
> **インデックス**: [README.md](../README.md) | [Phase0設計書](../PHASE0_design.md)
> **関連ファイル**: [07_model-caching-tier.md](./07_model-caching-tier.md)（§5.4-5.5 バックオフ・キャッシュ） | [02_architecture.md](./02_architecture.md) | [08_ui-ux-workflow.md](./08_ui-ux-workflow.md) | [README.md](../README.md)
> **元セクション**: §5.1-5.3（Lines 163-187）

> **要約**: 本ファイルはGemini 3.xファミリー統一（3.7 Flash主軸 / 3.6 Flash / 3.5 Flash / 3.5 Flash-Lite / 3.1 Pro、コスト単価表）、Interactions API対応、BYOK直接通信とCORS対策（Direct Fetch / Local Proxy）を定義する。

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
- Google公式の最新標準である Interactions API を通信プロトコルとして採用。
- 単一の対話ストリーム内で、ツールの呼び出し（`tool_calls`）とステップ実行（`steps`）をスムーズに処理。
- 従来の `GenerateContent` も併用可能とし、段階的移行を可能にする。

### 5.3 BYOK 直接通信と CORS 対策
- 基本通信路: `@google/genai` (公式 JavaScript SDK) を使用。Gemini API エンドポイントはブラウザからの直接 CORS リクエストを公式にサポートしている。
- フォールバック設計: 万が一の企業内プロキシ制限や将来のCORS仕様変更に備え、以下の拡張ポイントを設ける。
  - `Direct Fetch Mode`（デフォルト・標準）
  - `Local Proxy Mode`（ユーザーが手元で起動した `localhost:PORT` 経由へのルーティング設定）


> 🆕 **詳細化補足（Phase 4）**
> - **対象**: `Interactions API` の実在性とSDK呼び出し形状の乖離（G06）、`genAI` 初期化未定義（G14）
> - **種別**: 🟢補足 / 🔴Blocker解消
> - **内容**: Web検索（2026-08-18）で **Interactions APIは2026-06-22にGA済み** と確認。公式は `POST /v1beta/interactions`、SDKは `import { GoogleGenAI } from "@google/genai"` → `new GoogleGenAI({apiKey})` → `client.interactions.create({model, input})` が正式。仕様書の `genAI.models.generateContent({model, contents})` はレガシー `generateContent` APIの形状である。**両APIを併用可能** とし、段階的移行を推奨する叩き台を提示する。
>   ```typescript
>   import { GoogleGenAI } from "@google/genai";
>   // BYOK復号後の鍵で初期化（03_security-byok.md の decryptApiKey の戻り値）
>   const genAI = new GoogleGenAI({ apiKey: decryptedKey });
>   // 新（推奨）: Interactions API
>   const interaction = await genAI.interactions.create({
>     model: "gemini-3.7-flash",
>     input: prompt,
>     // store: false で履歴保存を無効化可能（デフォルトは paid:55日保存）
>   });
>   // 旧（互換）: generateContent — 既存コードのフォールバックとして維持
>   // const res = await genAI.models.generateContent({ model: "gemini-3.7-flash", contents: prompt });
>   ```
>   `Direct Fetch Mode`（デフォルト）と `Local Proxy Mode` の切り替えは `14_shared-contracts.md` §3 の `GenAIClientConfig` 型を参照。
> - **根拠**: Google公式ブログ（2026-06-22 GA）および `google-gemini/gemini-skills` の `gemini-interactions-api` Skillで上記形状が公式と一致することを確認。`Interactions API` という名称は実在し、仕様書の記述は正しいが、コード例の形状だけ補足が必要だったため。
> - **要検証**: 本プロダクトが `store:false` を使うか（プライバシー重視）否かは人間判断。

---

> **出典**: `Local_AI_Agent.md` §5.1-5.3（Lines 163-187）を一字一句維持して分割
> **相互参照**: [07_model-caching-tier.md](./07_model-caching-tier.md)（§5.4-5.5 バックオフ・キャッシュ） | [02_architecture.md](./02_architecture.md) | [08_ui-ux-workflow.md](./08_ui-ux-workflow.md) | [README.md](../README.md)
