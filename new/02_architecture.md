<!-- 統合版: docs/02_architecture.md の Phase 4〜5 追記（G05/R1 2層化）を本文にマージ（元: Local_AI_Agent.md §2 Lines 25-88） -->
# 02 システムアーキテクチャ全体像

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local%20AI%20Agent.md)（§2 Lines 25-88）
> **インデックス**: [README.md](./README.md)
> **関連ファイル**: [01_overview.md](./01_overview.md) | [03_security-byok.md](./03_security-byok.md) | [04_storage-persist.md](./04_storage-persist.md) | [05_sandbox.md](./05_sandbox.md) | [06_model-selection.md](./06_model-selection.md)

> **要約**: 本ファイルはブラウザ完結型アーキテクチャ全体図（Mobile-First UI / Orchestrator / Security / Storage / Gemini Cloud / Sandbox）を定義する。全体地図として機能し、他章は本図の各レイヤの詳細である。サンドボックス層は **2層構成（Sandbox-Host + WebContainers）** を正とする（§2.1）。

> **ナビゲーション**: ← [01_overview.md](./01_overview.md) | [03_security-byok.md](./03_security-byok.md) →

---

## 2. システムアーキテクチャ全体像

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        User Device Browser (Mobile / Tablet / PC)                      │
│                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐  │
│  │   Mobile-First UI Layer (PWA)                                                    │  │
│  │  - Claude Code Style Terminal & Chat UI                                          │  │
│  │  - One-Hand Diff Approval Gate (スワイプ / タップ承認)                           │  │
│  │  - In-App Web Live Preview (iframe / Blob URL)                                   │  │
│  │  - Monaco Editor / Mobile Code View                                              │  │
│  │  - Storage Exporter (Zip / File System Access API)                               │  │
│  └────────────────────────────────────────┬─────────────────────────────────────────┘  │
│                                           │                                            │
│                                           ▼                                            │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐  │
│  │                   Client Agent Orchestrator & IDE Core                           │  │
│  │  - Gemini 3.x Family Router (3.7F ↔ 3.6F ↔ 3.5F ↔ 3.5FL)                         │  │
│  │  - AST Context Router (Tree-sitter / Babel Wasm)                                 │  │
│  │  - Context Caching Manager (AST Skeleton / System Prompt キャッシュ)              │  │
│  │  - Fuzzy Search & Replace Engine (差分パッチ適用)                                │  │
│  │  - TDD State Machine with Human Approval Gate                                    │  │
│  │  - Scribe Agent (1作業1Markdownログ非同期記録 + Mutex WAL)                        │  │
│  │  - GitHub API Client (直接コミット / PR作成)                                     │  │
│  └──────────────────┬───────────────────────────────────┬───────────────────────────┘  │
│                     │                                   │                              │
│                     ▼                                   ▼                              │
│  ┌─────────────────────────────────────┐  ┌─────────────────────────────────────────┐  │
│  │ Encrypted Security Layer            │  │ Local Storage Layer (IndexedDB)         │  │
│  │  - Web Crypto API (AES-GCM-256)     │  │  - navigator.storage.persist()          │  │
│  │  - PBKDF2 (600,000回 SHA-256)       │  │  - Schema Migration (v1 -> vN)          │  │
│  │  - 5分無操作 メモリ自動破棄         │  │  - files (ローカル仮想FS: 外部送信なし) │  │
│  │  - 完全ローカル保管 (盗難リスク排除)│  │  - snapshots (巻き戻し用履歴)           │  │
│  │  - セッション限定モード対応         │  │  - logs (.agent/logs/ 構造化記録)       │  │
│  │                                     │  │  - preferences (設定・プリファレンス)   │  │
│  └─────────────────────────────────────┘  └─────────────────────────────────────────┘  │
└───────────────────────────────────────┬────────────────────────────────────────────────┘
                                        │ Direct HTTPS (Interactions API / CORS)
                                        │ ※ソースコード全体は送らず、差分・プロンプトのみ通信
                                        ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                          Google Gemini 3.x API Cloud                                   │
