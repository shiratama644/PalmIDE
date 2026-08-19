<!-- 元ファイル: Local_AI_Agent.md 全体インデックス（§2 図を複製） -->
# 🧬 Unified Autonomous Agent IDE 実装仕様書 v4.0 — インデックス

> **親ドキュメント**: [Local_AI_Agent.md](uploads/Local_AI_Agent.md)（全648行・全11章＋ロードマップ）
> **Phase0設計書**: [PHASE0_design.md](PHASE0_design.md) | **Phase4-0ギャップ一覧**: [PHASE4_0_gaplist.md](PHASE4_0_gaplist.md) | **Phase4レポート**: [PHASE4_report.md](PHASE4_report.md)（作成後）
> **文字コード**: UTF-8 / **形式**: Markdown / **分割方式**: 意味単位（章＝論理ドメイン）で13ファイル＋共通契約1ファイルの計14ファイルに再編成（Phase 4で横断契約を集約）

> **要約**: 本インデックスは、単一巨大ファイルだった技術仕様書を保守性・可読性の高い複数ファイル構成へ再設計した全体地図である。各ファイルは単独でも文脈を失わずに読めるよう冒頭に要約・関連リンク・元行範囲を付与し、章をまたぐ相互参照はMarkdownリンクで辿れる。

---

## 📐 全体アーキテクチャ図（§2 より複製・一字一句維持）

> 出典: `Local_AI_Agent.md` Lines 25-88（`docs/02_architecture.md` と同一）

> **図の参照**: 詳細なアーキテクチャ図は [02_architecture.md](docs/02_architecture.md) を参照してください。  
> （Phase 5 R7 により、本READMEの図複製はリンクに置換。最新の2層化図は `02` が正とする。）

> **凡例**: 上段=User Device Browser（PWA UI / Orchestrator / Security / Storage）、中段=Gemini Cloud（HTTPS直結）、下段=Isolated Sandbox（postMessage）。詳細は [02_architecture.md](docs/02_architecture.md) を参照。

---

## 📚 ファイル一覧（読む順序 = ファイル名の NN 順）

| NN | ファイル | 元セクション | 行範囲 | 概要 | キー数値・キーワード |
|---|---|---|---|---|---|
| 01 | [01_overview.md](docs/01_overview.md) | §1 1.1-1.2 | 1-24 | プロダクト概要と8つのコア設計原則 | Zero-Install / Local-Only / BYOK |
| 02 | [02_architecture.md](docs/02_architecture.md) | §2 | 25-88 | システムアーキテクチャ全体像（上図の詳細） | 図1枚・全レイヤ俯瞰 |
| 03 | [03_security-byok.md](docs/03_security-byok.md) | §3.1 | 89-132 | 暗号化BYOK — AES-GCM-256 / PBKDF2 600,000回 | `AES-GCM-256` `PBKDF2 600k` `256-bit Salt` `96-bit IV` |
| 04 | [04_storage-persist.md](docs/04_storage-persist.md) | §3.2 | 133-150 | ゼロ・クラウドファイル保持 — IndexedDB永続化 | `navigator.storage.persist()` |
| 05 | [05_sandbox.md](docs/05_sandbox.md) | §4 | 151-162 | ゼロトラスト実行環境 — iframe null-origin隔離 | `sandbox="allow-scripts"` `null origin` |
| 06 | [06_model-selection.md](docs/06_model-selection.md) | §5.1-5.3 | 163-187 | Gemini 3.xモデル選定・Interactions API・CORS | 5モデル表 / `@google/genai` |
| 07 | [07_model-caching-tier.md](docs/07_model-caching-tier.md) | §5.4-5.5 | 188-275 | レート制限バックオフ・Tier Fallback・Context Caching | 75〜90%削減 / Flex 50%割引 |
| 08 | [08_ui-ux-workflow.md](docs/08_ui-ux-workflow.md) | §6 6.1-6.5 | 276-345 | モバイルUI/UXとHITL TDDワークフロー | Diff承認ゲート / TDD 4 Phase |
| 09 | [09_patch-engine.md](docs/09_patch-engine.md) | §7 7.1-7.2 | 346-415 | Fuzzy Search&Replaceとコンテキスト注入基準 | 3段階マッチ / 300行閾値 |
| 10 | [10_logging-scribe.md](docs/10_logging-scribe.md) | §8 8.1-8.2 | 416-482 | Scribe Agent — Mutex+WALとMarkdownログ | `.agent/logs/SEQ_...` `cost_estimate` |
| 11 | [11_storage-export.md](docs/11_storage-export.md) | §9 9.1-9.2 | 483-500 | ストレージ永続化宣言とエクスポート/インポート | GitHub / JSZip / File System Access |
| 12 | [12_db-schema.md](docs/12_db-schema.md) | §10 | 501-615 | IndexedDBスキーマ v4とマイグレーション | `UnifiedAgentIDE_DB` v4 / 5 stores |
| 13 | [13_roadmap.md](docs/13_roadmap.md) | §11 | 616-648 | 実装ロードマップ Milestone 1〜5 | 優先順位順 |
| 14 | [14_shared-contracts.md](docs/14_shared-contracts.md) | —（Phase 4 新規） | — | 横断的共通契約 — JSON-RPC / TDD型 / GenAI初期化 / コストレート | `postMessage` `TDDState` `RATE_TABLE` |

