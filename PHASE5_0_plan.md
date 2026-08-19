# Phase 5-0 決定依頼 ＋ 補完計画（承認ゲート①）

> 作成日: 2026-08-18 / 対象: `REVIEW_DESIGN.md` R1〜R10 および `PHASE4_report.md` G03/G05/G10/G16
> ステータス: **要承認** — Track A の回答をいただいた後に Phase 5-1 反映へ進む。Track B は軽量確認のみ。

---

## 1. 背景

- Phase 4完了時点でレビュー総合 **4.6/5.0**。ただし人間判断4件（G03/G05/G10/G16）とレビュー指摘10件（R1〜R10）が残存。
- R1はG05と同一、R3はG03に連動。残る **Track A 6件** は人間の好み・方針の選択、**Track B 7件** は技術的に自明な完成度向上。
- 本計画書では Track A について **選択肢・推奨・影響** を提示し、Track B について **何を・なぜ・どう直すか** を一覧で提示する。**いずれもまだ加筆していない**（原文は無傷）。

---

## 2. Track A — 人間判断が必要（回答待ち）

> 回答は一部でも可。未回答の項目は `⚠️` のまま残し、Phase 5-1 では回答分のみ `🆕（Phase5・決定反映）` に更新する。

| # | 論点 | ファイル | 選択肢 | 推奨 | 備考・影響 |
|---|---|---|---|---|---|
| **G05/R1** | WebContainersの `null origin` 両立不可能性（Blocker） | 05_sandbox.md / 02_architecture.md | **A: 2層化**（別オリジンiframeに分離、Host経由でpostMessageリレー）<br>**B: 縮退**（WebContainers廃止、Pyodide/QuickJSのみ） | **A** | Aは `02` の図に第2 iframe（`crossOriginIsolated` + COOP/COEP）を追記。Bは図の変更不要だが npm 互換を失う。**Phase 5-1で図の新旧注記を必ず行う**。 |
| **G03** | Pyodide / QuickJS / WebContainers の役割分担 | 05_sandbox.md | **A: 分担**（Pyodide=Python, QuickJS=軽量JS, WebContainers=Node）<br>**B: WebContainers一本化**（QuickJS廃止）<br>**C: 縮退**（WebContainersなし） | **G05=AならA**<br>**G05=BならC** | G05に依存。G05=AでWebContainersが使えるなら分担が最も柔軟。G05=BならCが自然。 |
| **G10** | 複数タブでのIndexedDB競合 | 10_logging-scribe.md | **A: 単一タブ制約**（警告トーストのみ）<br>**B: `navigator.locks`**（跨タブ排他）<br>**C: 楽観ロック**（seq大きい方を採用） | **A（MVP）** | Aは実装1行、B/Cは堅牢だがコスト増。MVPはAで将来Bへ移行が自然。 |
| **G16** | GitHub PATの保管方式 | 11_storage-export.md | **A: 暗号化**（`security`ストアでAES-GCM）<br>**B: セッション限定**（Fine-grained PAT前提）<br>**C: ユーザ選択**（トグルでA/Bを選ばせる） | **C** | CがUXとセキュリティのバランス最良。Aは高セキュリティ、Bは毎回入力。 |
| **R2** | JSON-RPCメソッド名の確定 | 14_shared-contracts.md §1.4 | **現行案で確定**: `typeCheck` / `runTests` / `validateOutput` / `extractSkeleton` / `applyPatch` / `lint`<br>**変更案を提示**（あれば自由記述） | **現行案で確定** | `extractSkeleton` は `ASTContextRouter` との命名整合を要確認。変更があれば `14` のみを更新。 |
| **R3** | `skeleton` の型（Tree-sitter JSON か Babel文字列か） | 14_shared-contracts.md §2 | **G03の決定に従って自動確定**（例: G03=Aなら Tree-sitter由来JSON、B/Cなら Babel文字列）<br>個別に決める場合は自由記述 | **G03に連動** | 単独で決めると G03 と矛盾するため、G03回答後に自動確定。 |

### 依存関係

```
G05/R1 ──→ G03 ──→ R3
  │
  └─→ 02_architecture.md の図更新（G05=Aの場合のみ）
```

---

## 3. Track B — 人間判断不要・技術的完成（着手前に一覧のみ提示）

> Blockerではないため軽量な確認でよいが、無断実行はしない。異論がなければ Track A と並行して着手する。

