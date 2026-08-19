# Phase 4-3 検証・完了レポート — 詳細化・リファクタリング

> 作成日: 2026-08-18 (Asia/Tokyo)
> 前提: Phase 0〜3で `Local_AI_Agent.md`（648行）を13ファイル＋READMEに分割（[PHASE3_report.md](PHASE3_report.md)で完全一致検証済み）。Phase 4-0で18件のギャップを洗い出し（[PHASE4_0_gaplist.md](PHASE4_0_gaplist.md)）、Phase 4-1で承認された方針に基づき加筆を実行。本レポートはPhase 4-2（横断整合性）とPhase 4-3（検証）を兼ねる。

---

## 1. 対応した項目一覧（Add / Flag / Skip 内訳）

### 1.1 集計

| 仕分け | 件数 | 該当G | 概要 |
|---|---|---|---|
| **Add** | 11件（実ブロック19） | G01,G02,G04,G06,G07,G08,G09,G12,G13,G14,G15,G17,G18（G07/G18は軽量） | 引用ブロック `> 🆕` で加筆。原文は上書きせず末尾に追記。横断的なものは `14_shared-contracts.md` に集約 |
| **Flag** | 4件（実ブロック4） | G03,G05,G10,G16 | `> ⚠️ 要人間判断` で選択肢を提示。加筆せず人間の決定待ち |
| **Skip** | 1件 | G11 | ダウングレード時の処理は稀なため現時点では未対応（理由を明記してAddで注記） |
| **計** | **16件**（G07/G18はAddに含む） | 18件中16件をAdd/Flag、1件Skip、1件（G07）は軽量Addとして計上。G04/G08/G14は同一新ファイルに集約のため重複カウントを整理すると **Add 11 / Flag 4 / Skip 1**（Phase 4-0の仕分けどおり） |

### 1.2 詳細（G別）

| G | ファイル | 仕分け | 加筆内容（1行要約） | 状態 |
|---|---|---|---|---|
| G01 | 09_patch-engine.md | **Add** | `normalizeWhitespace` / `applyFuzzyPatch` の叩き台実装を提示 | ✅ 加筆済み |
| G02 | 03_security-byok.md | **Add** | `decryptApiKey` 復号関数と `OperationError` ハンドリングを提示 | ✅ |
| G03 | 05_sandbox.md | **Flag** | Pyodide/QuickJS/WebContainers使い分けの3案を提示 | ⚠️ 未解決 |
| G04 | 05/07/09 + 14_shared-contracts | **Add** | JSON-RPC 2.0 の型（`JsonRpcRequest`/`Response`/`method`一覧）を `14` に新設し、各ファイルから参照 | ✅ 新ファイル270行 |
| G05 | 05_sandbox.md | **Flag** | WebContainersの `crossOriginIsolated` 矛盾を指摘し2層化 vs 縮退の2案を提示 | ⚠️ 未解決（Blocker） |
| G06 | 06_model-selection.md | **Add** | Interactions APIが2026-06-22 GA済みであることをWeb検索で裏取り、`client.interactions.create` と `generateContent` の併用方針と `GoogleGenAI` 初期化コードを提示 | ✅ |
| G07 | 07_model-caching-tier.md | **Add** | 紹介価格終了後は `RATE_TABLE` を外部定数化し公式料金表に追従する旨を追記 | ✅ |
| G08 | 08_ui-ux-workflow.md + 14 | **Add** | TDD各Phaseの型（`ContractPhaseOutput`等）を `14` に集約、08からは参照 | ✅ |
| G09 | 08_ui-ux-workflow.md | **Add** | Reviseループ上限を `maxReviseRetries=3` とする叩き台を提示 | ✅ |
| G10 | 10_logging-scribe.md | **Flag** | 複数タブ競合の3案（単一タブ制約 / `navigator.locks` / 楽観ロック）を提示 | ⚠️ 未解決 |
| G11 | 12_db-schema.md | **Skip** | ダウングレード時は `warn` のみで何もしない運用を明記（将来v5で対応） | ✅ 注記済み |
| G12 | 12_db-schema.md | **Add** | `checksum` の計算（put時）・照合（Preview/Export/復元時）ライフサイクルを提示 | ✅ |
| G13 | 13_roadmap.md | **Add** | Milestone1〜5のDoDテンプレート（PWA起動/Persist成功/テストグリーン等）を提示 | ✅ |
| G14 | 06/07 + 14 | **Add** | `genAI` 初期化と `cacheName` の型を `14` に集約 | ✅ |
| G15 | 07/10 + 14 | **Add** | コスト式 `estimated_usd = (in*inRate + out*outRate + cached*cachedRate)/1e6 * flexFactor` と `RATE_TABLE` を `14` に集約 | ✅ |
| G16 | 11_storage-export.md | **Flag** | GitHub PAT保管の3案（暗号化/B/C混在）を提示 | ⚠️ 未解決 |
| G17 | 12_db-schema.md | **Add** | `defaultModel` / `defaultTier` の列挙バリデーションコードを提示 | ✅ |
| G18 | 04_storage-persist.md | **Add** | `persist()===false` 時のトースト＋再試行UIを提示 | ✅ |

