<!-- 元ファイル: Local_AI_Agent.md §2 Lines 25-88 -->
# 02 システムアーキテクチャ全体像

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local_AI_Agent.md)
> **インデックス**: [README.md](../README.md) | [Phase0設計書](../PHASE0_design.md)
> **関連ファイル**: [01_overview.md](./01_overview.md) | [03_security-byok.md](./03_security-byok.md) | [04_storage-persist.md](./04_storage-persist.md) | [05_sandbox.md](./05_sandbox.md) | [06_model-selection.md](./06_model-selection.md) | [README.md](../README.md)
> **元セクション**: §2（Lines 25-88）

> **要約**: 本ファイルはブラウザ完結型アーキテクチャ全体図（Mobile-First UI / Orchestrator / Security / Storage / Gemini Cloud / Sandbox）を定義する。全体地図として機能し、他章は本図の各レイヤの詳細である。

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
│                        Isolated Sandbox (iframe sandbox="allow-scripts")               │
│                        ※ `allow-same-origin` なし (null originでHost遮断)               │
│                                                                                        │
│  - TypeScript Language Service (Wasm)  - Pyodide / QuickJS / WebContainers Runner      │
│  - Automated Test Runner (Vitest/Jest Wasm)  - ESLint / Prettier Wasm                  │
│  - Structured Output Validator (Zod/AJV Wasm)                                          │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---



> 🆕 **詳細化補足（Phase 4-決定反映 2026-08-18）— G05 2層化アーキテクチャ**
> - **対象**: 元図の下段 `Isolated Sandbox (iframe sandbox="allow-scripts")` が単一iframeで WebContainers を含む点
> - **種別**: 🟡要確認の解消（決定）
> - **内容**: レビューで G05 を A案（2層化）に決定したため、下段を以下の2層構成に読み替える。元図は一字一句維持し、本補足が正とする。
>   ```text
>   ┌────────────────────────────────────────────────────────────────────────────────────────┐
>   │              Isolated Sandbox Layer（2層化 — G05決定反映）                           │
>   │                                                                                      │
>   │  ┌──────────────────────────────────────────────────────────────────────────────┐   │
>   │  │  Sandbox-Host (null origin)  iframe sandbox="allow-scripts"                  │   │
>   │  │   ※ allow-same-origin なし → null originでHost遮断                          │   │
>   │  │   - TypeScript Language Service (Wasm)  - Pyodide / QuickJS                 │   │
>   │  │   - Automated Test Runner (Vitest/Jest Wasm)  - ESLint / Prettier Wasm      │   │
>   │  │   - Structured Output Validator (Zod/AJV Wasm)                              │   │
>   │  └──────────────────────────────┬───────────────────────────────────────────────┘   │
>   │                                 │ postMessage リレー (Host経由)                    │
>   │                                 ▼                                                  │
>   │  ┌──────────────────────────────────────────────────────────────────────────────┐   │
>   │  │  WebContainers iframe (crossOriginIsolated)  allow="cross-origin-isolated"   │   │
>   │  │   ※ COOP: same-origin + COEP: require-corp を配信する別オリジンで配信        │   │
>   │  │   - Node.js / npm / Vite 互換  - WebContainers Runner                        │   │
>   │  └──────────────────────────────────────────────────────────────────────────────┘   │
>   └────────────────────────────────────────────────────────────────────────────────────────┘
>   ```
>   Host（null origin）と WebContainers（crossOriginIsolated）は `postMessage` で Host を経由してリレーする。詳細は [14_shared-contracts.md](./14_shared-contracts.md) §5 を参照。
> - **根拠**: WebContainersが `SharedArrayBuffer` のため `crossOriginIsolated` 必須であることを公式（webcontainers.io/troubleshooting, GitHub #37）で確認。単一 null origin では起動しないため、2層化が唯一の両立解。
> - **関連**: 本決定により `05_sandbox.md` の G05 `⚠️` は解消済み。M3 Sandbox の実装は本図で進める。

> 🆕 **詳細化補足（Phase 5・決定反映）— G05/R1 2層化を正式決定**
> - **決定**: **A案 2層化** を正式に採用（Phase 4-M0の決定をPhase 5で再承認）。`Isolated Sandbox` を `Sandbox-Host (null origin)` と `WebContainers (crossOriginIsolated)` の2層に分離。
> - **不採用案**: **B案 縮退**（WebContainers廃止）は npm 互換を失い、M3の `vite`/`vitest` 実行が不可になるため不採用。
> - **影響**: 本決定により `05_sandbox.md` の G05 `⚠️` は解消済み（`> 🆕 決定` として反映）。Phase 5-1 で本ファイルに「Phase 5 更新版アーキテクチャ図」節を新設する（下記R1対応）。元の図は削除せず注記して残す。

> 🆕 **詳細化補足（Phase 5・レビュー反映）— R1 Phase 5 更新版アーキテクチャ図**
> - **指摘元**: REVIEW_DESIGN.md R1（G05と同一）
> - **内容**: Phase 4までの原案図（単一 `null origin` Sandboxに WebContainers を含む）は、WebContainersが `crossOriginIsolated` 必須のため両立しないことが判明した。Phase 5版を正とするため、以下の更新版図を新設する。原案図は削除せず「Phase 4までの原案（問題発覚のためPhase 5版を正とする）」と注記して残す。
>   ```text
>   ┌────────────────────────────────────────────────────────────────────────────────────────┐
>   │              Isolated Sandbox Layer（Phase 5 更新版 — 2層化）                        │
>   │                                                                                      │
>   │  ┌──────────────────────────────────────────────────────────────────────────────┐   │
>   │  │  Sandbox-Host (null origin)  iframe sandbox="allow-scripts"                  │   │
>   │  │   ※ allow-same-origin なし → null originでHost遮断                          │   │
>   │  │   - TypeScript Language Service (Wasm)  - Pyodide / QuickJS                 │   │
>   │  │   - Automated Test Runner (Vitest/Jest Wasm)  - ESLint / Prettier Wasm      │   │
>   │  │   - Structured Output Validator (Zod/AJV Wasm)                              │   │
>   │  └──────────────────────────────┬───────────────────────────────────────────────┘   │
>   │                                 │ postMessage リレー (Host経由)                    │
>   │                                 ▼                                                  │
>   │  ┌──────────────────────────────────────────────────────────────────────────────┐   │
>   │  │  WebContainers iframe (crossOriginIsolated)  allow="cross-origin-isolated"   │   │
>   │  │   ※ COOP: same-origin + COEP: require-corp を配信する別オリジンで配信        │   │
>   │  │   - Node.js / npm / Vite 互換  - WebContainers Runner                        │   │
>   │  └──────────────────────────────────────────────────────────────────────────────┘   │
>   └────────────────────────────────────────────────────────────────────────────────────────┘
>   ```
> - **根拠**: 公式 `webcontainers.io/troubleshooting` で `crossOriginIsolated` 必須が明記されているため。

---

> **出典**: `Local_AI_Agent.md` §2（Lines 25-88）を一字一句維持して分割
> **相互参照**: [01_overview.md](./01_overview.md) | [03_security-byok.md](./03_security-byok.md) | [04_storage-persist.md](./04_storage-persist.md) | [05_sandbox.md](./05_sandbox.md) | [06_model-selection.md](./06_model-selection.md) | [README.md](../README.md)
