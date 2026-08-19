# Phase 0 分割設計書 — Unified Autonomous Agent IDE v4.0（承認ゲート①）

> 対象: `uploads/Local_AI_Agent.md` 全648行 / 11章 + ロードマップ / コードブロック12個 / 表2個 / ASCII図3個  
> 作成日: 2026-08-18 (Asia/Tokyo)  
> ステータス: **承認済み** — docs/集約 + §3・§5 2分割で Phase 1 へ進行

---

## 1. 提案ディレクトリ構成（確定版）

ユーザ承認結果:
- `directory_location = docs_folder`
- `granularity_choice = split_3_and_5`

```
 /home/user/
 ├── README.md                         # インデックス（§2 図を複製）
 ├── PHASE0_design.md                  # 本ファイル（設計書）
 └── docs/
     ├── 01_overview.md                # §1 プロダクト概要
     ├── 02_architecture.md            # §2 アーキテクチャ全体像
     ├── 03_security-byok.md           # §3.1 暗号化BYOK
     ├── 04_storage-persist.md         # §3.2 ゼロ・クラウドファイル保持
     ├── 05_sandbox.md                 # §4 ゼロトラスト実行環境
     ├── 06_model-selection.md         # §5.1-5.3 モデル選定・Interactions・CORS
     ├── 07_model-caching-tier.md      # §5.4-5.5 レート制限・Context Caching
     ├── 08_ui-ux-workflow.md          # §6 モバイルUI/UX・TDD
     ├── 09_patch-engine.md            # §7 パッチ＆検証エンジン
     ├── 10_logging-scribe.md          # §8 ログ・Scribe Agent
     ├── 11_storage-export.md          # §9 エクスポート/インポート
     ├── 12_db-schema.md               # §10 IndexedDBスキーマ
     └── 13_roadmap.md                 # §11 実装ロードマップ
```

**総ファイル数**: 14（README + 章ファイル13）  
**命名規則**: `NN_kebab-case-slug.md`（NN=読む順序 2桁連番）を厳守。READMEのみ例外。

### 1.1 叩き台（Phase0当初の12ファイル案）からの変更点

| 変更箇所 | 叩き台 | 確定版 | 理由 |
|---|---|---|---|
| §3 | `03_security.md` 1ファイル (62行) | `03_security-byok.md` (44行) + `04_storage-persist.md` (18行) に分割 | §3.1（暗号化ロジック・PBKDF2 600k）と§3.2（persist・通信最小化）は論理ドメインが異なり、単独で読まれる頻度が高いため |
| §5 | `05_model-orchestration.md` 1ファイル (113行) | `06_model-selection.md` (25行) + `07_model-caching-tier.md` (88行) に分割 | 113行は最大章。5.1-5.3（モデル選定・API疎通）と5.4-5.5（バックオフ・キャッシュ）は運用時と設計時で参照者が分かれるため |
| 番号繰り上がり | 04_sandbox 以降は+1ずれ | 05_sandbox 以降、全て+1インクリメント | 連番規則維持のため |

§10（115行）も分割候補でしたが、スキーマ定義とマイグレーションは同一トランザクションで理解すべき一体性が高いため今回は見送り（Phase 3 で再検討可能）。

---

## 2. ファイル一覧（ファイル名・対応セクション・行範囲・概要・規模）

| # | ファイル名 | 対応セクション | 行範囲 | 行数 | 概要1行 | コードブロック | 表 |
|---|---|---|---|---|---|---|---|
| 0 | `README.md` | §2 図を複製 + 全章目次 | 25-88の図を複製 + 新規目次 | 新規~120 | 全体地図・推奨読了順・相互参照マップ | 1（図）| 0 |
| 1 | `docs/01_overview.md` | §1 1.1-1.2 | 1-24* | 24 | プロダクト概要と8つのコア設計原則 | 0 | 0 |
| 2 | `docs/02_architecture.md` | §2 | 25-88 | 64 | ブラウザ完結アーキテクチャ全体図とレイヤ関係 | 1 (text) | 0 |
| 3 | `docs/03_security-byok.md` | §3.1 | 89-132 | 44 | AES-GCM-256 / PBKDF2 600,000回 / 暗号化モード2種 | 1 (typescript) | 0 |
| 4 | `docs/04_storage-persist.md` | §3.2 | 133-150 | 18 | IndexedDBローカル永続化と通信最小化 | 1 (typescript) | 0 |
| 5 | `docs/05_sandbox.md` | §4 | 151-162 | 12 | iframe null-origin 二重隔離とJSON-RPC 2.0 | 0 | 0 |
| 6 | `docs/06_model-selection.md` | §5.1-5.3 | 163-187 | 25 | Gemini 3.x統一モデル一覧・Interactions API・CORS | 0 | 1 |
| 7 | `docs/07_model-caching-tier.md` | §5.4-5.5 | 188-275 | 88 | 指数バックオフ・Tier Fallback・Context Caching・Flex/Priority | 2 (typescript) | 0 |
| 8 | `docs/08_ui-ux-workflow.md` | §6 6.1-6.5 | 276-345 | 70 | モバイルDiff承認ゲートとHITL TDDワークフロー | 2 (text) | 0 |
| 9 | `docs/09_patch-engine.md` | §7 7.1-7.2 | 346-415 | 70 | Fuzzy Search&Replace 3段階マッチとコンテキスト注入基準 | 2 (text+ts) | 1 |
| 10 | `docs/10_logging-scribe.md` | §8 8.1-8.2 | 416-482 | 67 | Mutex+WALとFrontmatter+Markdownコスト追跡ログ | 2 (ts+markdown) | 0 |
| 11 | `docs/11_storage-export.md` | §9 9.1-9.2 | 483-500 | 18 | GitHub直連携・Zip・File System Access API | 0 | 0 |
| 12 | `docs/12_db-schema.md` | §10 | 501-615 | 115 | UnifiedAgentIDE_DB v4 スキーマとv1→v4マイグレーション | 1 (typescript) | 0 |
| 13 | `docs/13_roadmap.md` | §11 | 616-648 | 33 | Milestone 1〜5 実装ロードマップ | 0 | 0 |