> **Addの原則**: 全て `> 🆕 詳細化補足（Phase 4）` の引用ブロックで視覚的に分離。原文の行は1行も削除・上書きしていない。
> **Flagの原則**: `> ⚠️ 要人間判断` で選択肢と影響を明示。推測を断定化していない。

---

## 2. 未解決のまま残った「要人間判断」項目一覧（実装着手前に必ず決めるべき事項）

> **重要**: 以下4件は **Blockerを含む** ため、実装着手前に人間の決定が必須。決定後は `14_shared-contracts.md` および該当ファイルの Flag ブロックを `🆕` に更新すること。

| # | G | ファイル | 論点 | 選択肢と影響 | 推奨 |
|---|---|---|---|---|---|
| 1 | **G03** | 05_sandbox.md | Pyodide / QuickJS / WebContainers の役割分担 | **A: 分担**（Pyodide=Python, QuickJS=軽量JS, WebContainers=Node）/ **B: WebContainers一本化**（QuickJS廃止）/ **C: 縮退**（WebContainers廃止）— バンドルサイズ10〜25MB、起動時間、対応言語が変わる | **A**（フルカバー）だが、WebContainersの扱いはG05と連動して再評価 |
| 2 | **G05** | 05_sandbox.md | WebContainersと `null origin` の両立不可能性 | **A: 2層化**（null origin本体 + crossOriginIsolatedな別オリジンでWebContainers分離、postMessageリレー）/ **B: 縮退**（WebContainers諦め）— Aは図の変更が必要だがNode互換を維持、Bは即時リリース可能だがnpm不可 | **A** を推奨。`02_architecture.md` の図に第2 iframeを追記する改修が必要 |
| 3 | **G10** | 10_logging-scribe.md | 複数タブでのIndexedDB競合 | **A: 単一タブ制約**（警告トースト）/ **B: `navigator.locks`**（跨タブ排他）/ **C: 楽観ロック**（seq大きい方を採用）— Aは実装1行、B/Cは堅牢だがコスト増 | **A** でMVP、将来Bへ移行 |
| 4 | **G16** | 11_storage-export.md | GitHub PATの暗号化保管 | **A: 暗号化**（Geminiキー同様に `security` ストア）/ **B: セッション限定**（Fine-grained PAT前提）/ **C: ユーザ選択**（トグル）— セキュリティ vs UX | **C**（ユーザ選択）が最も柔軟 |

> **G05は🔴Blocker** であるため、最優先で決定すること。G05をA案（2層化）にした場合、G03の選択もA案（分担）に倒すのが自然。

---

## 3. 加筆による増加行数と原文無傷の確認

### 3.1 行数変化

| 区分 | Phase 3 直後 | Phase 4 後 | 増加 | 備考 |
|---|---|---|---|---|
| docs/01_overview.md | 43 | 43 | +0 | 変更なし（ギャップなし） |
| docs/02_architecture.md | 83 | 83 | +0 | 変更なし |
| docs/03_security-byok.md | 63 | 93 | **+30** | G02 Add |
| docs/04_storage-persist.md | 37 | 60 | **+23** | G18 Add + 横断参照 |
| docs/05_sandbox.md | 31 | 53 | **+22** | G03/G05 Flag 2件 + 横断参照1件 |
| docs/06_model-selection.md | 44 | 65 | **+21** | G06/G14 Add |
| docs/07_model-caching-tier.md | 107 | 132 | **+25** | G07/G15 Add + 横断参照 |
| docs/08_ui-ux-workflow.md | 89 | 107 | **+18** | G08/G09 Add |
| docs/09_patch-engine.md | 89 | 126 | **+37** | G01 Add + 横断参照 |
| docs/10_logging-scribe.md | 86 | 101 | **+15** | G10 Flag + G15 Add |
| docs/11_storage-export.md | 37 | 46 | **+9** | G16 Flag |
| docs/12_db-schema.md | 134 | 165 | **+31** | G11/G12/G17 Add |
| docs/13_roadmap.md | 52 | 63 | **+11** | G13 Add |
| docs/14_shared-contracts.md | — | 270 | **+270** | 新規（横断契約の単一ソース） |
| **docs合計** | **895** | **1407** | **+512**（うち270は新ファイル） | — |
| README.md | 166 | 178 | **+12** | 14へのリンク追加 |
| **総合計** | **1061** | **1585** | **+524** | — |
| **コア行数（元648行）** | 648 | 648 | **+0** | 後述の検証で完全一致 |

