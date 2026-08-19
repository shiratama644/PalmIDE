# Phase 4-0 ギャップ一覧（承認ゲート①）— 詳細化・リファクタリング

> 対象: `docs/*.md` 13ファイル（648行を13分割、README含め14ファイル構成）+ `README.md`
> 前提: Phase 0〜3で「一字一句維持」の分割は完了（[PHASE3_report.md](PHASE3_report.md)で完全一致検証済み）。本フェーズでは「分割では直せなかった元仕様の曖昧さ・未定義参照・技術的矛盾」を洗い出す。
> 作成日: 2026-08-18 (Asia/Tokyo) / ステータス: **要承認** — 本一覧を承認後に Phase 4-1 加筆へ進行

---

## 1. スキャン方法

- 全13ファイルを再走査（`grep` 横断検索 + 手動レビュー+ Web裏取り）
- コードブロック12個・表2個・ASCII図3個を全て展開し、呼び出し元と定義元の対応をチェック
- 固有名詞（Interactions API / WebContainers / Pyodide等）は Web検索で実在性を確認（2026-08-18 時点）

### 固有名詞裏取り結果（Phase 4-0 時点）

| 固有名詞 | 検証結果 | 根拠 |
|---|---|---|
| **Interactions API** | ✅ 実在・GA済み（2026-06-22） | Google公式ブログ・AI Studio docsでGA宣言。エンドポイント `POST /v1beta/interactions`、SDK `google/genai` の `client.interactions.create()` が正式。`generateContent` はレガシーとして併用可能。 → 仕様書の「Interactions APIが最新標準」は**正しい**が、SDKの呼び出し形状は要補足（下記G06参照） |
| **WebContainers** | ✅ 実在だが **制約あり** | StackBlitz WebContainers は `SharedArrayBuffer` 利用のため `crossOriginIsolated=true`（COOP: same-origin + COEP: require-corp）が必須。`iframe sandbox="allow-scripts"`（`allow-same-origin`なし → `null origin`）とは**技術的に両立しない**。公式トラブルシュートでも `crossOriginIsolated` 必須と明記。 → G05の懸念は**実在のコンフリクト** |

---

## 2. 重大度定義（Phase 4 仕様書 §4 準拠）

| 重大度 | 定義 | 対応方針 |
|---|---|---|
| 🔴 Blocker | 未定義関数/変数参照・型不一致など、実装が物理的に詰まる欠落 | Add（実装を埋める）または Flag（人間判断を促す）のいずれかで必ず対応 |
| 🟡 要確認 | 複数解釈が可能で、選んだ解釈で挙動が変わる曖昧さ。断定すると誤実装を誘発 | Flag（選択肢提示）原則。Addする場合は選択肢と根拠を明示 |
| 🟢 補足推奨 | あった方が親切だが実装を妨げない補足 | Add / Skip を判断。Skip時は理由を明記 |

---

## 3. ギャップ一覧（再走査確定版：たたき台13件 + 新規検出5件 = 18件）

> **凡例**: `Gxx` は本レポートでの通番。`元#` はプロンプトのたたき台番号。`状態` は今回の再走査で確定した重大度（変更があれば注記）。

