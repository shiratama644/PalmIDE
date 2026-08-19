---
name: verify-doc-integrity
description: new/ の整合性（不変値保持・リンク実在・ブロック残存なし）を機械検証する一連の手順。仕様変更後・コミット前に必須。
---

# Skill: 仕様書整合性の機械検証

PalmIDE の `new/` に対する変更が「壊していないか」を、チャット判断ではなく機械的コマンドで担保する手順。

## いつ使うか

- `new/` のファイルを 1行でも編集した直後
- PR を open / update する直前
- 人間に「この変更で仕様が壊れていないか」と聞かれたとき

## 手順（順序厳守）

### Step 1. ブロック残存チェック（過去形式が混ざっていないか）

```bash
grep -nH '^>[^>]*\(🆕\|⚠️\)' new/*.md | grep -v 'new/README.md'
# 期待: 出力なし（README の版説明文中の言及のみ許容。
#       引用ブロック `^>` 形式のみを対象にし、`## ⚠️ 発生したエラー` 等の正当な見出しは誤検出しない）
```

### Step 2. 不変値保持チェック

`.agent/rules/02_immutable-invariants.md` §2 のスクリプトを実行し、`MISSING:` が1件も出ないことを確認。

### Step 3. 内部リンク検証

```bash
cd new
grep -ohr '](\./[^)]*)' *.md | sed 's/](\.\///; s/)$//; s/#.*//' | sort -u |
  while read -r f; do [ -f "$f" ] || echo "BROKEN: $f"; done
ls -la ../uploads/"Local AI Agent.md"
cd ..
# 期待: BROKEN 0件、uploads ファイルが存在
```

### Step 4. 変更槌の見読み

```bash
git status --short && git diff --stat
# 狙いではないファイルが変更されていないか目視
```

## 完了報告のフォーマット

```
- (A) ブロック残存: OK (0件)
- (B) 不変値: OK (MISSING 0件/XX件)
- (C) リンク: OK (BROKEN 0件)
- (D) 変更狙い: 意図した N ファイルのみ
```

どれか 1つでも NG が出たら「統合作業の完了」宣言はしない。先に直す。