* `01_overview.md` はタイトル行1-5（`# 🧬 Unified ...` と `---`）を含むため 1-24 と記載。厳密には 1-5 + 6-24。  
**合計**: 元ファイル648行を重複なく分割（READMEの図複製を除く）。コードブロック合計12、表合計2は完全一致。

### 行数整合性チェック計画（Phase 3で実施）

- 実質コンテンツ行数 = 各ファイルのヘッダー（約8行）を除いた本文行数の合計が648行±5行以内であること（ヘッダー重複分を除く）
- `grep -c "```typescript"` etc で前後比較

---

## 3. 相互参照箇所リスト（分割後もMarkdownリンクで辿れるようにする）

| 参照元 | 参照先 | 元記述 | 分割後リンク |
|---|---|---|---|
| §2 アーキテクチャ図 `Encrypted Security Layer` | §3 セキュリティ | 図内の「AES-GCM-256」「PBKDF2 600,000回」 | `02_architecture.md` → `03_security-byok.md` `04_storage-persist.md` |
| §2 `Local Storage Layer` | §3.2 / §9 / §10 | 図内の「navigator.storage.persist()」「files/snapshots」 | `02` → `04` `11` `12` |
| §2 `Isolated Sandbox` | §4 | 図内の「iframe sandbox=\"allow-scripts\"」「postMessage JSON-RPC」 | `02` → `05_sandbox.md` |
| §2 `Gemini 3.x API Cloud` | §5 | 図内のGemini 3.7/3.6/3.5/3.1 | `02` → `06` `07` |
| §9.1 | §3.2 | 「（3.2節参照）」明記 | `11_storage-export.md` → `04_storage-persist.md` に `[(§3.2)](04_storage-persist.md)` としてリンク化 |
| §6.4 TDD Phase4 承認ゲート | §7 パッチエンジン | Phase1 Contract→Wasm検証 は §7.1のFuzzy patchと連携 | `08_ui-ux-workflow.md` → `09_patch-engine.md` |
| §6.4 TDD | §4 サンドボックス | Wasm型チェックはサンドボックス内で実行 | `08` → `05_sandbox.md` |
| §7.2 コンテキスト注入 | §5.5 Context Caching | 表内の「Context Cache推奨/必須」 | `09_patch-engine.md` → `07_model-caching-tier.md` |
| §8 Scribe ログ | §10 スナップショット/DB | `snapshot_id: snap_...` `touched_files` は §10 `snapshots` / `files` ストアに紐づく | `10_logging-scribe.md` → `12_db-schema.md` |
| §10 preferences | §6.5 動作モード | `autoPilotThreshold` は §6.5 Auto-Pilot/Cost-Aware と連動 | `12` ↔ `08` |
| §11 Milestone 1 | §3, §5.3, §4, §9.1 | 「Web Crypto API」「Interactions API」「persist()」 | `13_roadmap.md` → `03` `06` `04` |
| §11 Milestone 2 | §9, §7, §6, §8 | 「仮想FS」「Fuzzy」「Diff承認」「コスト推計」 | `13` → `11` `09` `08` `10` |
| §11 Milestone 3 | §4, §5, §7 | 「iframe JSON-RPC」「Wasm」「AST Router」 | `13` → `05` `07` `09` |
| §11 Milestone 4 | §5.4-5.5, §6.4 | 「TDDステートマシン」「Context Caching」「Tier」 | `13` → `07` `08` |
| §11 Milestone 5 | §8, §10, §9 | 「Scribe」「Mutex+WAL」「スナップショット」「GitHub」「JSZip」 | `13` → `10` `12` `11` |

