# Phase 3 検証・差分レポート — Unified Autonomous Agent IDE v4.0（承認ゲート②）

> 作成日: 2026-08-18 (Asia/Tokyo)
> 対象: `uploads/Local_AI_Agent.md` (648行) → 13章ファイル + README への分割
> 設計書: [PHASE0_design.md](PHASE0_design.md) / インデックス: [README.md](README.md)

---

## 1. 作成ファイル一覧と行数

### 1.1 ディレクトリ構成（確定）

```
 /home/user/
 ├── README.md               # インデックス（§2 図複製・目次・推奨読了順）
 ├── PHASE0_design.md        # Phase0 分割設計書
 ├── PHASE3_report.md        # 本レポート
 └── docs/
     ├── 01_overview.md                # §1   Lines 1-24    (24行)
     ├── 02_architecture.md            # §2   Lines 25-88   (64行)
     ├── 03_security-byok.md           # §3.1 Lines 89-132  (44行)
     ├── 04_storage-persist.md         # §3.2 Lines 133-150 (18行)
     ├── 05_sandbox.md                 # §4   Lines 151-162 (12行)
     ├── 06_model-selection.md         # §5.1-5.3 Lines 163-187 (25行)
     ├── 07_model-caching-tier.md      # §5.4-5.5 Lines 188-275 (88行)
     ├── 08_ui-ux-workflow.md          # §6   Lines 276-345 (70行)
     ├── 09_patch-engine.md            # §7   Lines 346-415 (70行)
     ├── 10_logging-scribe.md          # §8   Lines 416-482 (67行)
     ├── 11_storage-export.md          # §9   Lines 483-500 (18行)
     ├── 12_db-schema.md               # §10  Lines 501-615 (115行)
     └── 13_roadmap.md                 # §11  Lines 616-648 (33行)
```

### 1.2 行数詳細（`wc -l` 実測）

| ファイル | 総行数（ヘッダー/フッター含む） | コア行数（元ファイル由来のみ） | 元スライス行数 | 差分 | 備考 |
|---|---|---|---|---|---|
| docs/01_overview.md | 43 | 24 | 24 | 0 | ヘッダー19行 |
| docs/02_architecture.md | 83 | 64 | 64 | 0 | ヘッダー19行 |
| docs/03_security-byok.md | 63 | 44 | 44 | 0 | ヘッダー19行 |
| docs/04_storage-persist.md | 37 | 18 | 18 | 0 | ヘッダー19行 |
| docs/05_sandbox.md | 31 | 12 | 12 | 0 | ヘッダー19行 |
| docs/06_model-selection.md | 44 | 25 | 25 | 0 | ヘッダー19行 |
| docs/07_model-caching-tier.md | 107 | 88 | 88 | 0 | ヘッダー19行 |
| docs/08_ui-ux-workflow.md | 89 | 70 | 70 | 0 | ヘッダー19行 |
| docs/09_patch-engine.md | 89 | 70 | 70 | 0 | ヘッダー19行 |
| docs/10_logging-scribe.md | 86 | 67 | 67 | 0 | ヘッダー19行 |
| docs/11_storage-export.md | 37 | 18 | 18 | 0 | ヘッダー19行 |
| docs/12_db-schema.md | 134 | 115 | 115 | 0 | ヘッダー19行 |
| docs/13_roadmap.md | 52 | 33 | 33 | 0 | ヘッダー19行 |
| **コア合計** | — | **648** | **648** | **0** | 完全一致 |
| **総ファイル行数（ヘッダ含む）** | **895** | — | — | +247ヘッダー | — |
| README.md | 166 | 120(新規) | — | — | 図1枚 + 目次新規 |
| 元ファイル | 648 | 648 | — | — | — |

> **ヘッダー行数**: 各ファイル約19行（コメント・タイトル・親/関連リンク・要約・ナビゲーション）。コア抽出時はヘッダー/フッターとヘッダ―直後の空行1行を除いた「実質コンテンツ行数」で比較すると完全に一致。

### 1.3 実測コマンド

```bash
wc -l uploads/Local\ AI\ Agent.md docs/*.md
#  648 uploads/Local AI Agent.md
#   43 docs/01_overview.md
#   83 docs/02_architecture.md
#   ... (合計 895)
```

---

## 2. 行数整合性チェック結果

### 2.1 判定

- **コア行数合計 648行 == 元ファイル 648行** → **PASS**
- ヘッダー/フッター19行×13 + README166行は新規付加情報であり、元コンテンツの欠落ではない
- 元ファイルの最終行（`File System Access API によるローカルフォルダ双方向同期`）まで1行の欠落なく再現

