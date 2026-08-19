# AGENT.md — PalmIDE リポジトリ作業指針（AIエージェント向け）

> 本ファイルは、このリポジトリで作業する AI コーディングエージェントへの恒久的な指示書である。
> 詳細な行動ルール・スキル・フック・サブエージェント定義は `.agent/` 配下（`rules/` / `skills/` / `hooks/` / `agents/`）に配置する。

---

## 1. このリポジトリは何か

**PalmIDE = Unified Autonomous Agent IDE v4.0** の仕様書リポジトリ。最終目標は「スマホ/タブレット/PCのブラウザだけで動く、Claude Code 相当の自律 AI コーディング IDE」の実装である。

- **現状**: コード実装はまだない。**仕様書（Markdown）のみ**で構成される
- **バックエンド不要**: IndexedDB / iframe Sandbox / Wasm でクライアント完結する設計
- **モデル**: Google Gemini 3.x 系列に統一（`3.7 Flash` 主軸、`3.6/3.5 Flash` フォールバック、`3.5 Flash-Lite` Scribe用、`3.1 Pro` 難関用）

## 2. 最重要: 「どこが正の情報か」

| 用途 | 正の情報源 | 備考 |
|---|---|---|
| **実装・質問の参照（通常は常にこちら）** | `new/*.md`（14章 + README） | Phase 0〜5 の決定を本文に統合済みのクリーン版 |
| 履歴・判断経緯の確認 | `docs/*.md`（`> 🆕` / `> ⚠️` ブロック付き） | **原則編集しない** |
| 判断の根拠の原資料 | `PHASE5_report.md` / `REVIEW_DESIGN.md` / `PHASE4_0_gaplist.md` | 読み取り専用 |
| 元の単一仕様書（648行） | `uploads/Local AI Agent.md` | **変更禁止** |

> **ルール**: 仕様の追加・改訂は **`new/` の該当ファイルの本文のみ**に行い、`docs/` や `uploads/` には絶対に追記・修正しない。
> 横断的な型・定数の変更は **`new/14_shared-contracts.md` のみ**を更新し、各章からは参照リンクに留める。

## 3. 絶対に変えてはいけない不変値（検証対象）

- 暗号化: `AES-GCM-256` / `PBKDF2 600,000 iterations` / `SHA-256` / `256-bit Salt` / `96-bit IV` / `メモリ上の鍵は5分無操作で破棄`
- DB: `UnifiedAgentIDE_DB` v4（v5移行計画あり）/ 5ストア（`files` / `snapshots` / `security` / `contextCaches` / `preferences`）
- Sandbox: `iframe sandbox="allow-scripts"`（`allow-same-origin` なし → `null origin`）/ WebContainers 用は別オリジン `crossOriginIsolated` iframe / `postMessage JSON-RPC 2.0` / `event.origin === "null"` 検証必須
- コスト: 単価は `new/14_shared-contracts.md` §4 `RATE_TABLE` を唯一の正とする。ハードコード禁止
- パッチ: エラー種別 `NO_MATCH` / `AMBIGUOUS_MATCH` / `SYNTAX_ERROR` / `VALIDATION_FAILED`、前後5行ルール、300行閾値
- TDD: `Contract → Test → Impl → Approval` 4フェーズ、`maxReviseRetries` デフォルト 3

## 4. Phase 5 までの確定決定（再議論しない）

1. **G05/R1**: Sandbox は2層構成（Sandbox-Host null origin + WebContainers crossOriginIsolated、postMessage リレー経由）
2. **G03**: ランタイム3者分担（Pyodide=Python / QuickJS=軽量JS<50ms / WebContainers=Node・npm）
3. **G10**: 複数タブ排他は `navigator.locks.request("scribe-wal", {mode:"exclusive"})`（非対応時は BroadcastChannel フォールバック検討）
4. **G16**: GitHub PAT 保管はユーザ選択トグル（デフォルト=暗号化保存、`security` ストア `key: "github_pat"`）
5. **R2/R3**: JSON-RPCメソッド確定（`typeCheck`/`runTests`/`validateOutput`/`extractSkeleton`/`applyPatch`/`lint`）、skeleton は Tree-sitter JSON
6. **R5**: cached課金 = cache hit 別単価（約10%）+ storage 時間課金（公式料金表構造）
7. **R4**: Fuzzy Patch は `StrictFuzzyPatch`（オフセットマッピング保持）を14 §2.1 で正とする

## 5. レビュー持ち越し判断（`MERGE_DIFF_REPORT.md` RP-1〜RP-3）

- **RP-1**: 旧コスト式（`flexFactor * cached`）を削除 → 公式構造のみ
- **RP-2**: Interactions API の `store:false` は「ユーザー設定で切替可能（デフォルト: Google標準の保存 ON）」
- **RP-3**: ⚠️ 履歴ブロックは統合版から削除（履歴は `docs/` / `PHASE4_0_gaplist.md` に残存）

## 6. 実装ロードマップ（`new/13_roadmap.md` §11.1 DoD 準拠）

| M | 内容 | 目安 | 状態 |
|---|---|---|---|
| M1 | PWA + BYOK暗号化 + persist + Interactions API 疎通 | 2週間 | Ready（未着手） |
| M2 | 仮想FS + Fuzzyパッチ + 承認ゲート UI + コスト見積 | 2週間 | Ready（未着手） |
| M3 | 2層 Sandbox + Wasm TS Service + Zod バリデータ + AST Skeleton | 3週間 | 決定済み（2層化） |
| M4 | TDD ステートマシン + Context Caching + Tier Fallback | 3週間 | Ready（未着手） |
| M5 | Scribe Agent + 巻き戻し + GitHub/Zip/File System 連携 | 2週間 | 決定済み（G10/G16） |

## 7. `.agent/` ディレクトリ構成（拡張用）

```
.agent/
├── rules/    # 常時適用の行動ルール（言語・規約・禁止事項）
├── skills/   # 再利用可能な手順・知識パック（技能定義）
├── hooks/    # PreToolUse / PostToolUse 等のイベントフックスクリプト
└── agents/   # サブエージェント定義（役割分担プロンプト）
```

## 8. 作業ルール（要約）

- **言語**: ドキュメント・コミットメッセージ・PR は日本語を基本（コード内コメントは英語可）
- **変更対象**: 仕様は `new/` のみ。`docs/`・`uploads/`・`PHASE*.md`・`REVIEW_DESIGN.md` は変更しない
- **変更時の検証**: 数値・識別子の保持を `grep` で確認（例: `grep -r "PBKDF2" new/`）
- **リンク**: `new/` 内は `./NN_*.md` 形式、親は `../uploads/Local%20AI%20Agent.md`
- **不明点・仕様に矛盾が見つかった場合**: 推測で埋めず、`PHASE4_0_gaplist.md` の形式（論点-選択肢-影響）で人間に問い合わせる
- **コード実装を開始する場合**: `new/13_roadmap.md` の Milestone 1 から。DoD を満たすまで次へ進まない

---

> 最終更新: 2026-08-20 / この AGENT.md 自体の変更が必要な場合は、本ファイルのみを更新すること。
