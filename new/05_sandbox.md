<!-- 統合版: docs/05_sandbox.md の Phase 4〜5 追記（G03 ランタイム分担 / G05 2層化）を本文にマージ（元: Local_AI_Agent.md §4 Lines 151-162） -->
# 05 ゼロトラスト実行環境（サンドボックス）

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local%20AI%20Agent.md)（§4 Lines 151-162）
> **インデックス**: [README.md](./README.md)
> **関連ファイル**: [02_architecture.md](./02_architecture.md) | [03_security-byok.md](./03_security-byok.md) | [09_patch-engine.md](./09_patch-engine.md)（Wasm検証） | [14_shared-contracts.md](./14_shared-contracts.md)（§1 JSON-RPC / §5 分離アーキテクチャ）

> **要約**: 本ファイルは iframe sandbox="allow-scripts"（allow-same-originなし・null origin）による二重隔離レイヤーと、postMessage JSON-RPC 2.0（Origin検証 `event.origin === 'null'`）通信プロトコルを定義する。サンドボックスは **2層構成（Sandbox-Host + WebContainers iframe）** とし、ランタイムは **Pyodide / QuickJS / WebContainers の3者分担** を採用する。

> **ナビゲーション**: ← [04_storage-persist.md](./04_storage-persist.md) | [06_model-selection.md](./06_model-selection.md) →

---

## 4. ゼロトラスト実行環境（サンドボックス）

Web Worker単体では `Same-Origin` のCookieやローカル通信にアクセスできてしまうため、二重の隔離レイヤー を採用する。

- ホスト側: IDE本体、IndexedDB、APIキー管理、UI。
- サンドボックス側: `<iframe sandbox="allow-scripts">`（`allow-same-origin` は付与しない）。
  - オリジンが強制的に `null` となり、親のDOM、LocalStorage、IndexedDB、Cookieへのアクセスがブラウザレベルで遮断される。
  - コードの構文解析、TypeScript型チェック、テスト実行はサンドボックス側で実行し、結果のみを `postMessage` 経由の JSON-RPC 2.0 でホストに返す。
- 通信プロトコル: `postMessage` は型安全なJSON-RPC 2.0でラップし、Origin検証（`event.origin === 'null'`）を必須とする。リクエスト/レスポンスの型（`id`/`method`/`params`）と想定メソッド一覧は [14_shared-contracts.md](./14_shared-contracts.md) §1 を参照。

### 4.1 サンドボックスの2層構成

サンドボックスは以下の2層構成とする（詳細図は [02_architecture.md](./02_architecture.md) §2.1 と同一）。

- **Sandbox-Host（null origin）**: `iframe sandbox="allow-scripts"` のみ。Wasm型チェック・lint・テスト等を実行する高隔離レイヤー。
- **WebContainers iframe（crossOriginIsolated）**: `allow="cross-origin-isolated"` を付与し、`COOP: same-origin` + `COEP: require-corp` ヘッダを配信する**別オリジン**で提供する Node.js / npm / Vite 互換ランタイム。
- **連携**: 両層の通信は Host を経由した `postMessage` リレーとする。通信契約は [14_shared-contracts.md](./14_shared-contracts.md) §5 を正とする。

**採用理由**: WebContainers は `SharedArrayBuffer` のため `crossOriginIsolated=true` が必須であり（StackBlitz公式が明記）、単一の `null origin` iframe では物理的に起動しない。2層化で `null origin` によるXSS耐性を維持したまま Node 互換を確保できる。npm 互換を失う縮退案（WebContainers廃止）は、将来の `vite`/`vitest` 実行を不可にするため不採用。

### 4.2 ランタイムの役割分担

3つのランタイムは以下の通り適材適所で使い分ける。

| ランタイム | 役割 | 配置 |
|---|---|---|
| **Pyodide** | Python 実行 | Sandbox-Host（null origin） |
| **QuickJS** | 軽量 JS スニペット実行（起動 `<50ms`） | Sandbox-Host（null origin） |
| **WebContainers** | Node.js / npm 互換（フル fs / network） | 別オリジンの crossOriginIsolated iframe |

- `14_shared-contracts.md` §1.4 のメソッド分担もこれに準拠する（`typeCheck` / `lint` は Sandbox-Host 側、`runTests` の Node 系は WebContainers 側で実行）。
- 起動コスト（約2秒）とメモリ（約100MB）が軽量JS処理にまでかかるため、WebContainers 一本化はモバイルUXの観点から不採用。

---

> **出典**: `Local_AI_Agent.md` §4（Lines 151-162）。2層化決定（G05）とランタイム分担決定（G03）を本文に統合した統合版である。
> **相互参照**: [02_architecture.md](./02_architecture.md) | [03_security-byok.md](./03_security-byok.md) | [09_patch-engine.md](./09_patch-engine.md)（Wasm検証） | [14_shared-contracts.md](./14_shared-contracts.md) | [README.md](./README.md)
