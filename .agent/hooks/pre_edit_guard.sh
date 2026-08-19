#!/bin/sh
# pre_edit_guard.sh — 禁止領域への編集をブロックする PreToolUse フック
#
# Claude Code の hooks 経由で呼ばれる想定（stdin に JSON が来る）が、
# 直接 `sh pre_edit_guard.sh <ファイルパス>` でも動作するよう両対応にしている。
#
# ブロック対象（Rule 01）:
#   docs/ 以下、uploads/ 以下、PHASE*.md、REVIEW_DESIGN.md
#
# 終了コード:
#   0 = 許可, 1 = 警告のみ（許可）, 2 = ブロック（Claude Code の PreToolUse 慣例）

set -u

TARGET=""

# 1) 引数運び（手動実行用）
if [ $# -ge 1 ]; then
  TARGET="$1"
else
  # 2) Claude Code hooks（stdin JSON）から tool_input.file_path を抜く
  INPUT=$(cat 2>/dev/null || true)
  TARGET=$(printf '%s' "$INPUT" \
    | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n1)
fi

# 正規化: 絶対パス・./ プレフィックスを落として repo 相対にする
case "$TARGET" in
  "") exit 0 ;;
  /*/PalmIDE/*) TARGET="${TARGET#*/PalmIDE/}" ;;
  ./*) TARGET="${TARGET#./}" ;;
esac

is_protected() {
  case "$1" in
    docs/*|uploads/*) return 0 ;;
    PHASE*.md|REVIEW_DESIGN.md) return 0 ;;
    *) return 1 ;;
  esac
}

if is_protected "$TARGET"; then
  {
    echo "⛔ [pre_edit_guard] 編集禁止領域です: $TARGET"
    echo "   Rule 01 により docs/, uploads/, PHASE*.md, REVIEW_DESIGN.md は読み取り専用です。"
    echo "   仕様の改訂は new/ 配下の本文のみで行ってください。"
  } >&2
  exit 2
fi

exit 0
