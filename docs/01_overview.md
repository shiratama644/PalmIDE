<!-- 元ファイル: Local_AI_Agent.md §1 Lines 1-24 -->
# 01 プロダクト概要とコア設計原則

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local_AI_Agent.md)
> **インデックス**: [README.md](../README.md) | [Phase0設計書](../PHASE0_design.md)
> **関連ファイル**: [02_architecture.md](./02_architecture.md) | [03_security-byok.md](./03_security-byok.md) | [README.md](../README.md)
> **元セクション**: §1（Lines 1-24）

> **要約**: 本ファイルはプロダクト概要（§1.1）と8つのコア設計原則（§1.2: Zero-Install / Local-Only / Encrypted BYOK / Zero-Trust / Gemini 3.x最適化 / Deterministic Verification / Mobile-First HITL / Cost-Optimized）を定義する。§2のアーキテクチャ図で全体像を確認することを推奨。

> **ナビゲーション**:   [02_architecture.md](./02_architecture.md) →

---

# 🧬 Unified Autonomous Agent IDE 実装仕様書 (統合版 v4.0)
〜 Web-Native × Client-First 統合・スマホ/タブレット/PC 対応型 完全ローカル完結アーキテクチャ 〜

---

## 1. プロダクト概要とコア設計原則

### 1.1 プロダクト概要
本プロダクトは、PC専用のCLIツール（Claude Code等）やデスクトップIDE（Cursor等）がインストールできないスマートフォン（iOS / Android）、タブレット（iPad）、Chromebook、およびPCのWebブラウザ上から、Claude Codeと同等以上の自律Web開発を行えるWebネイティブAIエージェントIDEである。

バックエンドサーバーを完全に排除し、ブラウザ上（IndexedDB / 隔離Sandbox / Wasm）で完結する。モデルファミリーを Google Gemini 3.x シリーズに統一 することで、ツール定義・推論の癖・コンテキスト長の一貫性を保ち、破綻のない自律開発を実現する。

### 1.2 コアバリュー＆設計原則
1. Zero-Install & Any-Device（どこでもClaude Code）: URLを開くだけで1秒で起動。PWAとしてスマホのホーム画面に追加し、移動中やベッドの上からでも片手で本格的な自律Web開発が可能。
2. Local-Only File Storage（完全ローカルファイル保持）: プロジェクトのソースコードや成果物はすべて端末内のIndexedDBにのみ保存。クラウド上にはAIとの推論通信しか飛ばず、第三者サーバーにファイルが保存されることは一切ない。
3. Encrypted BYOK Security（軍事級の鍵保護）: Google APIキーは端末内で `AES-GCM-256` 暗号化され、IndexedDBに完全ローカル保管。開発者サーバーが存在しないため、中間搾取・情報漏洩の心配がない。
4. Zero-Trust Client Security: APIキーの暗号化保存に加え、`iframe null-origin` によるコード実行の完全隔離を実現。
5. Google Gemini 3.x 最適化: 異種モデルの混在による挙動破綻を排除し、最新の Gemini 3.7 Flash 等を主軸とした高速・低コスト・高精度な自律開発ループを実現。
6. Deterministic Verification & Safety Gate: コンパイラ検証（Wasm）とユーザー承認ゲート（Human-in-the-Loop）による確実なコード変更。
7. Mobile-First Human-in-the-Loop: スマホの狭い画面でも直感的にコード変更を確認・承認できるモバイル特化型Diffビューアと承認ゲート。
8. Cost-Optimized Orchestration: Context Caching と Flex/Priority Tier による徹底的なコスト最適化。

---


> 🆕 **詳細化補足（Phase 5・レビュー反映）— R8 横断契約への参照**
> - **指摘元**: REVIEW_DESIGN.md R8
> - **内容**: 初学者が `14_shared-contracts.md` を読み飛ばさないよう、本ファイル末尾に「横断的な型契約は `14_shared-contracts.md` を参照」の導線を追記した。実装時は `01` → `02` → `14` の順で読むことを推奨。

---

> **出典**: `Local_AI_Agent.md` §1（Lines 1-24）を一字一句維持して分割
> **相互参照**: [02_architecture.md](./02_architecture.md) | [03_security-byok.md](./03_security-byok.md) | [README.md](../README.md)