| # | 対象ファイル | 指摘元 | 内容（何を・なぜ・どう直すか） |
|---|---|---|---|
| **R4** | 09_patch-engine.md / 14_shared-contracts.md | REVIEW R4 | **何を**: `normalizeWhitespace` の厳密版（オフセットマッピング保持）とテストケース<br>**なぜ**: 現行の `idx + searchBlock.length` は正規化前後の差でズレるため<br>**どう**: `14` に `StrictFuzzyPatch` ユーティリティ（正規化前後のオフセット表を持つ版）を追加し、`09` から参照。テストケース（全角空白・CRLF・タブ混在・空行）を `09` の補足に追記。 |
| **R5** | 07_model-caching-tier.md / 14_shared-contracts.md | REVIEW R5 | **何を**: `cached_tokens` の課金モデル<br>**なぜ**: `flexFactor * cached` が推測のため、公式で「割引率」か「別単価」かを確認する必要がある<br>**どう**: Web検索で Gemini 公式の Context Caching / Flex Tier の請求仕様を再確認。確認できれば `RATE_TABLE` の `cached` の扱いを確定し `14` に反映、確認できなければ `> 🆕` 内で「未確認。要検証」と明記。**断定しない**。 |
| **R6** | 12_db-schema.md | REVIEW R6 | **何を**: v4→v5 マイグレーション追加<br>**なぜ**: `maxReviseRetries`（G09）や `RATE_TABLE` の `preferences` 追加でスキーマ変更が必要<br>**どう**: `12` に `if (oldVersion < 5) { preferencesStore ...; createIndex ... }` の叩き台を追加し、`14` の型とも整合。 |
| **R7** | README.md | REVIEW R7 | **何を**: アーキテクチャ図の二重管理解消<br>**なぜ**: 同一図が README と `02` に複製され、将来の2層化更新で2箇所直す必要があるため<br>**どう**: READMEの図ブロックを `> 図は [02_architecture.md](docs/02_architecture.md) を参照` のリンク1行に置換。`02` 側の図は維持。原文の図は削除せず、README側だけをリンク化するため「原文削除」には当たらない。 |
| **R8** | 01_overview.md | REVIEW R8 | **何を**: 「横断契約 `14_shared-contracts.md` を参照」の1文<br>**なぜ**: 初学者が `14` を読み飛ばすのを防ぐ<br>**どう**: `01` 末尾に `> 🆕` で1行追記。 |
| **R9** | 12_db-schema.md | REVIEW R9 | **何を**: `checksum` ライフサイクルの説明を `snapshots` にも拡張<br>**なぜ**: 現状は `files` のみに触れているため<br>**どう**: `12` の G12 補足に `snapshots` の整合性チェック（復元時に `files` の checksum を再検証）の一文を追記。 |
| **R10** | 13_roadmap.md | REVIEW R10 | **何を**: 各MilestoneのDoDに目安期間の列を追加<br>**なぜ**: プロジェクト管理上、期限の目安があると計画しやすいため<br>**どう**: `13` の DoD 表に `目安期間` 列（例: M1=2週間, M2=2週間, M3=3週間, M4=3週間, M5=2週間）を追加。叩き台であり、正式な期限は別管理。 |

### Track B の着手条件

- 本一覧に異論がなければ、Track A の回答を待たずに並行して着手してよい（ただし R3 は G03 決定後に着手）。

---

## 4. 反映時の書式（Phase 5-1 で厳守）

- **Track A 決定反映**:
  ```markdown
  > 🆕 **詳細化補足（Phase 5・決定反映）**
  > - **決定**: <選ばれた選択肢>
  > - **不採用案**: <選ばれなかった案とその理由>
  ```
- **Track B 追記**:
  ```markdown
  > 🆕 **詳細化補足（Phase 5・レビュー反映）**
  > - **指摘元**: REVIEW_DESIGN.md R<番号>
  > - **内容**: <加筆内容>
  ```

- 既存の `> 🆕（Phase 4）` / `> ⚠️` は削除せず残す。Phase 5 の補足はその **後段** に追記し、時系列で判断が追えるようにする。
- `02_architecture.md` の図更新は **元の図を削除せず**、「Phase 4までの原案（…問題が発覚したため、Phase 5版を正とする）」と注記して残し、新たに「### Phase 5 更新版アーキテクチャ図」節を新設する。

---

## 5. 次のステップ

1. **Track A の回答**（全項目でも一部でも可）をいただく
2. **Track B の一覧**に異論がなければ「承認」で着手
3. 承認後、Phase 5-1 で反映を実行し、Phase 5-2 で `PHASE5_report.md` を作成

> **本計画書の時点では一切の加筆を行っていない**（原文および Phase 4 までの `🆕/⚠️` は無傷）。