│  - Gemini 3.7 Flash (コーディング・推論主軸 / 2026年末まで紹介価格)                    │
│  - Gemini 3.6 Flash / 3.5 Flash (フォールバック)                                       │
│  - Gemini 3.5 Flash-Lite (Scribeログ記録 / Flex Tier)                                  │
│  - Gemini 3.1 Pro (巨大設計・難関リファクタリング)                                     │
│  - Context Caching (75〜90% トークンコスト削減)                                        │
└────────────────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        │ postMessage (Structured JSON-RPC 2.0)
                                        ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        Isolated Sandbox Layer (2層構成 — 詳細は §2.1)                  │
│  - Sandbox-Host (null origin): iframe sandbox="allow-scripts"                          │
│  - WebContainers iframe (crossOriginIsolated): Node.js / npm / Vite 互換               │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.1 サンドボックス層の2層分離（Sandbox-Host / WebContainers）

サンドボックス層は以下の2層構成を正とする。Wasm型チェック等の高特権に近い処理と、Node.js互換ランタイムを物理的に分離する。

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│              Isolated Sandbox Layer（2層化）                                           │
│                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────┐     │
│  │  Sandbox-Host (null origin)  iframe sandbox="allow-scripts"                  │     │
│  │   ※ allow-same-origin なし → null originでHost遮断                          │     │
│  │   - TypeScript Language Service (Wasm)  - Pyodide / QuickJS                 │     │
│  │   - Automated Test Runner (Vitest/Jest Wasm)  - ESLint / Prettier Wasm      │     │
│  │   - Structured Output Validator (Zod/AJV Wasm)                              │     │
│  └──────────────────────────────┬───────────────────────────────────────────────┘     │
│                                 │ postMessage リレー (Host経由)                        │
│                                 ▼                                                      │
│  ┌──────────────────────────────────────────────────────────────────────────────┐     │
│  │  WebContainers iframe (crossOriginIsolated)  allow="cross-origin-isolated"   │     │
│  │   ※ COOP: same-origin + COEP: require-corp を配信する別オリジンで配信        │     │
│  │   - Node.js / npm / Vite 互換  - WebContainers Runner                        │     │
│  └──────────────────────────────────────────────────────────────────────────────┘     │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

**構成の要点**:

- **Sandbox-Host（null origin）**: `iframe sandbox="allow-scripts"`（`allow-same-origin` は付与しない）。オリジンが強制的に `null` となり、親の DOM・LocalStorage・IndexedDB・Cookie へのアクセスがブラウザレベルで遮断される。TypeScript Language Service (Wasm)、Pyodide、QuickJS、Test Runner、Lint、Zod/AJV バリデータをここで実行する。
- **WebContainers iframe（crossOriginIsolated）**: Node.js / npm / Vite 互換のランタイム専用。`allow="cross-origin-isolated"` を付与し、`Cross-Origin-Opener-Policy: same-origin` と `Cross-Origin-Embedder-Policy: require-corp` ヘッダを配信する**別オリジン**から提供する。
- **連携**: 2つの iframe 間の通信は Host を経由した `postMessage` リレーとする。通信契約の詳細は [14_shared-contracts.md](./14_shared-contracts.md) §5 を参照。

**本構成の根拠**: WebContainers は `SharedArrayBuffer` を使用するため `crossOriginIsolated` が必須であり（公式 `webcontainers.io/troubleshooting`、GitHub Issue #37 で確認済み）、単一の `null origin` iframe とは両立しない。したがって2層化（A案）が唯一の両立解として正式採用された。npm 互換を失い `vite`/`vitest` の実行が不可になるため、WebContainers廃止への縮退（B案）は不採用とする。

---

> **出典**: `Local_AI_Agent.md` §2（Lines 25-88）。サンドボックス層のみ Phase 4〜5 の決定（G05/R1）に基づき2層構成へ統合した統合版である。
> **相互参照**: [01_overview.md](./01_overview.md) | [03_security-byok.md](./03_security-byok.md) | [04_storage-persist.md](./04_storage-persist.md) | [05_sandbox.md](./05_sandbox.md) | [06_model-selection.md](./06_model-selection.md) | [README.md](./README.md)
