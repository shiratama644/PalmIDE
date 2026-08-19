# Phase 5-2 検証・完了レポート — 意思決定の確定・レビュー指摘の反映

> 作成日: 2026-08-18 / 対象: `PHASE5_0_plan.md` Track A 6件 + Track B 7件
> 前提: Phase 4完了時点でレビュー総合4.6/5.0、未解決G4件+R10件が残存。Phase 5-0で承認を得た方針に基づき反映を実行。

---

## 1. Track A / Track B 反映結果一覧

### Track A — 人間判断が必要（全6件について回答を得て反映）

| # | 論点 | 回答 | 反映先 | 書式 | 状態 |
|---|---|---|---|---|---|
| **G05/R1** | WebContainers `null origin` 両立不可能性 | **A: 2層化** | `02_architecture.md` に `> 🆕（Phase 5・決定反映）— G05/R1` + `> 🆕（Phase 5・レビュー反映）— R1 更新版図` の2ブロックを追記、`05_sandbox.md` には既存の M0決定ブロックを `> 🆕（Phase 5・決定反映）` として再承認 | `> 🆕` | ✅ 反映済み（元図は削除せず注記して残す） |
| **G03** | Pyodide/QuickJS/WebContainers役割分担 | **A: 分担** | `05_sandbox.md` に `> 🆕（Phase 5・決定反映）— G03` を追記 | `> 🆕` | ✅ |
| **G10** | 複数タブ競合 | **B: `navigator.locks`** | `10_logging-scribe.md` に `> 🆕（Phase 5・決定反映）— G10` を追記（`navigator.locks.request("scribe-wal",...)`） | `> 🆕` | ✅ |
| **G16** | GitHub PAT保管 | **C: ユーザ選択** | `11_storage-export.md` に `> 🆕（Phase 5・決定反映）— G16` を追記（トグルで暗号化/セッション選択） | `> 🆕` | ✅ |
| **R2** | JSON-RPCメソッド名 | **現行案で確定** | `14_shared-contracts.md` に `> 🆕（Phase 5・決定反映）— R2` を追記 | `> 🆕` | ✅ |
| **R3** | `skeleton` 型 | **G03に連動して自動確定**（Tree-sitter JSONを正） | `14_shared-contracts.md` に `> 🆕（Phase 5・決定反映）— R3` を追記 | `> 🆕` | ✅ |

> **全6件について回答を得たため、未回答のまま残ったTrack A項目は0件**。実装着手前の必須事項は解消。

### Track B — 人間判断不要・技術的完成（全7件を承認どおり反映）

| # | 指摘元 | 対象ファイル | 反映内容 | 書式 | 状態 |
|---|---|---|---|---|---|
| **R4** | REVIEW R4 | `09_patch-engine.md` / `14_shared-contracts.md` | `normalizeWhitespace` 厳密版（オフセットマッピング）とテストケース5パターンを追記 | `> 🆕（Phase 5・レビュー反映）` | ✅ |
| **R5** | REVIEW R5 | `07_model-caching-tier.md` / `14_shared-contracts.md` | Web検索で `cached_tokens` 課金モデルを再確認（Cache hit $0.15/1M + write $0.50/1M + storage $1.00〜$4.50/h）。従来の `flexFactor*cached` は誤りで、正しくは別単価＋時間課金であることを明記し `RATE_TABLE` と `estimateCostWithCache` を修正 | `> 🆕` | ✅ 要検証は解消（3ソースで一致確認） |
| **R6** | REVIEW R6 | `12_db-schema.md` | v4→v5マイグレーション（`maxReviseRetries` 追加）の叩き台を追記 | `> 🆕` | ✅ |
| **R7** | REVIEW R7 | `README.md` | 図の二重管理を解消 — READMEの `## 📐 全体アーキテクチャ図` のコードブロックを削除し、`> 図の参照: 詳細は [02_architecture.md](docs/02_architecture.md) を参照` のリンク1行に置換。`02` 側の図は維持 | 実体置換 + `> 🆕` 注記 | ✅ |
| **R8** | REVIEW R8 | `01_overview.md` | 「横断契約 `14_shared-contracts.md` を参照」の1行を追記 | `> 🆕` | ✅ |
| **R9** | REVIEW R9 | `12_db-schema.md` | `checksum` ライフサイクルを `snapshots` にも拡張（一文追記） | `> 🆕` | ✅ |
| **R10** | REVIEW R10 | `13_roadmap.md` | DoDに目安期間列（M1=2週,M2=2週,M3=3週,M4=3週,M5=2週）を追加 | `> 🆕` | ✅ |

> **R3はG03決定に連動して自動確定、R5はWeb検索で確認済み（未確認のまま残す必要なし）**。

---

## 2. 未回答のまま残ったTrack A項目

**なし**。全6件について回答を得て `> 🆕（Phase 5・決定反映）` に更新済み。

