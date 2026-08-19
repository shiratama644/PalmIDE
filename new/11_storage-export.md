<!-- 統合版: docs/11_storage-export.md の Phase 5 追記（G16 GitHub PAT保管・ユーザ選択式）を本文にマージ（元: Local_AI_Agent.md §9 Lines 483-500） -->
# 11 ストレージ永続化とエクスポート/インポート

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local%20AI%20Agent.md)（§9 Lines 483-500）
> **インデックス**: [README.md](./README.md)
> **関連ファイル**: [04_storage-persist.md](./04_storage-persist.md)（§3.2参照） | [12_db-schema.md](./12_db-schema.md) | [10_logging-scribe.md](./10_logging-scribe.md) | [03_security-byok.md](./03_security-byok.md)（securityストア）

> **要約**: 本ファイルはブラウザストレージ永続化宣言（§3.2再掲）と、成果物連携3種（GitHub API BYOK直接連携・JSZip一括ダウンロード・File System Access API双方向同期、.agent除外）、および GitHub PAT の保管方式（ユーザ選択トグル、デフォルトは暗号化保存）を定義する。

> **ナビゲーション**: ← [10_logging-scribe.md](./10_logging-scribe.md) | [12_db-schema.md](./12_db-schema.md) →

---

## 9. ストレージ永続化 ＆ エクスポート / インポート仕様

### 9.1 ブラウザストレージの永続化宣言
IndexedDBがブラウザの容量逼迫時に自動削除される（Eviction）のを防止する（3.2節参照）。

### 9.2 成果物のエクスポート / インポート機能
1. GitHub API 直接連携 (BYOK):
   - ユーザーの GitHub Personal Access Token を使って、スマホから直接GitHubリポジトリを作成、コミット、プルリクエスト（PR）作成 が可能。
   - スマホでAIに指示 → そのままGitHubにPR作成 → VercelやCloudflare Pagesで自動デプロイ という完全モバイル開発フローが成立。
   - **PAT の保管方式（ユーザ選択）**: 設定画面で「暗号化保存（推奨・デフォルト）/ セッション限定」のトグルを提供する。
     - 暗号化保存: [03_security-byok.md](./03_security-byok.md) と同様に `AES-GCM-256` + `PBKDF2` で暗号化し、`security` ストアに `key: "github_pat"` として保存。メモリ上の平文は5分無操作で破棄。UI はマスターパスワード入力と共通化する。
     - セッション限定: `sessionStorage` のみに保持し、ブラウザを閉じたら再入力。IndexedDB には保存しない。
   - PAT のスコープ（`repo` / `contents:write` 等）と失効時の UI 導線は実装時に決定する。
2. Zip一括ダウンロード (`JSZip`):
   - IndexedDB内のプロジェクト全ファイルを `.zip` でスマホの「ファイル」アプリにワンタップ保存。
   - ログ・スナップショットも含めた完全バックアップモードと、ソースコードのみの軽量モードを選択可能。
3. File System Access API 連携:
   - ユーザーが指定したPC内のローカルフォルダと、IndexedDBの仮想ファイルを1クリックで双方向同期。
   - `.agent/` ディレクトリは同期対象外とし、IDE内部データと明確に分離。

---

> **出典**: `Local_AI_Agent.md` §9（Lines 483-500）。GitHub PAT 保管方式の決定（G16）を本文に統合した統合版である。
> **相互参照**: [04_storage-persist.md](./04_storage-persist.md)（§3.2参照） | [12_db-schema.md](./12_db-schema.md) | [10_logging-scribe.md](./10_logging-scribe.md) | [03_security-byok.md](./03_security-byok.md) | [README.md](./README.md)
