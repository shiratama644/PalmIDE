<!-- 統合版: docs/08_ui-ux-workflow.md の Phase 4 追記（G08 TDD型契約参照 / G09 Revise上限）を本文にマージ（元: Local_AI_Agent.md §6 Lines 276-345） -->
# 08 モバイルUI/UXとHuman-in-the-Loop TDDワークフロー

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local%20AI%20Agent.md)（§6 Lines 276-345）
> **インデックス**: [README.md](./README.md)
> **関連ファイル**: [05_sandbox.md](./05_sandbox.md)（Wasm検証） | [09_patch-engine.md](./09_patch-engine.md)（パッチ適用） | [10_logging-scribe.md](./10_logging-scribe.md)（承認ログ） | [14_shared-contracts.md](./14_shared-contracts.md)（§2 TDD型契約）

> **要約**: 本ファイルはモバイル特化UI（タブ切替・Diff承認ゲート・Live Preview・Monaco）、HITL承認ゲート付きTDD（Contract→Test→Impl→Approval）、3つの動作モード（Interactive/Auto-Pilot/Cost-Aware）、および Reviseループ上限（デフォルト3回）を定義する。

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

各Phase間で受け渡すデータ型は共通契約に集約する。`ContractPhaseOutput{ interfaces: ... }` → `TestPhaseOutput{ testCode: ... }` → `ImplPhaseOutput{ patch: ... }` → `ApprovalGatePayload{ diff, testResult, cost }` の流れの正式な型定義は [14_shared-contracts.md](./14_shared-contracts.md) §2 を参照。

### 6.5 設定可能な動作モード
- Interactive Mode（推奨・デフォルト）: パッチ適用前に必ずDiffの承認を要求。
- Auto-Pilot Mode: 型チェックとテストがパスした場合のみ自動適用（ワンクリックで切り替え可能）。
- Cost-Aware Mode: 推定コストが閾値を超える場合、必ず承認を要求。

### 6.6 修正指示（Revise）ループの上限

Reviseループの収束を保証するため、**最大リトライ回数を `preferences` の `maxReviseRetries`（デフォルト 3）** として定義する。3回超過で「承認ゲートで却下し、指示を具体化してください」のトーストを出す。`Auto-Pilot Mode` でも同一上限を適用し、無限ループを防止する。値は設定可能とし、将来的にユーザーが調整できる。

```typescript
if (reviseCount >= preferences.maxReviseRetries) {
  showToast("修正が3回失敗しました。指示を具体化するか、一度却下してください。");
  return "REJECT";
}
```

上限3回は、LLMの自己修正が収束する経験則の閾値であり、UX上のストレスとコストのバランスが取れる。DBへの保存（v5マイグレーション）は [12_db-schema.md](./12_db-schema.md) §10.4 を参照。

---

> **出典**: `Local_AI_Agent.md` §6（Lines 276-345）。TDD型契約（G08）への参照とRevise上限（G09）を本文に統合した統合版である。
> **相互参照**: [05_sandbox.md](./05_sandbox.md)（Wasm検証） | [09_patch-engine.md](./09_patch-engine.md)（パッチ適用） | [10_logging-scribe.md](./10_logging-scribe.md)（承認ログ） | [14_shared-contracts.md](./14_shared-contracts.md) | [README.md](./README.md)