**命名規則**: `NN_kebab-case-slug.md`（NN=読む順序）。全文648行を重複なく分割（READMEの図複製を除く）。コードブロック12個・表2個は一字一句維持。Phase 4で横断契約を `14_shared-contracts.md` に集約（既存13ファイルの原文は無傷）。

---

## 🗺️ 推奨読了順（実装ロードマップ準拠）

仕様を「作る順」に読む場合（[13_roadmap.md](docs/13_roadmap.md) 準拠）と、「理解する順」に読む場合の2通りを示す。

### A. 実装者が手を動かす順（ロードマップ準拠）

```
Phase 1 — 基盤: 01 → 02 → 03 → 04 → 06(5.1-5.3) → 11(§9.1 persist)
Phase 2 — ファイルと承認: 04 → 09 → 08 → 10の一部(cost推計)
Phase 3 — サンドボックス: 05 → 09(再読) → 07の一部(5.5 CacheのAST)
Phase 4 — オーケストレーション: 06 → 07 → 08(§6.4 TDD)
Phase 5 — ログと外部連携: 10 → 12 → 11
```

詳細は [13_roadmap.md](docs/13_roadmap.md) の Milestone 1〜5 を参照。

### B. 初回読了で全体像を掴む順（推奨）

```
01_overview（なぜ作るか）
 → 02_architecture（全体地図）
 → 08_ui-ux-workflow（ユーザが触る部分）
 → 05_sandbox（安全性の核）
 → 03/04（セキュリティと永続化）
 → 06/07（Geminiオーケストレーション）
 → 09 → 10 → 12 → 11 → 13
```

---

## 🔗 相互参照マップ

> 分割後も辿れるよう、全ての章またぎ言及をMarkdownリンク化済み。各ファイル冒頭の「関連ファイル」にも双方向リンクあり。