| G | 元# | ファイル | 重大度 | ギャップ内容（要約） | 詳細 |
|---|---|---|---|---|---|
| G01 | 1 | [09_patch-engine.md](docs/09_patch-engine.md) | 🔴 Blocker | `normalizeWhitespace` / `applyFuzzyPatch` が呼び出されるが定義なし | `applySearchReplace` 内で2関数を呼ぶが実装がどこにもない。実装が詰まる。 |
| G02 | 2 | [03_security-byok.md](docs/03_security-byok.md) | 🔴 Blocker | `encryptApiKey` 対の `decryptApiKey` 未定義、誤パスワード時エラー未定義 | 復号フロー・UI表示・リトライが書かれていない。5分破棄後の再入力導線も不明。 |
| G03 | 3 | [05_sandbox.md](docs/05_sandbox.md) | 🟡 要確認 | Pyodide / QuickJS / WebContainers の使い分け基準未定義 | 図では3者が並列だが、どれがPython/JS/Node互換のどれを担うか、選択条件が不明。 |
| G04 | 4 | 横断 05・07・09 | 🔴 Blocker | `postMessage` JSON-RPC 2.0 のメソッド名・パラメータ・レスポンス型がどこにも定義なし | `postMessage` と書かれているだけで、`method: "typeCheck"` なのか `requestId` の有無すら不明。全Wasm連携が詰まる。 |
| G05 | 5 | [05_sandbox.md](docs/05_sandbox.md) | 🔴 Blocker（昇格） | WebContainersはCOOP/COEP分離必須で `null origin` の `sandbox` iframe内で動作不可能な矛盾 | Web検索で確認：`crossOriginIsolated=true` が必須。`allow-same-origin`なしのnull originでは `SharedArrayBuffer` が使えず WebContainersは起動しない。設計の前提崩壊。 |
| G06 | 6 | [06_model-selection.md](docs/06_model-selection.md) | 🟢 補足推奨（降格） | Interactions APIは実在するがSDKの呼び出し形状が仕様書と公式で乖離 | 仕様書: `genAI.models.generateContent({model, contents})` / 公式: `client.interactions.create({model, input})`。どちらを使うのか、移行方針の具体コードがない。 |
| G07 | 7 | 横断 06・07 | 🟢 補足推奨 | Gemini 3.7 Flash 紹介価格終了後（2026/12/31以降）の単価未記載 | コスト推計が2027年以降で崩れる。 |
| G08 | 8 | [08_ui-ux-workflow.md](docs/08_ui-ux-workflow.md) | 🔴 Blocker | Contract→Test→Implの各Phase間で受け渡すデータの型契約未定義 | TDDステートマシンの入力/出力の型（例: `ContractOutput` が `Test` に渡る形）がなく、実装が推測になる。 |
| G09 | 9 | [08_ui-ux-workflow.md](docs/08_ui-ux-workflow.md) | 🟡 要確認 | Revise（修正指示）ループの最大リトライ回数未定義 | 無限ループリスク。 |
| G10 | 10 | [10_logging-scribe.md](docs/10_logging-scribe.md) | 🟡 要確認 | `ScribeMutex` は単一タブのメモリ内排他のみ、複数タブのIndexedDB競合は防げない | `BroadcastChannel` や `IndexedDB` ロックの要否が不明。 |
| G11 | 11 | [12_db-schema.md](docs/12_db-schema.md) | 🟢 補足推奨 | `oldVersion > 4`（ダウングレード）時の処理未定義 | 将来v5→v4に戻すケース。 |
| G12 | 12 | [12_db-schema.md](docs/12_db-schema.md) | 🟡 要確認 | `checksum`（SHA-256）の計算・照合タイミング未定義 | いつ計算し、いつ検証し、不一致時どうするか不明。 |
| G13 | 13 | [13_roadmap.md](docs/13_roadmap.md) | 🟢 補足推奨 | 各Milestoneの完了条件（DoD）未定義 | 「できた」と判定する基準がない。 |
| **G14** | **新規** | [07_model-caching-tier.md](docs/07_model-caching-tier.md) | 🔴 Blocker | `genAI` / `cacheName` 変数が未定義 | `callGeminiWithRetry` 内で `genAI.models.generateContent` と `cachedContent: cacheName` を参照するが、初期化コードがどこにもない。`@google/genai` のimportと`cacheName`の取得元が不明で実行時 ReferenceError。 |
| **G15** | **新規** | 横断 07・08・10 | 🟡 要確認 | コスト推計（tokens→USD換算）の計算式未定義 | §5表の単価はあるが、入力/出力/キャッシュの合算式・端数処理・表示タイミング（Approval Gateで見積もるのかログで確定するのか）が不明。 |
| **G16** | **新規** | [11_storage-export.md](docs/11_storage-export.md) | 🟡 要確認 | GitHub PATの保管方法が未定義（Geminiキー同様に暗号化するのか） | §3では `security` ストアに暗号化と書かれているが、PATが同ストア対象か、平文か、スコープは、期限切れ時の扱いは不明。 |
| **G17** | **新規** | [12_db-schema.md](docs/12_db-schema.md) 横断 | 🟢 補足推奨 | `preferences` の `defaultModel` / `defaultTier` の取りうる値の列挙未定義 | どの文字列が有効か（例: `gemini-3.7-flash` のみか `3.5-flash-lite` も可か）、不正値時のフォールバックが不明。 |
| **G18** | **新規** | [04_storage-persist.md](docs/04_storage-persist.md) | 🟢 補足推奨 | `navigator.storage.persist()` が `false` を返した時のフォールバック未定義 | 永続化拒否時の警告UI・再試行導線がない。 |