### 3.2 原文無傷の検証

- **検証方法**: 各 `docs/0*.md` のテキスト内に、元スライス `Local_AI_Agent.md` の該当行範囲（例: `03` は Lines 89-132）を `slice_text in file_text` で部分文字列検索
- **結果**: **13ファイル全てで `FOUND`**（1行も欠落なし）
  ```
  docs/01_overview.md: original slice FOUND
  docs/02_architecture.md: original slice FOUND
  ...（全13ファイルでFOUND）
  ```
- **コードブロック**: 分割前後で `12` 個 → `12` 個で一致（`14_shared-contracts.md` の新規ブロックは除く）
- **表**: 2個（14行）→ 2個で一致
- **数値**: PBKDF2 600k / AES-GCM-256 / 75〜90% 等は `grep` で全ファイルに存在を確認

> **結論**: **原文は1字も削除・上書きされていない**。増加分は全て `> 🆕` または `> ⚠️` の引用ブロック、および新規 `14` ファイルのみ。

### 3.3 新規ファイルの位置づけ

- `14_shared-contracts.md` は元ファイルには存在しない Phase 4 新規ファイル。`NN_kebab-case-slug` 規則に従い末尾（14）に配置し、既存13ファイルの番号は崩していない。
- 横断的な型（G04/G08/G14/G15）を本ファイルに集約したことで、各ファイルの補足は「詳細は `14` を参照」の1行で済み、将来の変更時の矛盾を防止。

---

## 4. 横断整合性の再確認（Phase 4-2）

- **実施内容**: READMEの相互参照マップに `14_shared-contracts` を追加し、全関連ファイルの冒頭「関連ファイル」欄にも `14` へのリンクを追記（済み）
- **図の整合性**: `02_architecture.md` の図は Phase 4 では書き換えていない（絶対厳守事項に従い原文維持）。G05の2層化が採用された場合は、Phase 5 で図に第2 iframeを追記する改修を推奨。
- **命名規則**: `14_shared-contracts.md` は `NN_kebab-case-slug` に準拠（`14` + `shared-contracts`）

---

## 5. 次回検討事項・残課題

| # | 項目 | 優先度 | 対応時期 |
|---|---|---|---|
| 1 | G05の最終決定（2層化 vs 縮退）と `02_architecture.md` 図の更新 | 高 | 実装着手前 |
| 2 | `14_shared-contracts.md` の型を Zod スキーマに変換し、Sandboxの `validateOutput` で共用 | 中 | Milestone 3 |
| 3 | コストレートの外部JSON化（G07）— 管理画面で更新可能にする | 低 | Milestone 4以降 |
| 4 | `preferences.maxReviseRetries` のデフォルト値（G09）を `preferences` ストアのマイグレーション（v4→v5）で追加 | 中 | Milestone 2 |

---

## 6. 承認依頼

- **Phase 4-0**: ギャップ18件の洗い出しと仕分け → 承認済み
- **Phase 4-1**: 承認された Add/Flag に基づく加筆 → 本レポートの §1-§3 で完了
- **Phase 4-2**: 横断整合性のための新ファイル `14_shared-contracts.md` 新設と README 更新 → 完了

> **本レポートの承認をもって Phase 4 全フェーズ完了**とします。未解決の4件（G03/G05/G10/G16）は実装着手前に必ず人間の決定が必要です。決定後は該当ファイルの `⚠️` を `🆕` に更新し、本レポートを改訂してください。

---

### 付録: 検証コマンド

```bash
# 原文スライスが残っているか
python3 -c "import pathlib; ...; print('FOUND' if slice_text in file_text else 'MISSING')"

# 増加行数
wc -l docs/*.md README.md

# 補足ブロック数
grep -rn "🆕" docs/ --include="*.md" | wc -l  # 19
grep -rn "⚠️" docs/ --include="*.md" | wc -l  # 5（うち1は元ログの⚠️を含む）
```
