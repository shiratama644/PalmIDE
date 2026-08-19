<!-- 元ファイル: Local_AI_Agent.md §11 Lines 616-648 -->
# 13 実装ロードマップ（優先順位順）

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local_AI_Agent.md)
> **インデックス**: [README.md](../README.md) | [Phase0設計書](../PHASE0_design.md)
> **関連ファイル**: [01_overview.md](./01_overview.md) | [02_architecture.md](./02_architecture.md) | [05_sandbox.md](./05_sandbox.md) | [06_model-selection.md](./06_model-selection.md) | [README.md](../README.md)
> **元セクション**: §11（Lines 616-648）

> **要約**: 本ファイルはMilestone 1（セキュア基盤/PWA）〜5（ログ自己改善・外部連携）の優先順位順ロードマップを定義する。全章の統合実装順序として機能。

> **ナビゲーション**: ← [12_db-schema.md](./12_db-schema.md)  

---

## 11. 実装ロードマップ（優先順位順）

- Milestone 1: セキュア基盤 ＆ モバイルUIプロトタイプ
  - PWA対応（マニフェスト、ServiceWorker）とレスポンシブなClaude Code風チャットUI
  - `Web Crypto API` による API キー暗号化・IndexedDB v4 初期化＆マイグレーション
  - `@google/genai` (Interactions API) のブラウザ直接疎通（CORS検証）
  - `navigator.storage.persist()` によるストレージ永続化宣言

- Milestone 2: ローカルファイルシステム ＆ 承認ゲート
  - IndexedDB 仮想ファイルシステムと Live Preview（Blob URL表示）
  - Fuzzy Search & Replace パッチエンジン
  - モバイル向け「Live Diff プレビュー ＆ 承認/却下/修正指示」UI
  - コスト推計表示機能（トークン数 → USD換算）

- Milestone 3: ゼロトラストサンドボックスとコンパイラ Wasm
  - `<iframe sandbox="allow-scripts">` の JSON-RPC 2.0 通信基盤構築
  - Wasm による TypeScript Language Service（型チェック）の稼働
  - Structured Output Validator（Zodスキーマによる応答検証）
  - AST Context Router（Tree-sitter / Babel Wasm）によるスケルトン抽出

- Milestone 4: Gemini 3.x オーケストレーター ＆ TDD ループ
  - Gemini 3.7 Flash を主軸とした TDD ステートマシン（Contract → Test → Impl → Approval）
  - Context Caching によるシステムプロンプト・参照ドキュメントの永続キャッシュ
  - Flex/Priority Tier 自動選択ロジック
  - 指数バックオフ ＆ Tier フォールバック（429制限対策）

- Milestone 5: ログ自己改善 ＆ 外部連携
  - 非同期 Scribe Agent による 1作業1Markdown ログ生成（コスト追跡付き）
  - Mutex Lock + WAL による書き込み競合制御
  - スナップショット巻き戻し（タイムトラベル）機能
  - GitHub API 連携（スマホからの直接コミット/PR作成）
  - `JSZip` によるプロジェクト一括エクスポート（完全バックアップ / 軽量モード）
  - File System Access API によるローカルフォルダ双方向同期

> 🆕 **詳細化補足（Phase 4）— G13 Definition of Done**
> - **対象**: 各Milestoneの完了条件（DoD）未定義
> - **種別**: 🟢補足
> - **内容**: 以下の叩き台DoDを提案する。
>   - **Milestone 1**: PWAがホーム画面から起動できる / `encryptApiKey` ↔ `decryptApiKey` round-trip 成功 / `navigator.storage.persist()` が `true` を返す / `@google/genai` で `interactions.create` が CORS越しに成功
>   - **Milestone 2**: IndexedDBに `files` put/get 成功 / Fuzzyパッチの3段階テストがグリーン / Diff承認UIで Approve/Reject/Revise が動作 / コスト見積が小数4桁で表示
>   - **Milestone 3**: `postMessage` で `typeCheck`→`runTests` が `null origin` 検証付きで往復 / Wasm TS Serviceが型エラーを検出 / AST Skeleton抽出が `files` から成功
>   - **Milestone 4**: TDD 4 Phase（Contract→Test→Impl→Approval）が3回連続で成功 / Context Cachingが `cachedContents/...` を返す / Tier Fallbackが429で自動切替
>   - **Milestone 5**: Scribeが `.agent/logs/SEQ_...md` を1作業1ファイルで生成 / Mutexで競合しない / Snapshot巻き戻し成功 / GitHubへPR作成成功（PAT暗号化時）
> - **根拠**: 各章のキーワードを「動くこと」の観点で具体化したもの。テスト自動化のベースとして使える。

> 🆕 **詳細化補足（Phase 5・レビュー反映）— R10 DoDに目安期間追加**
> - **指摘元**: REVIEW_DESIGN.md R10
> - **内容**: 各MilestoneのDoDに目安期間の列を追加した叩き台を提示する。
>   | Milestone | 目安期間 | 備考 |
>   |---|---|---|
>   | M1 基盤 | 2週間 | PWA/暗号化/persist |
>   | M2 ファイル&承認 | 2週間 | 仮想FS/パッチ/承認UI |
>   | M3 Sandbox | 3週間 | 2層化Sandbox/Wasm |
>   | M4 オーケストレーション | 3週間 | TDD/Cache/Tier |
>   | M5 ログ&外部連携 | 2週間 | Scribe/GitHub/Zip |
>   本期間は叩き台であり、正式な期限は別途プロジェクト管理で決定する。

---

> **出典**: `Local_AI_Agent.md` §11（Lines 616-648）を一字一句維持して分割
> **相互参照**: [01_overview.md](./01_overview.md) | [02_architecture.md](./02_architecture.md) | [05_sandbox.md](./05_sandbox.md) | [06_model-selection.md](./06_model-selection.md) | [README.md](../README.md)
