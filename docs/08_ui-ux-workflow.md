<!-- 元ファイル: Local_AI_Agent.md §6 Lines 276-345 -->
# 08 モバイルUI/UXとHuman-in-the-Loop TDDワークフロー

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local_AI_Agent.md)
> **インデックス**: [README.md](../README.md) | [Phase0設計書](../PHASE0_design.md)
> **関連ファイル**: [05_sandbox.md](./05_sandbox.md)（Wasm検証） | [09_patch-engine.md](./09_patch-engine.md)（パッチ適用） | [10_logging-scribe.md](./10_logging-scribe.md)（承認ログ） | [README.md](../README.md)
> **元セクション**: §6（Lines 276-345）

> **要約**: 本ファイルはモバイル特化UI（タブ切替・Diff承認ゲート・Live Preview・Monaco）、HITL承認ゲート付きTDD（Contract→Test→Impl→Approval）と3つの動作モード（Interactive/Auto-Pilot/Cost-Aware）を定義する。

> **ナビゲーション**: ← [07_model-caching-tier.md](./07_model-caching-tier.md) | [09_patch-engine.md](./09_patch-engine.md) →

---

## 6. モバイル特化型 UI/UX ＆ Human-in-the-Loop TDD ワークフロー

### 6.1 モバイル向け Claude Code インターフェース
PCの複雑な3ペインUI（ツリー・エディタ・ターミナル）を廃止し、スマホに最適化されたタブ切替型モバイルインターフェースを採用。

```text
┌──────────────────────────────────────────┐
│  [Project: my-react-app]    [⚙ Settings] │
├──────────────────────────────────────────┤
│                                          │
│  🤖 Agent:                              │
│  ヘッダーのナビゲーションバーを作成し、    │
│  レスポンシブ対応を追加しました。         │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ 📄 src/components/Header.tsx (+42) │  │
│  │ ---------------------------------- │  │
│  │ + export const Header = () => {    │  │
│  │ +   return <nav>...</nav>;         │  │
│  │ + };                               │  │
│  └────────────────────────────────────┘  │
│                                          │
├──────────────────────────────────────────┤
│  [  ❌ Reject  ]     [  ✅ Approve (適用) ] │ ◀── 片手でタップ/スワイプ承認
├──────────────────────────────────────────┤
│  > チャットで指示...                 [↑] │
├──────────────────────────────────────────┤
│  [ 💬 Chat ]  [ 📄 Code ]  [ 🌐 Preview ] │ ◀── ボトムナビゲーション
└──────────────────────────────────────────┘
```

### 6.2 片手で操作できる「Diff承認ゲート（Approval Gate）」
1. エージェントがコードを生成すると、IndexedDBへの適用前に「Diffプレビュー」を画面にカード形式で提示。
2. ユーザーは「Approve（承認）」を押すだけで、パッチがIndexedDBに適用されスナップショットが記録される。
3. 気に入らない場合は「Reject（却下）」または「修正指示」をチャットで送信。

### 6.3 アプリ内 Web Live Preview
- 生成されたHTML/CSS/JSは、ブラウザ内の `Blob URL` または `srcdoc iframe` を用いて、別タブを開かずにアプリ内の「Preview」タブで即座に動作確認可能。

### 6.4 Human-in-the-Loop 承認ゲート付き TDD ワークフロー
エージェントが勝手にファイルを書き換えて破壊するのを防ぐため、UI上の 承認ゲート（Approval Gate） を必須化する。

```text
[ユーザー指示]
     │
     ▼
【Phase 1: Contract (型定義・インターフェース)】 ──> [Wasm型チェック + Structured Output検証]
     │
     ▼
【Phase 2: Test (テストコード生成)】 ───────────> [Wasmテスト事前検証 (Red)]
     │
     ▼
【Phase 3: Implementation (実装コード生成)】 ───> [Wasmテスト検証 (Green)]
     │
     ▼
【Phase 4: 承認ゲート (Approval Gate)】 ◀───────── [★ Human-in-the-Loop]
     │
     ├── ［ 画面に Live Diff & テスト結果 & コスト推計を表示 ］
     │      ├── [ 承認 (Approve) ] ──> IndexedDBへコミット ＆ スナップショット作成
     │      ├── [ 修正指示 (Revise) ] ──> 指示をフィードバックしてPhase 3へ差し戻し
     │      └── [ 却下 (Reject) ] ──> 変更を破棄 ＆ スナップショット復元
```

### 6.5 設定可能な動作モード
- Interactive Mode（推奨・デフォルト）: パッチ適用前に必ずDiffの承認を要求。
- Auto-Pilot Mode: 型チェックとテストがパスした場合のみ自動適用（ワンクリックで切り替え可能）。
- Cost-Aware Mode: 推定コストが閾値を超える場合、必ず承認を要求。

---


> 🆕 **詳細化補足（Phase 4）— 横断契約への参照（G08）**
> - **対象**: Contract→Test→Implの各Phase間で受け渡すデータ型未定義
> - **種別**: 🔴Blocker解消（参照）
> - **内容**: 各Phaseの入出力型は [14_shared-contracts.md](./14_shared-contracts.md) §2 に集約した。`ContractPhaseOutput{ interfaces: ... }` → `TestPhaseOutput{ testCode: ... }` → `ImplPhaseOutput{ patch: ... }` → `ApprovalGatePayload{ diff, testResult, cost }` の流れを参照。
> - **根拠**: 型契約を単一ファイルに集約し、08・09間の不整合を防ぐため。

> 🆕 **詳細化補足（Phase 4）— G09 Reviseループ上限**
> - **対象**: 「修正指示（Revise）」ループの最大リトライ回数未定義
> - **種別**: 🟡要確認の解消
> - **内容**: 叩き台として **最大3回** を推奨。`preferences` に `maxReviseRetries: number = 3` を新設し、3回超過で「承認ゲートで却下し、指示を具体化してください」のトーストを出す。`Auto-Pilot Mode` でも同一上限を適用し、無限ループを防止。
>   ```typescript
>   if (reviseCount >= preferences.maxReviseRetries) {
>     showToast("修正が3回失敗しました。指示を具体化するか、一度却下してください。");
>     return "REJECT";
>   }
>   ```
> - **根拠**: 3回はLLMの自己修正で収束する経験則の閾値であり、UX上のストレスとコストのバランスが取れるため。値は設定可能にしておき、将来的に人間が調整可能。

---

> **出典**: `Local_AI_Agent.md` §6（Lines 276-345）を一字一句維持して分割
> **相互参照**: [05_sandbox.md](./05_sandbox.md)（Wasm検証） | [09_patch-engine.md](./09_patch-engine.md)（パッチ適用） | [10_logging-scribe.md](./10_logging-scribe.md)（承認ログ） | [README.md](../README.md)