> **補足**: 上記18件以外にも軽微な曖昧さ（例: Monaco Editorの統合方法）は多数あるが、実装を物理的に妨げないため今回のスコープ外とし、必要に応じて Phase 4-1 で `Skip` として理由を記録する。

---

## 4. 対応方針の仕分け（Add / Flag / Skip）

> **Add** = 本フェーズで `> 🆕 詳細化補足` として加筆する（原文は上書きしない）<br>
> **Flag** = `> ⚠️ 要人間判断` として選択肢を提示し、加筆はしない（人間の決定待ち）<br>
> **Skip** = 対応不要と判断（理由を明記）

| G | 重大度 | 仕分け | 理由と対応概要 | 新規ファイル要否 |
|---|---|---|---|---|
| G01 | 🔴 | **Add** | 欠落関数を補完しないとビルドすら通らない。`normalizeWhitespace`（空白・改行正規化）と `applyFuzzyPatch`（元インデントを保持した差分適用）の**叩き台実装**を `09_patch-engine.md` 末尾に補足として提示。推測だが根拠（テスト容易性・インデント保持）を明記。 | 不要 |
| G02 | 🔴 | **Add** | `decryptApiKey` は `encryptApiKey` の対で自明。復号失敗時（誤パスワード・データ破損）の `OperationError` ハンドリングとUI文言案を `03_security-byok.md` に補足。 | 不要 |
| G03 | 🟡 | **Flag** | 使い分けはプロダクト方針に依存（例: PyodideをPython、QuickJSを軽量JS、WebContainersをNode互換とする案 vs QuickJSを廃止しWebContainersに一本化する案）。断定せず **選択肢A/B** を `05_sandbox.md` に明示のみ。 | 不要 |
| G04 | 🔴 | **Add（要新規ファイル）** | 横断的な契約。`docs/14_shared-contracts.md` を**新設**し、JSON-RPC 2.0の `request`/`response`/`error` 型（`jsonrpc: "2.0"`, `id`, `method`, `params`）と想定メソッド（`typeCheck`/`runTests`/`validateOutput`/`applyPatch` 等）の**叩き台スキーマ**を定義。既存の「postMessage」記述は一切書き換えず、新ファイルへリンクする補足のみを 05・07・09 に追記。 | **要 `14_shared-contracts.md`** |
| G05 | 🔴 | **Flag** | 技術的矛盾。`null origin` + `WebContainers` は両立しない。選択肢 **A: WebContainersを別オリジンの `crossOriginIsolated` iframeに分離する** vs **B: WebContainersを諦め Pyodide/QuickJSのみとする** を `05_sandbox.md` に明示。**実装前に人間がアーキテクチャを選び直す必要あり**。 | G04の新ファイルにも影響を注記 |
| G06 | 🟢 | **Add** | Interactions APIは実在確認済み。乖離しているSDK呼び出し形状を補足で是正：公式の `client.interactions.create` とレガシー `generateContent` の**併用方針**と `genAI` 初期化の叩き台を `06_model-selection.md` に補足。断定ではなく公式へのリンクと移行ガイドへの参照を併記。 | G04新ファイルと連携（genAI初期化は共有） |
| G07 | 🟢 | **Skip** | 将来の価格。2026-08-18 時点で未公表の単価を推測で書くと誤情報になる。`07_model-caching-tier.md` に「**2026/12/31以降は公式料金表を参照し、コスト推計ロジックは定数化せず設定可能にすること**」という注意喚起のみを **Add**（軽量補足）とするか、Skipか — 本仕分けでは **Add（軽量）** とする。 | 不要 |
| G08 | 🔴 | **Add（要新規ファイル）** | TDDの型契約。G04の `14_shared-contracts.md` に `ContractPhaseOutput` / `TestPhaseOutput` / `ImplPhaseOutput` / `ApprovalGatePayload` の**叩き台TypeScript型**を定義。`08_ui-ux-workflow.md` には型ファイルへのリンク補足のみ。 | **要 `14_shared-contracts.md`** |
| G09 | 🟡 | **Add（Flag併記）** | 推奨リトライ上限を **3回** とする叩き台を `08_ui-ux-workflow.md` に補足しつつ、「無限ループ防止のため上限はプロダクト設定 `preferences.autoPilotThreshold` とは別に `preferences.maxReviseRetries` として持つ」という設計選択肢も併記。軽微なため Add で解消可能。 | 不要 |
| G10 | 🟡 | **Flag** | 単一タブか複数タブかはプロダクト要件次第。`BroadcastChannel` + `IndexedDB` 楽観ロック等の選択肢があるが、オーバースペックかも。`10_logging-scribe.md` に **選択肢A: 単一タブ運用を制約として明記** vs **B: `navigator.locks` API で跨タブ排他** をFlag。 | 不要 |
| G11 | 🟢 | **Skip** | ダウングレードは稀。`12_db-schema.md` に「未対応なら `onupgradeneeded` で `oldVersion > 4` のときは `console.warn` + マイグレーションスキップ」という**Add（軽量）**でも良いが、今回は **Skip**（理由: ブラウザが自動でDBを削除する挙動に委ね、将来必要になれば対応）とする。 | 不要 |
| G12 | 🟡 | **Add** | `checksum` は `files` 書き込み時（パッチ適用直後）に `SHA-256` で計算、読み出し時（Preview/Export前）に検証、不一致なら警告UIを出す、という**叩き台ライフサイクル**を `12_db-schema.md` に補足。 | 不要 |
| G13 | 🟢 | **Add** | 各MilestoneのDoDテンプレート（例: Milestone1なら「PWAインストール可能」「暗号化 round-trip 成功」「persist()成功」）の**叩き台**を `13_roadmap.md` に補足。 | 不要 |
| G14 | 🔴 | **Add（要新規ファイル）** | `genAI` 初期化と `cacheName` 取得の欠落。`06_model-selection.md` に `import { GoogleGenAI } from "@google/genai"` の初期化と、G04新ファイルに `ContextCacheManager` のインターフェースを定義し、G07の `cacheName` は `createContextCache` の戻り値であると明示する補足を Add。 | **要 `14_shared-contracts.md`** |
| G15 | 🟡 | **Add** | コスト式 `estimated_usd = (input_tokens*inRate + output_tokens*outRate + cached_tokens*cachedRate)/1e6` の叩き台と、端数は小数4桁、Approval Gateでは見積、Logでは確定値を記録、というライフサイクルを `07_model-caching-tier.md` と `10_logging-scribe.md` に補足。 | G04新ファイルにレート定数の型を定義 |
| G16 | 🟡 | **Flag** | PATの暗号化はセキュリティ要件に直結。**A: Geminiキー同様に `security` ストアで暗号化** vs **B: GitHub側で期限短いFine-grained PATを前提に平文+セッション限定** の選択を `11_storage-export.md` にFlag。 | 不要 |
| G17 | 🟢 | **Add** | `defaultModel` は `GEMINI_TIER_ORDER` の4値のみ、`defaultTier` は `flex|priority` のみ、というバリデーション補足を `12_db-schema.md` にAdd。 | 不要 |
| G18 | 🟢 | **Add** | `persist()===false` 時のトースト警告「永続化が拒否されました。ブラウザ設定で…」と再試行ボタンのUI案を `04_storage-persist.md` にAdd（軽量）。 | 不要 |

