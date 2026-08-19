<!-- 元ファイル: Local_AI_Agent.md §9 Lines 483-500 -->
# 11 ストレージ永続化とエクスポート/インポート

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local_AI_Agent.md)
> **インデックス**: [README.md](../README.md) | [Phase0設計書](../PHASE0_design.md)
> **関連ファイル**: [04_storage-persist.md](./04_storage-persist.md)（§3.2参照） | [12_db-schema.md](./12_db-schema.md) | [10_logging-scribe.md](./10_logging-scribe.md) | [README.md](../README.md)
> **元セクション**: §9（Lines 483-500）

> **要約**: 本ファイルはブラウザストレージ永続化宣言（§3.2再掲）と、成果物連携3種（GitHub API BYOK直接連携・JSZip一括ダウンロード・File System Access API双方向同期、.agent除外）を定義する。

> **ナビゲーション**: ← [10_logging-scribe.md](./10_logging-scribe.md) | [12_db-schema.md](./12_db-schema.md) →

---

## 9. ストレージ永続化 ＆ エクスポート / インポート仕様

### 9.1 ブラウザストレージの永続化宣言
IndexedDBがブラウザの容量逼迫時に自動削除される（Eviction）のを防止する（3.2節参照）。

### 9.2 成果物のエクスポート / インポート機能
1. GitHub API 直接連携 (BYOK):
   - ユーザーの GitHub Personal Access Token を使って、スマホから直接GitHubリポジトリを作成、コミット、プルリクエスト（PR）作成 が可能。
   - スマホでAIに指示 → そのままGitHubにPR作成 → VercelやCloudflare Pagesで自動デプロイ という完全モバイル開発フローが成立。
2. Zip一括ダウンロード (`JSZip`):
   - IndexedDB内のプロジェクト全ファイルを `.zip` でスマホの「ファイル」アプリにワンタップ保存。
   - ログ・スナップショットも含めた完全バックアップモードと、ソースコードのみの軽量モードを選択可能。
3. File System Access API 連携:
   - ユーザーが指定したPC内のローカルフォルダと、IndexedDBの仮想ファイルを1クリックで双方向同期。
   - `.agent/` ディレクトリは同期対象外とし、IDE内部データと明確に分離。

---


> ⚠️ **要人間判断（Phase 4で未解決）— G16 GitHub PATの保管**
> **→ 決定済み: 下記 `🆕（Phase 5・決定反映）` を参照（本⚠️は履歴として残存）**
> - **論点**: GitHub Personal Access Token を `security` ストアで暗号化保管するのか、平文/セッション限定にするのか
> - **選択肢**:
>   - **A案（推奨・高セキュリティ）**: Geminiキーと同様に `AES-GCM-256` + `PBKDF2` で `security` ストアに暗号化（`key: "github_pat"`）。PATも5分無操作でメモリ破棄。
>   - **B案（利便性）**: PATは有効期限が短い Fine-grained PAT を前提に `sessionStorage` のみに保持し、ブラウザを閉じたら再入力。IndexedDBには保存しない。
>   - **C案（混在）**: ユーザに選択させる（「暗号化保存 / セッション限定」トグルを PAT にも提供）
> - **影響**: Aはセキュリティ高だが実装は03と同一、Bは実装簡単だが毎回入力、CはUX最良だがUI複雑。**セキュリティ要件とUXのトレードオフで人間が選択**すること。
> - **根拠**: 元仕様は「GitHub API直接連携 (BYOK)」としか書かず、保管方法が未定義。Geminiキーの暗号化仕様（§3.1）を流用できるが、PATのスコープ（repo/contents:write 等）や失効時のUIは未決。

> 🆕 **詳細化補足（Phase 5・決定反映）— G16 PAT保管**
> - **決定**: **C案 ユーザ選択** を採用する。設定画面で「暗号化保存（推奨） / セッション限定」をトグルで選ばせる。デフォルトは暗号化保存。
> - **不採用案**:
>   - **A案 暗号化のみ**: 高セキュリティだが、毎回パスワード入力を求められ利便性で劣るケースがあるため、選択肢として残しつつ強制はしない。
>   - **B案 セッション限定のみ**: 毎回入力で UX が悪く、Fine-grained PAT の短期限を前提にしすぎるため不採用。
> - **影響**: `03_security-byok.md` の `security` ストアを流用し、`key: "github_pat"` で暗号化。UIは `03` のマスターパスワード入力と共通化。

---

> **出典**: `Local_AI_Agent.md` §9（Lines 483-500）を一字一句維持して分割
> **相互参照**: [04_storage-persist.md](./04_storage-persist.md)（§3.2参照） | [12_db-schema.md](./12_db-schema.md) | [10_logging-scribe.md](./10_logging-scribe.md) | [README.md](../README.md)
