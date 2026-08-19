#!/bin/sh
# post_edit_verify.sh — new/ の仕様整合性を事後検証する PostToolUse フック
#
# 利用者が new/*.md を編集した後に、Rule 05 の機械検証 (A)(B)(C) を実行する。
# 終了コード: 0 = 全 OK, 1 = NG あり（ログでどこが落ちたかを必ず書く）

set -u
cd "$(dirname "$0")/../.." || exit 1   # 常に repo ルートで実行

FAIL=0

echo "=== post_edit_verify ==="

# (A) 許容外の 🆕/⚠️ 混入チェック（引用ブロック形式 `^>` のみ対象。
#     本文見出し `## ⚠️ 発生したエラー` 等の正当な仕様サンプルは誤検出しない）
HITS=$(grep -nH '^>[^>]*\(🆕\|⚠️\)' new/*.md 2>/dev/null | grep -v 'new/README.md' || true)
if [ -n "$HITS" ]; then
  echo "❌ (A) 🆕/⚠️ の残存を検出:"
  echo "$HITS" >&2
  FAIL=1
else
  echo "✅ (A) ブロック残存: OK"
fi

# (B) 内部リンク全面検証
BROKEN=$(
  cd new 2>/dev/null || exit 0
  grep -ohr '](\./[^)]*)' *.md 2>/dev/null \
    | sed 's/](\.\///; s/)$//; s/#.*//' \
    | sort -u \
    | while read -r f; do [ -f "$f" ] || echo "BROKEN: $f"; done
)
if [ -n "$BROKEN" ]; then
  echo "❌ (B) 壊れたリンクを検出:"
  echo "$BROKEN" >&2
  FAIL=1
else
  echo "✅ (B) リンク: OK"
fi

# (C) 不変値サンプル存在チェック（代表10件。空白含むキーは行単位で渡す）
MISS=""
while IFS= read -r KEY; do
  [ -z "$KEY" ] && continue
  grep -l "$KEY" new/*.md >/dev/null 2>&1 || MISS="$MISS $KEY"
done <<'EOF'
AES-GCM-256
PBKDF2
UnifiedAgentIDE_DB
null origin
crossOriginIsolated
JSON-RPC
scribe-wal
maxReviseRetries
RATE_TABLE
StrictFuzzyPatch
EOF
if [ -n "$MISS" ]; then
  echo "❌ (C) 不変値の消失を検出:$MISS" >&2
  FAIL=1
else
  echo "✅ (C) 不変値サンプル: OK"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "=== 全検証 OK ==="
  exit 0
fi
echo "=== 検証失敗（上の ❌ を直して再実行）===" >&2
exit 1
