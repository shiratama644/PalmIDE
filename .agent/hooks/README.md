# `.agent/hooks/` — フックスクリプトの使い方

エージェントの実行ライフサイクル（編集前 / 編集後）に割り込ませるスクリプトを配置するディレクトリ。

## 含まれるファイル

| ファイル | 種類 | 役割 |
|---|---|---|
| `pre_edit_guard.sh` | PreToolUse | Rule 01 の編集禁止領域（`docs/`・`uploads/`・`PHASE*.md`・`REVIEW_DESIGN.md`）への変更をブロック |
| `post_edit_verify.sh` | PostToolUse | `new/` への編集後に Rule 05 の機械検証（ブロック残存・リンク・不変値）を実行 |
| `settings.example.json` | 配線例 | Claude Code の settings.json にフックを登録する例 |
| `README.md` | 本書 | — |

## 手動での実行（フック未配線でも使える）

```bash
# 1) 編集を試みるパスが保護対象か確認（終了コード 2 でブロック）
sh .agent/hooks/pre_edit_guard.sh new/07_model-caching-tier.md   # -> 許可 (exit 0)
sh .agent/hooks/pre_edit_guard.sh docs/07_model-caching-tier.md  # -> ブロック (exit 2)

# 2) new/ 編集後に全検証を実行
sh .agent/hooks/post_edit_verify.sh                                # -> 全 OK (exit 0) / NG あり (exit 1)
```

## 終了コードの約束

| コード | 意味 | ブロック? |
|---|---|---|
| 0 | 許可 / 検証 OK | - |
| 1 | 検証 NG（ログ参照） | 事後チェックとして NG を表示（事前ブロックではない） |
| 2 | PreToolUse 系でのみ：編集ブロック | ✅ |

## 配線の仕方（Claude Code）

`settings.example.json` の内容を、プロジェクトの `.claude/settings.json` かユーザー設定にマージしてください。`PreToolUse` で `exit 2` を返すと、ツール実行がブロックされます。

## 追加する場合のルール

- **Script は POSIX sh で書く**（bash/zsh 依存の文法は使わない）
- 必ず `cd "$(dirname "$0")/../.."` で repo ルート基準に揃える
- 終了コードは上記の約束に従う。メッセージは日本語で具体的に
- **hook は推測しない**。NG のときは必ず事実（grep 結果等）を表示して終了する
