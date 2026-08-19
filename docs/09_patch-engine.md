<!-- 元ファイル: Local_AI_Agent.md §7 Lines 346-415 -->
# 09 パッチ＆検証エンジン

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local_AI_Agent.md)
> **インデックス**: [README.md](../README.md) | [Phase0設計書](../PHASE0_design.md)
> **関連ファイル**: [08_ui-ux-workflow.md](./08_ui-ux-workflow.md)（§6.4 Approval Gate） | [07_model-caching-tier.md](./07_model-caching-tier.md)（Context Cache） | [05_sandbox.md](./05_sandbox.md)（Wasm検証） | [README.md](../README.md)
> **元セクション**: §7（Lines 346-415）

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

#### パッチ適用失敗時のリカバリー戦略
1. `AMBIGUOUS_MATCH`: エージェントに「周辺の行（コンテキスト）を前後に5行増やしてSEARCHブロックを再生成してください」と指示（最大2リトライ）。
2. `NO_MATCH`: 対象関数のスコープを AST から再取得してプロンプトへ再注入。
3. `SYNTAX_ERROR`: パッチ適用後のコードをWasmコンパイラで検証し、失敗時は自動ロールバック。

### 7.2 コンテキスト注入の使い分け基準（AST Skeleton vs フルコード vs キャッシュ）

| ケース | 渡すコンテキスト | 判定基準 | キャッシュ戦略 |
| :--- | :--- | :--- | :--- |
| 他ファイルへの参照 / プロジェクト全容把握 | AST Skeleton（型・シグネチャのみ） | 参照先ファイル全般 | Context Cache推奨 |
| 編集対象の局所修正（関数単位） | 対象関数ブロック + 前後5行 | 該当ファイルが300行以上の場合 | なし |
| 編集対象の全面改修 / 新規作成 | 対象ファイル全文 | 該当ファイルが300行未満の場合 | なし |
| プロジェクト全体の設計レビュー | ファイルツリー + 主要ファイルのSkeleton | アーキテクチャ相談時 | Context Cache必須 |

---


> 🆕 **詳細化補足（Phase 4）**
> - **対象**: `applySearchReplace` 内で呼び出される未定義関数 `normalizeWhitespace` / `applyFuzzyPatch`（§7.1）
> - **種別**: 🔴Blocker解消
> - **内容**: 以下の叩き台実装を提案する。空白・改行コードの正規化と、元ファイルのインデントを保持した Fuzzy 置換を実現する。
>   ```typescript
>   function normalizeWhitespace(str: string): string {
>     // 改行コード統一 → 行末空白削除 → タブ→空白 → 空行の空白削除
>     return str
>       .replace(/\r\n/g, "\n")
>       .replace(/[ \t]+$/gm, "")
>       .replace(/\t/g, "  ")
>       .replace(/[ \t]{2,}/g, " ");
>   }
>   function applyFuzzyPatch(original: string, searchBlock: string, replaceBlock: string): string {
>     // 正規化後のインデックスを元文字列のインデックスに逆マッピングする簡易実装（叩き台）
>     const normOrig = normalizeWhitespace(original);
>     const normSearch = normalizeWhitespace(searchBlock);
>     const idx = normOrig.indexOf(normSearch);
>     if (idx === -1) return original;
>     // 元文字列側で Fuzzy にマッチした範囲を推定し、replaceBlock で置換
>     // 厳密な逆マッピングは将来 `14_shared-contracts.md` のユーティリティに集約することを推奨
>     const before = original.slice(0, idx);
>     const after = original.slice(idx + searchBlock.length);
>     // 実際には正規化前後のオフセット差を補正する必要があるため、運用前にテストを追加すること
>     return before + replaceBlock + after;
>   }
>   ```
>   本実装は最小動作の叩き台であり、`applyFuzzyPatch` のオフセット補正は完全ではない。Phase 4-2 で `14_shared-contracts.md` に厳密版を集約することを推奨。
> - **根拠**: 元仕様は「空白・インデント・改行コードを正規化した Fuzzy 一致」としか述べず、実装がなければビルドが通らない。最小の正規化でテスト容易性を担保しつつ、インデント保持の意図は `replaceBlock` をそのまま挿入することで満たすため。
> - **関連**: 詳細な型は [14_shared-contracts.md](./14_shared-contracts.md) §2 を参照。

> 🆕 **詳細化補足（Phase 4）— 横断契約への参照**
> - **対象**: `postMessage` JSON-RPC 2.0 の未定義スキーマ（G04）
> - **種別**: 🔴Blocker解消（参照）
> - **内容**: 本ファイルの `postMessage` 連携の詳細なリクエスト/レスポンス型は [14_shared-contracts.md](./14_shared-contracts.md) §1 に集約した。`method: "typeCheck" | "runTests" | "validateOutput"` 等の叩き台を参照すること。
> - **根拠**: 横断的な契約を単一ソースに集約し、05・07・09間の矛盾を防ぐため。

> 🆕 **詳細化補足（Phase 5・レビュー反映）— R4 厳密版 Fuzzy Patch**
> - **指摘元**: REVIEW_DESIGN.md R4
> - **内容**: Phase 4の叩き台 `normalizeWhitespace` は `idx + searchBlock.length` でオフセットを推定しており、正規化前後の差でズレる。Phase 5で `14_shared-contracts.md` §2 に **StrictFuzzyPatch** ユーティリティ（正規化前後のオフセットマッピング表を保持する厳密版）を追加した。テストケースとして **全角空白（U+3000）・CRLF・タブ混在・空行の空白・連続空白** の5パターンを本補足に追記し、`09` の実装は `14` の厳密版を参照すること。
>   ```text
>   テストケース:
>   1. "a  b"（連続空白）→ "a b" に正規化されても元オフセットを保持
>   2. "a\tb"（タブ）→ "a  b" への変換で行桁を保持
>   3. "a\r\nb"（CRLF）→ "a\nb" への統一で行番号を保持
>   4. "a　b"（全角空白）→ "a b" への正規化で文字幅を保持
>   5. "a \n \n b"（空行の空白）→ 空行の空白を除去してもブロック境界を保持
>   ```
> - **根拠**: オフセットマッピングを持つことで、正規化で文字数が変わっても元ファイルの正確な置換範囲を復元できるため。

---

> **出典**: `Local_AI_Agent.md` §7（Lines 346-415）を一字一句維持して分割
> **相互参照**: [08_ui-ux-workflow.md](./08_ui-ux-workflow.md)（§6.4 Approval Gate） | [07_model-caching-tier.md](./07_model-caching-tier.md)（Context Cache） | [05_sandbox.md](./05_sandbox.md)（Wasm検証） | [README.md](../README.md)