**集計**: Add 11件（うち新規ファイル要3件: G04/G08/G14が同一ファイルに集約） / Flag 4件（G03/G05/G10/G16） / Skip 1件（G11） / 軽量AddだがSkip相当だったものをAddに含む（G07/G18）

---

## 5. 新規ファイル提案（Phase 4-2 横断整合性）

### 提案: `docs/14_shared-contracts.md` を新設

- **目的**: G04（JSON-RPC）、G08（TDD型契約）、G14（genAI/cache）、G15（コストレート）など横断的で「どこにも属さない契約」を一箇所に集約し、重複・矛盾を防ぐ。
- **配置**: `docs/14_shared-contracts.md`（NN=14で読む順序は最後だが、READMEからは「共通契約」として先頭近くにリンク）。`00_` ではなく `14_` とする理由は、既存13ファイルの番号を崩さず、連番規則を維持するため。
- **内容（叩き台）**:
  1. `postMessage` JSON-RPC 2.0 リクエスト/レスポンス型
  2. TDD各Phaseの入出力型（Contract/Test/Impl/Approval）
  3. `GoogleGenAI` クライアント初期化と `ContextCache` 型
  4. コストレート定数型
  5. WebContainers分離案（G05の選択肢への参照）
- **既存ファイルへの影響**: 05・06・07・08・09・10 に「詳細は `14_shared-contracts.md` を参照」の補足リンクを1行ずつ追加するのみ（原文は書き換えない）。
- **代替案**: もし `00_` が好みであれば `docs/00_shared-contracts.md` でも可。連番規則は崩れるが「最初に読む共通契約」として分かりやすい。どちらでも実装上の差はないため、**承認時に選択**を求める。

