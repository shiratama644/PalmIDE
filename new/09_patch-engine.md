<!-- 統合版: docs/09_patch-engine.md の Phase 4〜5 追記（G01 正規化関数 / R4 厳密版Fuzzy）を本文にマージ（元: Local_AI_Agent.md §7 Lines 346-415） -->
# 09 パッチ＆検証エンジン

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local%20AI%20Agent.md)（§7 Lines 346-415）
> **インデックス**: [README.md](./README.md)
> **関連ファイル**: [08_ui-ux-workflow.md](./08_ui-ux-workflow.md)（§6.4 Approval Gate） | [07_model-caching-tier.md](./07_model-caching-tier.md)（Context Cache） | [05_sandbox.md](./05_sandbox.md)（Wasm検証） | [14_shared-contracts.md](./14_shared-contracts.md)（§1 JSON-RPC / §2 TDD型・StrictFuzzyPatch）

> **要約**: 本ファイルはFuzzy Search & Replace（完全一致→正規化Fuzzy→NO_MATCHの3段階）、リカバリー戦略（AMBIGUOUS/NO_MATCH/SYNTAX_ERROR）と、コンテキスト注入基準表（AST Skeleton vs フルコード vs キャッシュ、300行閾値）を定義する。

> **ナビゲーション**: ← [08_ui-ux-workflow.md](./08_ui-ux-workflow.md) | [10_logging-scribe.md](./10_logging-scribe.md) →

---

## 7. 堅牢なパッチ＆検証エンジン

### 7.1 曖昧性を排除した Fuzzy Search & Replace パッチエンジン
スマホの非力な環境でも一瞬で完了し、既存コードを壊さない「差分置換方式」を採用。

```text
<<<<<<< SEARCH
export const Button = ({ text }: { text: string }) => {
  return <button>{text}</button>;
};
=======
export const Button = ({ text, onClick }: { text: string; onClick?: () => void }) => {
  return <button onClick={onClick} className="btn-primary">{text}</button>;
};
>>>>>>> REPLACE
```

LLMが生成する差分パッチの失敗を防ぐため、3段階のフォールバック・マッチングを行う。

```typescript
export interface PatchResult {
  success: boolean;
  patchedContent?: string;
  error?: "NO_MATCH" | "AMBIGUOUS_MATCH" | "SYNTAX_ERROR" | "VALIDATION_FAILED";
}

function applySearchReplace(
  original: string,
  searchBlock: string,
  replaceBlock: string
): PatchResult {
  // Step 1: 完全一致チェック
  const exactMatches = original.split(searchBlock).length - 1;
  if (exactMatches === 1) {
    return { success: true, patchedContent: original.replace(searchBlock, replaceBlock) };
  }
  if (exactMatches > 1) {
    return { success: false, error: "AMBIGUOUS_MATCH" };
  }

  // Step 2: 空白・インデント・改行コードを正規化した Fuzzy 一致チェック
  const normalizedOriginal = normalizeWhitespace(original);
  const normalizedSearch = normalizeWhitespace(searchBlock);
  const fuzzyIndex = normalizedOriginal.indexOf(normalizedSearch);
  if (fuzzyIndex !== -1) {
    const fixedContent = applyFuzzyPatch(original, searchBlock, replaceBlock);
    return { success: true, patchedContent: fixedContent };
  }

  // Step 3: 一致しない場合
  return { success: false, error: "NO_MATCH" };
}
```

#### 正規化関数の実装

`applySearchReplace` が呼び出す `normalizeWhitespace` / `applyFuzzyPatch` は以下の通り定義する。空白・改行コードの正規化と、元ファイルのインデントを保持した Fuzzy 置換を実現する。

