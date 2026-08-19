<!-- 元ファイル: Local_AI_Agent.md §4 Lines 151-162 -->
# 05 ゼロトラスト実行環境（サンドボックス）

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local_AI_Agent.md)
> **インデックス**: [README.md](../README.md) | [Phase0設計書](../PHASE0_design.md)
> **関連ファイル**: [02_architecture.md](./02_architecture.md) | [03_security-byok.md](./03_security-byok.md) | [09_patch-engine.md](./09_patch-engine.md)（Wasm検証） | [README.md](../README.md)
> **元セクション**: §4（Lines 151-162）

> **要約**: 本ファイルは iframe sandbox="allow-scripts"（allow-same-originなし・null origin）による二重隔離レイヤーと、postMessage JSON-RPC 2.0（Origin検証 event.origin==='null'）通信プロトコルを定義する。

> **ナビゲーション**: ← [04_storage-persist.md](./04_storage-persist.md) | [06_model-selection.md](./06_model-selection.md) →

---

## 4. ゼロトラスト実行環境（サンドボックス）

Web Worker単体では `Same-Origin` のCookieやローカル通信にアクセスできてしまうため、二重の隔離レイヤー を採用する。

- ホスト側: IDE本体、IndexedDB、APIキー管理、UI。
- サンドボックス側: `<iframe sandbox="allow-scripts">`（`allow-same-origin` は付与しない）。
  - オリジンが強制的に `null` となり、親のDOM、LocalStorage、IndexedDB、Cookieへのアクセスがブラウザレベルで遮断される。
  - コードの構文解析、TypeScript型チェック、テスト実行（Pyodide / QuickJS / WebContainers）はすべてこの iframe 内で実行し、結果のみを `postMessage` 経由の JSON-RPC 2.0 でホストに返す。
- 通信プロトコル: `postMessage` は型安全なJSON-RPC 2.0でラップし、Origin検証（`event.origin === 'null'`）を必須とする。

---


> ⚠️ **要人間判断（Phase 4で未解決）— G03: ランタイム使い分け**
> **→ 決定済み: 下記 `🆕（Phase 5・決定反映）` を参照（本⚠️は履歴として残存）**
> - **論点**: Pyodide / QuickJS / WebContainers をどの言語/ユースケースで使い分けるか
> - **選択肢**:
>   - **A案（推奨叩き台）**: Pyodide → Python実行、QuickJS → 軽量JSスニペット（起動<50ms）、WebContainers → Node.js/npm互換（フルfs/network）
>   - **B案**: WebContainersに一本化し QuickJS を廃止（実装は単純だが起動コスト・メモリ増）
>   - **C案**: WebContainersを諦め Pyodide + QuickJS のみに縮退（軽量だが npm 互換を失う）
> - **影響**: バンドルサイズ（A: ~15MB, B: ~25MB, C: ~10MB）、起動時間、対応言語が変わる。Phase 4-2 の `14_shared-contracts.md` §5 に分岐を記載したため、**実装着手前にA/B/Cを人間が選択**すること。

> ⚠️ **要人間判断（Phase 4で未解決）— G05: WebContainersとnull originの矛盾**
> **→ 決定済み: 下記 `🆕（Phase 5・決定反映）` を参照（本⚠️は履歴として残存）**
> - **論点**: 仕様書は `iframe sandbox="allow-scripts"`（`allow-same-origin`なし → `null origin`）で隔離しつつ、同一iframe内で WebContainers を動かすとしているが、WebContainersは `SharedArrayBuffer` のため `crossOriginIsolated=true`（COOP: same-origin + COEP: require-corp）が必須で、null originとは両立しない（Web検索で確認済み、StackBlitz公式も `crossOriginIsolated` 必須と明記）。
> - **選択肢**:
>   - **A案（推奨）**: Sandboxを2層化 — 本体の `null origin` iframe（Wasm型チェック等）と、別オリジンの `crossOriginIsolated` iframe（`allow="cross-origin-isolated"` + `COOP/COEP` ヘッダを配信）で WebContainersを分離。両者は `postMessage` で連携。
>   - **B案**: WebContainersをスコープ外とし、Pyodide/QuickJSのみでリリース（将来、別オリジンで追加）
> - **影響**: Aはアーキテクチャ変更（`02_architecture.md` の図に第2 iframeを追加）が必要だがフル互換。Bは即時リリース可能だが Node 互換が欠落。
> - **根拠**: `webcontainers.io/guides/troubleshooting` および GitHub Issue #37 で `crossOriginIsolated` 必須が明記されているため、現仕様のままでは物理的に起動しない。
> 🆕 **決定（2026-08-18 レビュー反映）— G05 2層化を採用**
> - **決定**: A案（2層化）を採用する。Host側の `null origin` iframe（型チェック・lint・テスト等）と、別オリジンの `crossOriginIsolated` iframe（WebContainers専用）を分離し、`postMessage` でリレーする。
> - **理由**: StackBlitz公式が `crossOriginIsolated` 必須と明記しており、単一 `null origin` では WebContainersが物理的に起動しないため。B案（縮退）は npm 互換を失い将来の拡張を阻害する。
> - **影響**: `02_architecture.md` の図を2層化に更新済み（下記参照）。`14_shared-contracts.md` §5 の分離アーキテクチャを正とする。実装時は `05_sandbox.md` の `⚠️` は解消済みとして扱う。


> 🆕 **詳細化補足（Phase 4）— 横断契約への参照**
> - **対象**: `postMessage` JSON-RPC 2.0 スキーマ未定義（G04）
> - **種別**: 🔴Blocker解消（参照）
> - **内容**: 本ファイルの通信プロトコル詳細は [14_shared-contracts.md](./14_shared-contracts.md) §1 に集約した。`event.origin === 'null'` 検証に加え、`id`/`method`/`params` の型を参照すること。
> - **根拠**: 横断契約の単一ソース化のため。

> 🆕 **詳細化補足（Phase 5・決定反映）— G03 役割分担**
> - **決定**: **A案 分担** を採用する。Pyodide → Python実行、QuickJS → 軽量JSスニペット（起動<50ms）、WebContainers → Node.js/npm互換（フルfs/network）。G05の2層化決定と連動し、3者を適材適所で使い分ける。
> - **不採用案**:
>   - **B案 WebContainers一本化**: QuickJSを廃止し実装は単純だが、WebContainersの起動コスト（~2秒）とメモリ（~100MB）が軽量JSにもかかり、スマホでのUXが悪化するため不採用。
>   - **C案 縮退**: WebContainersなしは軽量だが npm 互換を失い、将来の `vite`/`vitest` 実行が不可になるため不採用。
> - **影響**: `14_shared-contracts.md` §1.4 の `method` 分担も本決定に準拠（`typeCheck`/`lint`はSandbox-Host、`runTests`のNode系はWebContainers側で実行）。

---

> **出典**: `Local_AI_Agent.md` §4（Lines 151-162）を一字一句維持して分割
> **相互参照**: [02_architecture.md](./02_architecture.md) | [03_security-byok.md](./03_security-byok.md) | [09_patch-engine.md](./09_patch-engine.md)（Wasm検証） | [README.md](../README.md)