全リンクは相対パス `../README.md` および `03_security-byok.md` 等で解決。READMEにも「相互参照マップ」章を設ける。

---

## 4. 判断に迷った分割点（選択肢付きで提示 — 今回は承認で確定）

### 4.1 §3 を分割すべきか

- **案A（維持）**: 1ファイル62行。可読性は十分だが論理ドメインが混在。
- **案B（分割・採用）**: 2ファイル（44行+18行）。暗号化と永続化で参照タイミングが異なるため分割が保守性向上。→ **ユーザ選択: B**
- リスク: §3冒頭の `## 3. セキュリティ ＆ ローカルストレージ仕様` 見出しは `03_security-byok.md` にのみ残し、`04_storage-persist.md` は `### 3.2` から開始するが冒頭ヘッダーで文脈補完する。

### 4.2 §5 を分割すべきか

- **案A（維持）**: 1ファイル113行。やや長大。
- **案B（2分割・採用）**: 5.1-5.3（モデル選定系）と5.4-5.5（運用最適化系）で分割。→ **ユーザ選択: B**
- **案C（3分割）**: 5.1 / 5.4 / 5.5 の3ファイル。粒度が細かすぎて相互参照が煩雑になるため不採用。

### 4.3 §10 を分割すべきか

- **案A（維持・採用）**: 1ファイル115行。スキーマ定義とマイグレーションは同一ファイルでトランザクション的に読むべき。
- **案B（2分割）**: `10_db-schema.md`（型定義）と`10b_migration.md`（openDatabase）に分割。可読性は上がるが、DBバージョンの一体性が失われるため見送り。

### 4.4 コードブロックの帰属

- 全12ブロックは単一セクションに帰属が自明（跨ぎなし）。§5の `GEMINI_TIER_ORDER` と `createContextCache` はともに §5 内だが分割点188で明確に分離可能。

---

## 5. リスク事前申告と矛盾チェック

- **表記ゆれ・バージョン不整合**: なし。以下を確認済み
  - PBKDF2 600,000回 / SHA-256 / 256-bit Salt / 96-bit IV は §2図・§3本文・コードで一致
  - AES-GCM-256 は全箇所一致
  - DB名 `UnifiedAgentIDE_DB` Version 4 は §2図・§10コードで一致
  - Geminiモデル名（3.7 Flash / 3.6 Flash / 3.5 Flash / 3.5 Flash-Lite / 3.1 Pro）とコスト単価は §2図と§5.1表で一致
  - Context Caching 75〜90%削減、TTL最大3600秒は §5.4・§5.5・§10 `ttlSeconds` で一致
  - `allow-scripts` のみ（`allow-same-origin`なし）は §2図と§4で一致
- **軽微な表記**: §8ログ例内の `estimated_usd: 0.023` と §5.1のコスト単価からの計算は例示であり矛盾ではない
- **対応方針**: 矛盾を発見した場合は Phase 3 検証レポートで報告のみ行い、元ファイルの数値は一字一句変更しない

---

## 6. 各ファイル冒頭の共通ヘッダー仕様

```markdown
<!-- 元ファイル: Local_AI_Agent.md §X Lines A-B -->
# 対応章タイトル

> **親ドキュメント**: [Local_AI_Agent.md](../../uploads/Local_AI_Agent.md)
> **インデックス**: [README.md](../../README.md) | [Phase0設計書](../../PHASE0_design.md)
> **関連ファイル**: [02_architecture.md](./02_architecture.md) | [03_security-byok.md](./03_security-byok.md) ...
> **元セクション**: §X（Lines A-B）

> **要約**: 本ファイルは ... を定義する。単独で読めるが、全体像は README のアーキテクチャ図を参照。

---
（本文：元ファイルからのコピーを一字一句維持）
---
> **次へ**: [05_sandbox.md](./05_sandbox.md) → ゼロトラスト実行環境
```

- コメント行で元行範囲を機械検証可能に
- 関連ファイルは相互参照リストに基づく双方向リンク
- 要約は原文を要約せず「何が書いてあるか」の1行メタ情報のみ（仕様の言い換えはしない）

---

## 7. Phase 1 実行計画

1. `docs/` ディレクトリ作成
2. 上記行範囲で `sed -n` 抽出し、ヘッダー付与して13ファイル作成
3. `README.md` 新設（アーキテクチャ図複製 + 目次 + 推奨読了順 + 相互参照マップ）
4. Phase 2 完了後、Phase 3 検証（行数・コードブロック・表の前後一致）へ

---

## 8. 承認

- [x] Phase 0 承認: `approve_as_is`（ただし Q2 で split_3_and_5 を明示選択）→ split_3_and_5 を優先して確定
- [x] 配置: `docs_folder`
- 次の承認ゲート: Phase 3 完了時