```typescript
function normalizeWhitespace(str: string): string {
  // 改行コード統一 → 行末空白削除 → タブ→空白 → 空行の空白削除
  return str
    .replace(/\r\n/g, "\n")
    .replace(/[ \t]+$/gm, "")
    .replace(/\t/g, "  ")
    .replace(/[ \t]{2,}/g, " ");
}
function applyFuzzyPatch(original: string, searchBlock: string, replaceBlock: string): string {
  // 正規化後のインデックスを元文字列のインデックスに逆マッピングする簡易実装
  const normOrig = normalizeWhitespace(original);
  const normSearch = normalizeWhitespace(searchBlock);
  const idx = normOrig.indexOf(normSearch);
  if (idx === -1) return original;
  const before = original.slice(0, idx);
  const after = original.slice(idx + searchBlock.length);
  // 正規化前後のオフセット差は厳密版（StrictFuzzyPatch）で補正する
  return before + replaceBlock + after;
}
```

> **注意**: 上記 `applyFuzzyPatch` は最小動作版で、`idx + searchBlock.length` のオフセット推定が正規化前後の差でズレうる。本番実装では **厳密版 `StrictFuzzyPatch`（正規化前後のオフセットマッピング表を保持する版）を [14_shared-contracts.md](./14_shared-contracts.md) §2 に従って実装する**こと。

厳密版は以下の5パターンのテストケースで検証する。

```text
テストケース:
1. "a  b"（連続空白）→ "a b" に正規化されても元オフセットを保持
2. "a\tb"（タブ）→ "a  b" への変換で行桁を保持
3. "a\r\nb"（CRLF）→ "a\nb" への統一で行番号を保持
4. "a　b"（全角空白）→ "a b" への正規化で文字幅を保持
5. "a \n \n b"（空行の空白）→ 空行の空白を除去してもブロック境界を保持
```

インデント保持の意図は `replaceBlock` をそのまま挿入することで満たす。

#### パッチ適用失敗時のリカバリー戦略
1. `AMBIGUOUS_MATCH`: エージェントに「周辺の行（コンテキスト）を前後に5行増やしてSEARCHブロックを再生成してください」と指示（最大2リトライ）。
2. `NO_MATCH`: 対象関数のスコープを AST から再取得してプロンプトへ再注入。
3. `SYNTAX_ERROR`: パッチ適用後のコードをWasmコンパイラで検証し、失敗時は自動ロールバック。

パッチ適用・検証の `postMessage` 連携（`method: "typeCheck" | "runTests" | "validateOutput" | "applyPatch"` 等）のリクエスト/レスポンス型は [14_shared-contracts.md](./14_shared-contracts.md) §1 を参照。TDD Phase間で受け渡す型（`ImplPhaseOutput.patch` 等）は同 §2 を参照。

### 7.2 コンテキスト注入の使い分け基準（AST Skeleton vs フルコード vs キャッシュ）

| ケース | 渡すコンテキスト | 判定基準 | キャッシュ戦略 |
| :--- | :--- | :--- | :--- |
| 他ファイルへの参照 / プロジェクト全容把握 | AST Skeleton（型・シグネチャのみ） | 参照先ファイル全般 | Context Cache推奨 |
| 編集対象の局所修正（関数単位） | 対象関数ブロック + 前後5行 | 該当ファイルが300行以上の場合 | なし |
| 編集対象の全面改修 / 新規作成 | 対象ファイル全文 | 該当ファイルが300行未満の場合 | なし |
| プロジェクト全体の設計レビュー | ファイルツリー + 主要ファイルのSkeleton | アーキテクチャ相談時 | Context Cache必須 |

---

> **出典**: `Local_AI_Agent.md` §7（Lines 346-415）。正規化関数の実装（G01）と厳密版 Fuzzy Patch（R4）を本文に統合した統合版である。
> **相互参照**: [08_ui-ux-workflow.md](./08_ui-ux-workflow.md)（§6.4 Approval Gate） | [07_model-caching-tier.md](./07_model-caching-tier.md)（Context Cache） | [05_sandbox.md](./05_sandbox.md)（Wasm検証） | [14_shared-contracts.md](./14_shared-contracts.md) | [README.md](./README.md)