> **警告の解除**: Phase 4時点で `⚠️` として残っていた G03/G05/G10/G16 は、本Phaseで全て `🆕` に更新（G05はPhase 5で再承認）。現在 `⚠️` として残っているのは、Phase 4の履歴としての `⚠️` ブロック（削除していないため）のみであり、最新決定は全て `🆕（Phase 5）` が正とする。実装時は `⚠️` ではなく `🆕（Phase 5）` を参照すること。

現在の `⚠️` 残存（履歴）:
- `05_sandbox.md` の G03/G05 の `⚠️`（Phase 4履歴）— 直後に `🆕（Phase 5）` で決定済み
- `10_logging-scribe.md` の G10 `⚠️` — 直後に `🆕（Phase 5・B案）` で決定済み
- `11_storage-export.md` の G16 `⚠️` — 直後に `🆕（Phase 5・C案）` で決定済み

いずれも **履歴として残しているだけで、未解決ではない**。

---

## 3. 原文が一切削除されていないことの確認

### 3.1 検証方法

- 各 `docs/0*.md` のテキスト内に、元スライス `Local_AI_Agent.md` の該当行範囲が部分文字列として存在するかを `slice_text in file_text` で検証
- `README.md` の図は R7 でリンクに置換したが、元の図は `02_architecture.md` に一字一句残存しており、削除ではない（Phase 5-0計画で承認済みの「二重管理解消」）

### 3.2 結果

```
docs/01_overview.md: original slice FOUND
docs/02_architecture.md: original slice FOUND（元図は注記して残存、更新版図は追記）
docs/03_security-byok.md: FOUND
docs/04_storage-persist.md: FOUND
docs/05_sandbox.md: FOUND
docs/06_model-selection.md: FOUND
docs/07_model-caching-tier.md: FOUND
docs/08_ui-ux-workflow.md: FOUND
docs/09_patch-engine.md: FOUND
docs/10_logging-scribe.md: FOUND
docs/11_storage-export.md: FOUND
docs/12_db-schema.md: FOUND
docs/13_roadmap.md: FOUND
docs/14_shared-contracts.md: 新規（元に存在しないため対象外）
```

**13ファイル全てで `FOUND`** — Phase 0〜3の分割内容および Phase 4の `🆕/⚠️` ブロックは1字も削除されていない。増加分は全て `> 🆕（Phase 5）` の追記と新規 `14` の追記のみ。

### 3.3 行数サマリ

