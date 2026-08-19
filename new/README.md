<!-- 統合版インデックス: docs/*.md（Phase 0〜5 の補足含む）を本文にマージしたクリーン版の全体地図 -->
# 🧬 Unified Autonomous Agent IDE 実装仕様書 v4.0（統合版）— インデックス

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local%20AI%20Agent.md)（全648行・全11章＋ロードマップ）
> **版**: 本 `new/` ディレクトリは、ルートの `docs/*.md` に追記された Phase 0〜5 の詳細化補足（`🆕` / `⚠️` ブロック）を本文に完全にマージした**統合版**である。履歴付きの原文＋追記版は `../docs/` にそのまま残している。
> **文字コード**: UTF-8 / **形式**: Markdown / **構成**: 13章＋共通契約1ファイル（計14ファイル）＋本インデックス

> **要約**: 単一巨大ファイルだった技術仕様書を、論理ドメイン単位の14ファイルに分割し、レビュー・決定事項のすべてを本文に統合した、実装可能な状態の仕様書である。

---

## 📐 全体アーキテクチャ図

> **図の参照**: 詳細なアーキテクチャ図は [02_architecture.md](./02_architecture.md) を参照。サンドボックス層は2層構成（Sandbox-Host + WebContainers）を正とする。

> **凡例**: 上段=User Device Browser（PWA UI / Orchestrator / Security / Storage）、中段=Gemini Cloud（HTTPS直結）、下段=Isolated Sandbox Layer（postMessage JSON-RPC 2.0）。

---

## 📚 ファイル一覧（読む順序 = ファイル名の NN 順）

| NN | ファイル | 概要 | キー数値・キーワード |
|---|---|---|---|
| 01 | [01_overview.md](./01_overview.md) | プロダクト概要と8つのコア設計原則 | Zero-Install / Local-Only / BYOK |
| 02 | [02_architecture.md](./02_architecture.md) | システムアーキテクチャ全体像（Sandbox 2層構成含む） | 全体図 / §2.1 2層Sandbox |
| 03 | [03_security-byok.md](./03_security-byok.md) | 暗号化BYOK — 暗号化・復号・モード選択 | `AES-GCM-256` `PBKDF2 600k` `256-bit Salt` `96-bit IV` `decryptApiKey` |
| 04 | [04_storage-persist.md](./04_storage-persist.md) | ゼロ・クラウドファイル保持 — IndexedDB永続化と拒否時フォールバック | `navigator.storage.persist()` |
| 05 | [05_sandbox.md](./05_sandbox.md) | ゼロトラスト実行環境 — 2層Sandboxとランタイム3者分担 | `null origin` `Pyodide/QuickJS/WebContainers` |
| 06 | [06_model-selection.md](./06_model-selection.md) | Gemini 3.xモデル選定・Interactions API（GA済み）・CORS | 5モデル表 / `@google/genai` `interactions.create` |
| 07 | [07_model-caching-tier.md](./07_model-caching-tier.md) | レート制限バックオフ・Tier Fallback・Context Caching・コスト推計式 | 75〜90%削減 / Flex 50%割引 / cache hit 別単価 |
| 08 | [08_ui-ux-workflow.md](./08_ui-ux-workflow.md) | モバイルUI/UXとHITL TDDワークフロー・Revise上限 | Diff承認ゲート / TDD 4 Phase / `maxReviseRetries=3` |
| 09 | [09_patch-engine.md](./09_patch-engine.md) | Fuzzy Search&Replace（正規化実装・厳密版Fuzzy含む）とコンテキスト注入基準 | 3段階マッチ / 300行閾値 |
| 10 | [10_logging-scribe.md](./10_logging-scribe.md) | Scribe Agent — Mutex+WAL・複数タブ排他（navigator.locks）・コストライフサイクル | `.agent/logs/SEQ_...` `scribe-wal` |
| 11 | [11_storage-export.md](./11_storage-export.md) | ストレージ永続化宣言とエクスポート/インポート・PAT保管（ユーザ選択） | GitHub / JSZip / File System Access |
| 12 | [12_db-schema.md](./12_db-schema.md) | IndexedDBスキーマ v4・checksum・バリデーション・v5移行計画 | `UnifiedAgentIDE_DB` v4→v5 / 5 stores |
| 13 | [13_roadmap.md](./13_roadmap.md) | 実装ロードマップ Milestone 1〜5・DoD・目安期間 | M1=2週 ... 全12週 |
| 14 | [14_shared-contracts.md](./14_shared-contracts.md) | 横断的共通契約の単一ソース — JSON-RPC / TDD型 / GenAI初期化 / コストレート / 分離Sandbox / StrictFuzzyPatch | `postMessage` `TDDState` `RATE_TABLE` |

**命名規則**: `NN_kebab-case-slug.md`（NN=読む順序）。

---

## 🗺️ 推奨読了順

### A. 実装者が手を動かす順（[13_roadmap.md](./13_roadmap.md) 準拠）

```
Phase 1 — 基盤: 01 → 02 → 03 → 04 → 06(5.1-5.3) → 11(§9.1 persist)
Phase 2 — ファイルと承認: 04 → 09 → 08 → 10の一部(cost推計)
Phase 3 — サンドボックス: 05 → 09(再読) → 07の一部(5.5 CacheのAST)
Phase 4 — オーケストレーション: 06 → 07 → 08(§6.4 TDD)
Phase 5 — ログと外部連携: 10 → 12 → 11
```

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

| 参照元 | 参照先 | 内容 |
|---|---|---|
| 02_architectureのSecurity層 | 03_security-byok | AES-GCM-256 / PBKDF2 600k / decryptApiKey |
| 02のStorage層 | 04・11・12 | persist / files/snapshots/logs |
| 02のSandbox（§2.1） | 05_sandbox・14 §5 | 2層Sandbox / postMessage リレー |
| 02のGemini Cloud | 06/07 | 3.7F/3.6F/3.5F/Lite/Pro |
| 11 §9.1 | 04 §3.2 | persist() 永続化宣言 |
| 08 §6.4 Phase4 | 09 §7 | Approval Gate → Fuzzy適用 |
| 08 §6.4 | 05 §4 | Wasm型チェックはサンドボックスで実行 |
| 08 §6.6 | 12 §10.4 | maxReviseRetries の v5 移行 |
| 09 §7.1 | 14 §2 | StrictFuzzyPatch 厳密版 |
| 09 §7.2 表 | 07 §5.5 | Context Cache推奨/必須 |
| 10 §8.2 | 12 §10 | snapshot_id / touched_files → snapshots/filesストア |
| 10 §8.1.1・14 §1 | navigator.locks | 複数タブ排他 `"scribe-wal"` |
| 12 preferences | 08 §6.5 | autoPilotThreshold → 動作モード |
| 13 Milestone | 全章 | 各Milestoneが対応章を参照 |
| 全ファイル | 14_shared-contracts | 横断契約（JSON-RPC/TDD/GenAI/コスト/Persist）の単一ソース |

---

## 📊 仕様中のキー数値

- 暗号化: `AES-GCM-256` / `PBKDF2 600,000 iterations` / `SHA-256` / `256-bit Salt` / `96-bit IV` / `5分無操作破棄`
- コスト: `Gemini 3.7 Flash` / `3.6 Flash 1.50 in / 7.50 out` / `3.5 Flash 1.50/9.00` / `3.5 Flash-Lite 0.15/0.60` / `3.1 Pro 2.00/12.00 @200K` / `75〜90%削減` / `Flex 50%割引` / cache hit は別単価（約10%）＋storage時間課金（公式構造）
- ストレージ: `UnifiedAgentIDE_DB v4`（v5移行計画あり） / `navigator.storage.persist()` / `files / snapshots / security / contextCaches / preferences`
- サンドボックス: `iframe sandbox="allow-scripts"` / `allow-same-originなし` / 2層構成（`crossOriginIsolated` の WebContainers iframe併設）/ `postMessage JSON-RPC 2.0` / `event.origin === 'null'`
- パッチ: `AMBIGUOUS_MATCH` / `NO_MATCH` / `SYNTAX_ERROR` / `前後5行` / `300行閾値`
- メソッド確定（14 §1.4）: `typeCheck` / `runTests` / `validateOutput` / `extractSkeleton` / `applyPatch` / `lint`

---

## 🛠️ 使い方

- **GitHubプレビュー**: 各 `*.md` は単独で開いても冒頭の「要約」「関連ファイル」で文脈が掴める
- **一括検索**: `grep -r "PBKDF2" new/` で横断検索
- **原文との照合**: `../docs/` に補足ブロック付きの履歴版、最終的な決定根拠は `../PHASE5_report.md` と `../REVIEW_DESIGN.md` に残っている

---

> **次のステップ**: [01_overview.md](./01_overview.md) から読み始めるか、上図で気になるレイヤの章へジャンプしてください。横断的な型契約は [14_shared-contracts.md](./14_shared-contracts.md) を先に読むと実装がスムーズです。