| 参照元 | 参照先 | 内容 | リンク |
|---|---|---|---|
| 02_architectureのSecurity層 | 03_security-byok | AES-GCM-256 / PBKDF2 600k | [03](./docs/03_security-byok.md) |
| 02のStorage層 | 04・11・12 | persist / files/snapshots/logs | [04](./docs/04_storage-persist.md) [11](./docs/11_storage-export.md) [12](./docs/12_db-schema.md) |
| 02のSandbox | 05_sandbox | iframe sandbox / postMessage | [05](./docs/05_sandbox.md) |
| 02のGemini Cloud | 06/07 | 3.7F/3.6F/3.5F/Lite/Pro | [06](./docs/06_model-selection.md) [07](./docs/07_model-caching-tier.md) |
| 11_storage-export §9.1 | 04_storage-persist §3.2 | `（3.2節参照）` | [04](./docs/04_storage-persist.md) |
| 08_ui-ux §6.4 Phase4 | 09_patch-engine §7 | Approval Gate → Fuzzy適用 | [09](./docs/09_patch-engine.md) |
| 08 §6.4 | 05_sandbox §4 | Wasm型チェックはSandbox内で実行 | [05](./docs/05_sandbox.md) |
| 09 §7.2 表 | 07_model-caching §5.5 | Context Cache推奨/必須 | [07](./docs/07_model-caching-tier.md) |
| 10_logging §8 | 12_db-schema §10 | snapshot_id / touched_files → snapshots/filesストア | [12](./docs/12_db-schema.md) |
| 12 preferences | 08 §6.5 | autoPilotThreshold → 動作モード | 相互 |
| 13_roadmap Milestone | 全章 | 各Milestoneが対応章を参照 | [13](./docs/13_roadmap.md) |
| 14_shared-contracts | 05/06/07/08/09/10 | 横断契約の単一ソース（JSON-RPC/TDD/GenAI/コスト） | [14](./docs/14_shared-contracts.md) |
| G04/G08/G14 横断 | 14_shared-contracts | 各ファイルの `🆕` 補足から本ファイルへ集約 | [14](./docs/14_shared-contracts.md) |

---

## 📊 技術的数値の不変保証

以下の数値は分割前後で一字一句変更していない（Phase 3で自動検証）:

- 暗号化: `AES-GCM-256` / `PBKDF2 600,000 iterations` / `SHA-256` / `256-bit Salt` / `96-bit IV` / `5分無操作破棄`
- コスト: `Gemini 3.7 Flash` / `3.6 Flash 1.50 in / 7.50 out` / `3.5 Flash 1.50/9.00` / `3.5 Flash-Lite 0.15/0.60` / `3.1 Pro 2.00/12.00 @200K` / `75〜90%削減` / `Flex 50%割引`
- ストレージ: `UnifiedAgentIDE_DB v4` / `navigator.storage.persist()` / `files / snapshots / security / contextCaches / preferences`
- サンドボックス: `iframe sandbox="allow-scripts"` / `allow-same-originなし` / `postMessage JSON-RPC 2.0` / `event.origin === 'null'`
- パッチ: `AMBIGUOUS_MATCH` / `NO_MATCH` / `SYNTAX_ERROR` / `前後5行` / `300行閾値`

---

## 🛠️ 使い方

- **GitHubプレビュー**: 各 `docs/*.md` は単独で開いても冒頭の「要約」「関連ファイル」で文脈が掴める
- **一括検索**: `grep -r "PBKDF2" docs/` で横断検索
- **行数検証**: `wc -l uploads/Local_AI_Agent.md docs/*.md` で整合性確認
- **Phase0設計書**: 分割の判断理由は [PHASE0_design.md](PHASE0_design.md) に記録

---

> 🆕 **詳細化補足（Phase 5・レビュー反映）— R7 図の二重管理解消**
> - **指摘元**: REVIEW_DESIGN.md R7
> - **内容**: 本READMEのアーキテクチャ図ブロック（`## 📐 全体アーキテクチャ図`）は、`docs/02_architecture.md` と二重管理になっている。Phase 5で README側の図を **リンクのみ** に変更する方針を決定。本補足をもって、将来の図更新は `02_architecture.md` のみを正とし、READMEはリンクを参照する運用に移行する。Phase 5-1 で README の図ブロックをリンク1行に置換する改修を別途実施する。

> **次のステップ**: [01_overview.md](docs/01_overview.md) から読み始めるか、上図で気になるレイヤの章へジャンプしてください。横断的な型契約は [14_shared-contracts.md](docs/14_shared-contracts.md) を先に読むと実装がスムーズです。
> **検証**: Phase 3 レポートは [PHASE3_report.md](PHASE3_report.md)、Phase 4 の詳細は [PHASE4_report.md](PHASE4_report.md) にまとまる。