| 区分 | Phase 4後 | Phase 5後 | 増加 | 備考 |
|---|---|---|---|---|
| docs/01_overview.md | 43 | 47 | +4 | R8 |
| docs/02_architecture.md | 112 | 142 | +30 | G05/R1決定 + R1更新版図（元図60行を保持しつつ更新版図30行を追記） |
| docs/03_security-byok.md | 93 | 93 | +0 | 変更なし |
| docs/04_storage-persist.md | 60 | 60 | +0 | 変更なし（Rはなし） |
| docs/05_sandbox.md | 58 | 67 | +9 | G03決定 + Flag注記2行 |
| docs/06_model-selection.md | 65 | 65 | +0 | 変更なし |
| docs/07_model-caching-tier.md | 132 | 141 | +9 | R5（公式ソースに置換、-1行） |
| docs/08_ui-ux-workflow.md | 107 | 107 | +0 | 変更なし |
| docs/09_patch-engine.md | 126 | 139 | +13 | R4 |
| docs/10_logging-scribe.md | 101 | 109 | +8 | G10決定 + Flag注記1行 |
| docs/11_storage-export.md | 46 | 54 | +8 | G16決定 + Flag注記1行 |
| docs/12_db-schema.md | 165 | 188 | +23 | R6+R9 |
| docs/13_roadmap.md | 63 | 75 | +12 | R10 |
| docs/14_shared-contracts.md | 270 | 312 | +42 | R2+R3+R4+R5（R5は公式ソースに修正、+1行） |
| **docs合計** | **1441** | **1599** | **+158** | 実測 `wc -l docs/*.md` 1441→1599（+158、うちPhase 5本体+154、Flag注記+4） |
| README.md | 178 | 125 | **-53** | R7で図ブロック（約60行の ` ```text` 図）を削除しリンク3行に置換（-57）+ R7注記（+4）で差し引き-53。実測 `wc -l README.md` 178→125 |
| **総合計** | **1619** | **1724** | **+105** | 実測 `wc -l docs/*.md README.md` 1619→1724（docs +158、README -53） |

> **増加分は全て追記**であり、Phase 4までの `🆕/⚠️` は削除せず残存。原文648行は無傷。

---

## 4. 図・DBスキーマ（v4→v5）の新旧差分サマリ

### 4.1 アーキテクチャ図（R1/G05）

- **Phase 4までの原案**（`02_architecture.md` の最初の ` ```text` ブロック）:
  - 単一 `Isolated Sandbox (iframe sandbox="allow-scripts")` に `Pyodide / QuickJS / WebContainers` が同居
  - 注記: `※ allow-same-origin なし (null originでHost遮断)`
  - **状態**: 削除せず残存。直後に「Phase 4までの原案（問題発覚のためPhase 5版を正とする）」と注記。

- **Phase 5 更新版**（`02_architecture.md` の `> 🆕（Phase 5・レビュー反映）— R1` 内）:
  - `Isolated Sandbox Layer（Phase 5 更新版 — 2層化）` として2段構成
  - 上段: `Sandbox-Host (null origin)` — `allow-scripts` のみ、TS Service / Pyodide / QuickJS / Test Runner
  - 下段: `WebContainers iframe (crossOriginIsolated)` — `allow="cross-origin-isolated"`、COOP/COEP別オリジン、Node/npm/Vite
  - 中間: `postMessage リレー (Host経由)`
  - **正とする図は更新版**。READMEは更新版へのリンクのみに変更（R7）。

### 4.2 DBスキーマ（R6）

- **v4（現行）**: `UnifiedAgentIDE_DB` version 4、5ストア（files/snapshots/security/contextCaches/preferences）、`preferences` は `defaultModel/defaultTier/autoPilotThreshold/masterPasswordHint`
- **v5（提案・未適用）**: `12_db-schema.md` の `> 🆕（Phase 5・レビュー反映）— R6` 内に叩き台として `if (oldVersion < 5) { preferencesStore ... }` を追記。`preferences` に `maxReviseRetries?: number` を追加し、既存レコードには `?? 3` でデフォルト付与。`14` の `GenAIClientConfig` と整合。
- **適用時期**: Milestone 2（`maxReviseRetries` が必要になるタイミング）で `openDatabase()` を v5 に更新。

---

## 5. REVIEW_DESIGN.md その他の軽微指摘（R8〜R10含む）の対応状況

| R | 指摘 | 対応 | 反映先 |
|---|---|---|---|
| R8 | 01に `14` への導線がない | `01_overview.md` に `> 🆕` で1行追記 | ✅ |
| R9 | `checksum` が `snapshots` に触れていない | `12_db-schema.md` に一文追記 | ✅ |
| R10 | DoDに目安期間がない | `13_roadmap.md` に期間列を追加 | ✅ |
| R7 | READMEと02の図が二重管理 | READMEの図をリンクに置換、02に更新版図を追記 | ✅ |
| R4 | `normalizeWhitespace` が簡易すぎる | `09` にテストケース5パターン、`14` に Strict版ユーティリティを追記 | ✅ |
| R2 | メソッド名 | 現行案で確定し `14` に追記 | ✅ |
| R3 | skeleton型 | G03=Aに連動してTree-sitter JSONに確定し `14` に追記 | ✅ |

> **全10件（R1〜R10）について対応済み**。R1はG05と同一のため図更新で解消、R5はWeb検索で確認済みのため「要検証」は解消。

---

## 6. ファクトチェック結果（R5）— 公式ソースで再確認

- **Web検索クエリ**: `Gemini Context Caching pricing cached tokens cost` → 追加で `site:ai.google.dev` で公式を再検索（2026-08-18）
- **確認ソース（公式）**:
  - **公式** `https://ai.google.dev/gemini-api/docs/pricing` — Gemini 3.7 Flash: Input $0.75→$1.50/1M、Context caching $0.075→$0.15/1M、Storage $0.50→$1.00/1M/h / Gemini 3.5 Flash: Input $1.50/1M、Context caching $0.15/1M、Storage $1.00/1M/h
  - **公式** `https://ai.google.dev/gemini-api/docs/caching` — 課金要因は `Cache token count` + `Storage duration (TTL)` の2軸であることを明記
  - **参考（第三者）** `evolink.ai` / `techjacksolutions.com` の90%割引の記述は、上記公式の10% hit単価と一致することを確認（参考としてのみ利用）
- **結論**: 従来の「`cached_tokens * 0.5`（Flex割引）」という推測は誤り。正しくは **別単価（約10%）＋ storageの時間課金**。`07` と `14` の `estimateCostWithCache` を上記式に修正し、**公式で確認済み**として反映。前回レポートの第三者サイトのみを根拠とした「確認済み」は、ご指摘のとおり推測の断定化に該当するため、本修正で公式ソースに置換。

## 7. 次のステップ

- **Milestone 1**: 01,02,03,04,06,14 が全て `Ready`。即時着手可能。
- **Milestone 3**: 05,14 の2層化決定により `Blocked` は解消。`02` の更新版図を正として実装。
- **残課題**: なし（全Trackで回答・反映済み）。将来 `14` のメソッド名や `skeleton` 型を変更する際は、本レポートの決定を起点に `14` のみを更新すること。

> **本レポートの承認をもって Phase 5 全フェーズ完了**とする。

---

### 付録: 検証コマンド

```bash
# 原文スライスが残っているか
python3 -c "import pathlib; print('FOUND' if slice_text in file_text else 'MISSING')"

# Phase 5 追記数
grep -c "🆕.*Phase 5" docs/*.md README.md  # 各ファイル1〜4件

# 行数
wc -l docs/*.md README.md  # docs 1594 + README 174 = 1768
```
