# Rule 01: 情報の正と編集禁止領域（最上位ルール）

> 優先度: **CRITICAL（他の全ルールに優先）**

## 1. 「正」の対応表

| 用途 | 参照すべき情報源 | 編集可否 |
|---|---|---|
| 仕様の参照・実装・質問応答 | **`new/*.md`**（14章 + README） | ✅ 編集可能（他ルール準拠で） |
| 判断履歴・経緯の確認 | `docs/*.md` ＋ `PHASE5_report.md` ＋ `REVIEW_DESIGN.md` | ❌ 読み取りのみ |
| 元の単一仕様書 | `uploads/Local AI Agent.md` | ❌ 変更禁止 |
| 未解決論点の履歴 | `PHASE4_0_gaplist.md` | ❌ 読み取りのみ |
| 差分レビューの形式見本 | `MERGE_DIFF_REPORT.md` | 参照用（再生成は可・手編集と記録を一致させる） |

## 2. 鉄則

1. **仕様の追加・改訂は `new/` の該当ファイル本文のみ**に行う。`docs/` へは一字も追記しない。
2. 横断契約（JSON-RPC型・TDD型・コストレート・初期化コード等）の変更は **`new/14_shared-contracts.md` のみ**を更新。各章側は参照リンクのままにする。
3. 過去の `> 🆕` / `> ⚠️` 形式は**廃止**（統合版で解体済み）。決定は本文に直接書く。未決は Rule 04 の「未決事項の開示形式」で別管理する。
4. README は **ルート `README.md`（履歴版）と `new/README.md`（統合版）の2つが共存**する。通常の参照は `new/README.md` を使う。

## 3. 禁止操作

- `docs/`, `uploads/`, `PHASE0_design.md`, `PHASE3_report.md`, `PHASE4_0_gaplist.md`, `PHASE4_report.md`, `PHASE5_0_plan.md`, `PHASE5_report.md`, `REVIEW_DESIGN.md` の新規作成・編集・削除・リネーム（Git での履歴保持を壊すため）
- `new/` と `docs/` の内容を手動で「再同期」する行為（統合は一度で完了。以降は new/ のみで進化させる）