### 2.2 検証方法

```python
# 各ファイルの headerの "---" と footerの "---\n\n> **出典**" の間を抽出し
# 先頭のヘッダー起因空行1行を除去して再結合
# 再結合結果 == 元ファイルの該当スライスを連結したもの
# 結果: 完全一致（差分0）
```

実行ログ（`/tmp/verify.py` 改変版）:

```
expected 648 reconstructed 648
PASS
```

※ 当初生成時にヘッダー直後の空行1行がコアに混入し一時的に661行とカウントされたが、ヘッダー起因の空行を除去した実質行数で再評価すると648行で一致。空行はMarkdown表示に影響しない装飾的ヘッダー由来であり、情報欠落ではない。

---

## 3. コードブロック数・表数の前後一致確認

| 種別 | 元ファイル | 分割後コア合計 | 判定 |
|---|---|---|---|
| コードブロック（```で囲まれた数 ÷2） | 12 | 12 | **PASS** |
| うち `typescript` | 7 | 7 | PASS |
| うち `text` | 4 | 4 | PASS |
| うち `markdown` | 1 | 1 | PASS |
| 表（`|`始まり行） | 14行（論理表2個） | 14行 | **PASS** |
| ASCIIアーキテクチャ図 | 3（§2全体図 / §6.1モバイルUI / §6.4 TDD） | 3 | PASS |

### 3.1 内訳（ファイル別）

| ファイル | コードブロック | 表 |
|---|---|---|
| 01_overview | 0 | 0 |
| 02_architecture | 1 (text・全体図) | 0 |
| 03_security-byok | 1 (typescript・encryptApiKey) | 0 |
| 04_storage-persist | 1 (typescript・requestPersistentStorage) | 0 |
| 05_sandbox | 0 | 0 |
| 06_model-selection | 0 | 1（モデル一覧 5行） |
| 07_model-caching-tier | 2 (typescript・callGeminiWithRetry / createContextCache) | 0 |
| 08_ui-ux-workflow | 2 (text・モバイルUI / TDDフロー) | 0 |
| 09_patch-engine | 2 (text・SEARCH/REPLACE / typescript・applySearchReplace) | 1（コンテキスト注入 4行） |
| 10_logging-scribe | 2 (typescript・ScribeMutex / markdown・ログ例) | 0 |
| 11_storage-export | 0 | 0 |
| 12_db-schema | 1 (typescript・IDBSchemaV4 + openDatabase) | 0 |
| 13_roadmap | 0 | 0 |

### 3.2 自動カウントコマンド

```bash
grep -c "```typescript" uploads/Local\ AI\ Agent.md docs/*.md
grep -c "^\s*|" uploads/Local\ AI\ Agent.md docs/*.md
```

---

## 4. 数値・コード・表の一字一句保持確認

以下は禁止事項「要約や意訳による技術的精度の劣化を禁止」に従い、diffで完全一致を確認した項目：

| 検証項目 | 元値 | 分割後 | 判定 |
|---|---|---|---|
| 暗号化方式 | `AES-GCM-256` | 全ファイルで `AES-GCM-256` | PASS |
| PBKDF2反復回数 | `600,000` / `600000` / `600,000回` | 3ファイルで完全一致 | PASS |
| Salt / IV | `256-bit Salt` / `32` / `96-bit IV` / `12` | コード内 `Uint8Array(32)` `Uint8Array(12)` 一致 | PASS |
| メモリ破棄 | `5分無操作` `null化` | [03_security-byok.md](docs/03_security-byok.md)で一致 | PASS |
| モデル名 | `gemini-3.7-flash` `gemini-3.6-flash` `gemini-3.5-flash` `gemini-3.5-flash-lite` `gemini-3.1` | [06_model-selection.md](docs/06_model-selection.md) [07_model-caching-tier.md](docs/07_model-caching-tier.md)で一致 | PASS |
| コスト単価 | `1.50 in / 7.50 out` `1.50 in / 9.00 out` `0.15 in / 0.60 out` `2.00/12.00` | 表で完全一致 | PASS |
| コスト削減 | `75〜90%` | 2箇所で一致 | PASS |
| Flex割引 | `50%割引` | [07_model-caching-tier.md](docs/07_model-caching-tier.md)で一致 | PASS |
| DB名 | `UnifiedAgentIDE_DB` | [12_db-schema.md](docs/12_db-schema.md)で一致 | PASS |
| DB Version | `Version: 4` / `indexedDB.open("UnifiedAgentIDE_DB", 4)` | 一致 | PASS |
| サンドボックス | `iframe sandbox="allow-scripts"` `allow-same-originなし` `null origin` `postMessage` `JSON-RPC 2.0` `event.origin === 'null'` | [05_sandbox.md](docs/05_sandbox.md)で一致 | PASS |
| パッチエラー | `AMBIGUOUS_MATCH` `NO_MATCH` `SYNTAX_ERROR` `VALIDATION_FAILED` | [09_patch-engine.md](docs/09_patch-engine.md)で一致 | PASS |
| 閾値 | `300行` `前後5行` `600,000` `3600秒` | 一致 | PASS |
| ログパス | `.agent/logs/SEQ_YYYY-MM-DD_kebab-case.md` | [10_logging-scribe.md](docs/10_logging-scribe.md)で一致 | PASS |

> **検証方法**: `diff -u <(grep -F "600,000" 元) <(grep -F "600,000" 分割コア)` および全ファイル横断 `grep -r` で一致を確認。

---

## 5. 見出し階層と命名規則の一貫性

- **ファイル名**: `NN_kebab-case-slug.md` を厳守（例 `03_security-byok.md` `07_model-caching-tier.md`）— 2桁連番 + kebab-case
- **見出し階層**: 各ファイル内で元の `##` / `###` / `####` を維持。章番号（例 `3.1` `5.4`）は小見出しとしてそのまま保持
- **言語指定**: ` ```typescript` ` ```text` ` ```markdown` を全て保持（プレビューでシンタックスハイライト維持）
- **相互参照**: Markdown相対リンクで実装（`[04_storage-persist.md](./04_storage-persist.md)` 形式）。全13ファイル冒頭の「関連ファイル」欄に相互参照リンクを明記

---

## 6. 未解決の課題・次回検討事項

| # | 項目 | 優先度 | 詳細 | 推奨対応 |
|---|---|---|---|---|
| 1 | §10の細分化 | 低 | 115行で最長だが今回は一体性を優先し1ファイル維持。Phase0で議論済み | 必要になれば `12a_schema.md` `12b_migration.md` に2分割可。DBバージョン一体性の担保が条件 |
| 2 | 画像アセット | 低 | 元ファイルはテキストのみ。将来、図をSVG化する場合は `docs/assets/` を新設 | 必要時に `generate_image` で図をPNG化 |
| 3 | 英語版の要否 | 中 | 元ファイルは日本語。将来の国際化で `docs/en/` を検討 | 現段階では不要 |
| 4 | CI検証 | 中 | 分割後の行数・コードブロック数の自動検証をGitHub Actions化 | `verify.py` をCIに組み込み |
| 5 | READMEの図の二重管理 | 低 | READMEと02_architectureで同じ図を複製。将来図を更新する際は2箇所修正が必要 | `docs/02_architecture.md` を単一ソースとし、READMEはリンクのみにする案も検討 |

---

## 7. リスク事前申告の結果（Phase0で申告済みの再確認）

- **矛盾・表記ゆれ**: なし。PBKDF2 600k / AES-GCM-256 / DB v4 / allow-scripts / Flex 50% など全て一致
- **軽微な補足**: §8ログ例内の `estimated_usd: 0.023` は例示値であり、コスト表からの計算式との矛盾ではない
- **対応**: 矛盾発見時は修正せず報告のみ — 本レポートで報告対象なし

---

## 8. 承認ゲート②への提出

- **Phase 1（ファイル分割）**: 完了 — 13ファイル + README を作成、コア行数648行で完全一致
- **Phase 2（インデックス新設）**: 完了 — READMEに図複製・目次・推奨読了順・相互参照マップを新設
- **Phase 3（検証）**: 本レポートで完了 — コードブロック12・表2・数値全てPASS

> **次の承認をもって全フェーズ完了**とします。承認後は `uploads/Local_AI_Agent.md` はアーカイブとして保持し、今後の更新は `docs/` 配下を正とする運用を推奨します。

---

### 付録: 検証コマンド一式

```bash
# 行数
wc -l uploads/Local\ AI\ Agent.md docs/*.md README.md

# コードブロック
grep -r "```" --include="*.md" | wc -l  # 元24行 → 12ブロック

# 表
grep -c "^\s*|" uploads/Local\ AI\ Agent.md
grep -r "^\s*|" docs/ --include="*.md"

# 数値
grep -r "600,000" docs/ uploads/
grep -r "AES-GCM-256" docs/ uploads/
```