**判断が必要**: 新規ファイルを作るか（推奨: 作る）、作らないで各ファイルに分散して補足するか。

---

## 6. 加筆時の書式（Phase 4-1 で厳守）

- 引用ブロック `> 🆕 詳細化補足（Phase 4）` で原文と視覚的に分離
- 内部フォーマット:
  ```markdown
  > 🆕 **詳細化補足（Phase 4）**
  > - **対象**: ...
  > - **種別**: 🔴Blocker解消 / 🟡要確認の解消 / 🟢補足
  > - **内容**: ...
  > - **根拠**: ...
  ```
- 要人間判断は:
  ```markdown
  > ⚠️ **要人間判断（Phase 4で未解決）**
  > - **論点**: ...
  > - **選択肢**: A案 / B案 ...
  > - **影響**: ...
  ```

---

## 7. 次のステップと承認依頼

1. 本一覧の **過不足**（見落としギャップはないか）
2. 各ギャップの **仕分け（Add/Flag/Skip）** の妥当性
3. **新規ファイル `14_shared-contracts.md` の要否と命名（14 vs 00）**

上記3点をご確認のうえ、承認をいただき次第 Phase 4-1（加筆実行）へ進む。

> **重要**: 本一覧の時点では **一切の加筆をまだ行っていない**（原文は無傷）。承認後にのみ、承認された Add/Flag 項目について末尾（出典コメント直前）へ引用ブロックで追記し、READMEの相互参照マップも更新する。

