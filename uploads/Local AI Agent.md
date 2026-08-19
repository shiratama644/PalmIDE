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

## 3. セキュリティ ＆ ローカルストレージ仕様

### 3.1 暗号化BYOK（APIキーの完全ローカル保護）
サーバーを持たないため、ユーザーのAPIキーが開発者サーバーを経由することは原理的にありません。端末内でのXSS攻撃や悪意あるスクリプトからキーを守るため、Web Crypto API による軍事水準の暗号化 を行います。

- 暗号化方式: `AES-GCM-256`
- 鍵導出: ユーザーが設定したマスターパスワードから `PBKDF2` (600,000 iterations, SHA-256, 256-bit Salt) で導出。
- 保存先: IndexedDB の `security` ストアに暗号文（Ciphertext）、Salt、IVのみを保管（平文は保存しない）。
- セッション破棄: メモリ上に復号されたキーは、5分間の無操作で参照を null 化 して自動消去。

#### 暗号化モード選択
1. 暗号化保存モード（推奨）:
   - ユーザーに「マスターパスワード」を設定させ、`PBKDF2` で暗号化キーを導出。
   - APIキーを `AES-GCM-256` で暗号化して IndexedDB に保存。セッション復帰時はパスワード入力でメモリ上にのみ復号展開する。
2. セッション限定モード:
   - ストレージに一切書き込まず、ブラウザを閉じるまで `sessionStorage` またはメモリ上でのみ保持。

```typescript
// 暗号化ロジック (Web Crypto API / NIST SP 800-132 準拠)
async function encryptApiKey(apiKey: string, masterPass: string): Promise<{
  cipher: ArrayBuffer; salt: Uint8Array; iv: Uint8Array;
}> {
  const enc = new TextEncoder();
  const salt = crypto.getRandomValues(new Uint8Array(32)); // 256-bit salt
  const iv = crypto.getRandomValues(new Uint8Array(12));   // 96-bit IV for GCM

  const keyMaterial = await crypto.subtle.importKey(
    "raw", enc.encode(masterPass), "PBKDF2", false, ["deriveKey"]
  );
  const key = await crypto.subtle.deriveKey(
    { name: "PBKDF2", salt, iterations: 600000, hash: "SHA-256" },
    keyMaterial,
    { name: "AES-GCM", length: 256 },
    false,
    ["encrypt"]
  );

  const cipher = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv }, key, enc.encode(apiKey)
  );
  return { cipher, salt, iv };
}
```

### 3.2 ゼロ・クラウドファイル保持（IndexedDBローカル永続化）
- ファイル実体の隔離: プロジェクトの全ファイルデータ（`src/`、`package.json` 等）は、端末の IndexedDB にのみ保存されます。
- 通信内容の最小化: Google API へ送信するのは「ユーザーの指示」「編集対象の関数/差分」「AST Skeleton（型情報）」のみであり、ファイルシステム全体をクラウドに同期・保管することはありません。
- ストレージ永続化: `navigator.storage.persist()` を初期化時に実行し、スマホのOSによるブラウザキャッシュ自動削除（Eviction）を防止します。

```typescript
async function requestPersistentStorage(): Promise<boolean> {
  if (navigator.storage && navigator.storage.persist) {
    const isPersisted = await navigator.storage.persist();
    console.log(`IndexedDB 永続化ステータス: ${isPersisted ? "永続化成功" : "一時ストレージ"}`);
    return isPersisted;
  }
  return false;
}
```

---

## 4. ゼロトラスト実行環境（サンドボックス）

Web Worker単体では `Same-Origin` のCookieやローカル通信にアクセスできてしまうため、二重の隔離レイヤー を採用する。

- ホスト側: IDE本体、IndexedDB、APIキー管理、UI。
- サンドボックス側: `<iframe sandbox="allow-scripts">`（`allow-same-origin` は付与しない）。
  - オリジンが強制的に `null` となり、親のDOM、LocalStorage、IndexedDB、Cookieへのアクセスがブラウザレベルで遮断される。
  - コードの構文解析、TypeScript型チェック、テスト実行（Pyodide / QuickJS / WebContainers）はすべてこの iframe 内で実行し、結果のみを `postMessage` 経由の JSON-RPC 2.0 でホストに返す。
- 通信プロトコル: `postMessage` は型安全なJSON-RPC 2.0でラップし、Origin検証（`event.origin === 'null'`）を必須とする。

---

## 5. Google Gemini 3.x モデルオーケストレーション

### 5.1 使用モデル一覧（Gemini 3.x ファミリー統一）
推論の癖やFunction Callingの挙動破綻を防ぐため、モデルはGoogle Gemini 3.xファミリーに統一します。
(※Gemini 2.x系は2026年6月1日にシャットダウン済みのため一切使用しない)

| モデル | 主な役割 | 特徴・コスト (per 1M tokens) |
| :--- | :--- | :--- |
| Gemini 3.7 Flash | メイン推論・コード生成・修正・プランニング | 最新のコーディング特化モデル。思考モード対応。紹介価格適用中（〜2026/12/31） |
| Gemini 3.6 Flash | フォールバック 1 / 複雑な型エラー解決 | 高速・安定したコード生成（Antigravity等でも実績多数）。1.50 in / 7.50 out |
| Gemini 3.5 Flash | フォールバック 2 / エージェントワークフロー | 標準エージェントモデル（1.50 in / 9.00 out） |
| Gemini 3.5 Flash-Lite | Scribe Agent（ログ生成）/ AST抽出 | 超軽量・極小レイテンシ（0.15 in / 0.60 out） |
| Gemini 3.1 Pro | 巨大設計・難関リファクタリング | 200万トークン対応・最上位推論（2.00/12.00 @200K以下） |

### 5.2 Interactions API への対応
- Google公式の最新標準である Interactions API を通信プロトコルとして採用。
- 単一の対話ストリーム内で、ツールの呼び出し（`tool_calls`）とステップ実行（`steps`）をスムーズに処理。
- 従来の `GenerateContent` も併用可能とし、段階的移行を可能にする。

### 5.3 BYOK 直接通信と CORS 対策
- 基本通信路: `@google/genai` (公式 JavaScript SDK) を使用。Gemini API エンドポイントはブラウザからの直接 CORS リクエストを公式にサポートしている。
- フォールバック設計: 万が一の企業内プロキシ制限や将来のCORS仕様変更に備え、以下の拡張ポイントを設ける。
  - `Direct Fetch Mode`（デフォルト・標準）
  - `Local Proxy Mode`（ユーザーが手元で起動した `localhost:PORT` 経由へのルーティング設定）

### 5.4 レート制限（429 / RESOURCE_EXHAUSTED）バックオフ ＆ コスト最適化
1. 指数バックオフ: 429 エラー検知時は、ジッター付き指数バックオフ（1s → 2s → 4s → 8s）で同一モデル内で再試行。
2. Tier フォールバック: 上限到達時は `3.7 Flash` → `3.6 Flash` → `3.5 Flash` → `3.5 Flash-Lite` へ自動切り替え。
3. Context Caching: システムプロンプトやプロジェクト共通の型定義（AST Skeleton）をキャッシュし、通信コストを 75〜90% 削減。
4. Flex / Priority Tier: 2026年4月に導入された Flex Tier と Priority Tier を活用。
   - Priority: 緊急のリアルタイムタスク。標準レート、最優先処理。
   - Flex: バッチ処理・非緊急タスク（Scribeログ等）。最大50%割引、キューイング許容。

```typescript
const GEMINI_TIER_ORDER = [
  "gemini-3.7-flash",
  "gemini-3.6-flash",
  "gemini-3.5-flash",
  "gemini-3.5-flash-lite"
];

async function callGeminiWithRetry(
  prompt: any,
  tierIndex = 0,
  options?: { useCache?: boolean; tier?: "flex" | "priority" }
): Promise<any> {
  const model = GEMINI_TIER_ORDER[tierIndex];
  const MAX_RETRIES = 3;

  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    try {
      return await genAI.models.generateContent({
        model,
        contents: prompt,
        config: {
          responseMimeType: "application/json",
          ...(options?.tier && { tier: options.tier }),
          ...(options?.useCache && { cachedContent: cacheName }),
        },
      });
    } catch (error: any) {
      const isRateLimit = error.status === 429 
        || error.message?.includes("RESOURCE_EXHAUSTED");

      if (isRateLimit && attempt < MAX_RETRIES) {
        const delay = Math.pow(2, attempt) * 1000 + Math.random() * 1000;
        await new Promise(r => setTimeout(r, delay));
        continue;
      }

      if (isRateLimit && tierIndex < GEMINI_TIER_ORDER.length - 1) {
        console.warn(`[Tier Fallback] ${model} 制限。${GEMINI_TIER_ORDER[tierIndex + 1]} にフォールバック。`);
        return callGeminiWithRetry(prompt, tierIndex + 1, options);
      }
      throw error;
    }
  }
}
```

### 5.5 Context Caching（コンテキストキャッシュ）によるコスト最適化
システムプロンプト、プロジェクトのAST Skeleton、参照ドキュメントなど、頻繁に再利用されるコンテキストをキャッシュし、75〜90%のコスト削減 を実現する。

```typescript
interface CacheConfig {
  ttlSeconds: number;      // キャッシュ有効期限（最大3600秒）
  displayName: string;     // キャッシュ識別名
}

async function createContextCache(
  systemPrompt: string,
  referenceDocs: string[],
  config: CacheConfig
): Promise<string> {
  const contents = [
    { role: "user", parts: [{ text: systemPrompt }] },
    ...referenceDocs.map(doc => ({ role: "user", parts: [{ text: doc }] }))
  ];

  const cache = await genAI.caches.create({
    model: "gemini-3.6-flash",
    config: {
      contents,
      ttlSeconds: config.ttlSeconds,
      displayName: config.displayName,
    },
  });
  return cache.name; // 例: "cachedContents/abc123"
}
```

---

## 6. モバイル特化型 UI/UX ＆ Human-in-the-Loop TDD ワークフロー

### 6.1 モバイル向け Claude Code インターフェース
PCの複雑な3ペインUI（ツリー・エディタ・ターミナル）を廃止し、スマホに最適化されたタブ切替型モバイルインターフェースを採用。

```text
┌──────────────────────────────────────────┐
│  [Project: my-react-app]    [⚙ Settings] │
├──────────────────────────────────────────┤
│                                          │
│  🤖 Agent:                              │
│  ヘッダーのナビゲーションバーを作成し、    │
│  レスポンシブ対応を追加しました。         │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ 📄 src/components/Header.tsx (+42) │  │
│  │ ---------------------------------- │  │
│  │ + export const Header = () => {    │  │
│  │ +   return <nav>...</nav>;         │  │
│  │ + };                               │  │
│  └────────────────────────────────────┘  │
│                                          │
├──────────────────────────────────────────┤
│  [  ❌ Reject  ]     [  ✅ Approve (適用) ] │ ◀── 片手でタップ/スワイプ承認
├──────────────────────────────────────────┤
│  > チャットで指示...                 [↑] │
├──────────────────────────────────────────┤
│  [ 💬 Chat ]  [ 📄 Code ]  [ 🌐 Preview ] │ ◀── ボトムナビゲーション
└──────────────────────────────────────────┘
```

### 6.2 片手で操作できる「Diff承認ゲート（Approval Gate）」
1. エージェントがコードを生成すると、IndexedDBへの適用前に「Diffプレビュー」を画面にカード形式で提示。
2. ユーザーは「Approve（承認）」を押すだけで、パッチがIndexedDBに適用されスナップショットが記録される。
3. 気に入らない場合は「Reject（却下）」または「修正指示」をチャットで送信。

### 6.3 アプリ内 Web Live Preview
- 生成されたHTML/CSS/JSは、ブラウザ内の `Blob URL` または `srcdoc iframe` を用いて、別タブを開かずにアプリ内の「Preview」タブで即座に動作確認可能。

### 6.4 Human-in-the-Loop 承認ゲート付き TDD ワークフロー
エージェントが勝手にファイルを書き換えて破壊するのを防ぐため、UI上の 承認ゲート（Approval Gate） を必須化する。

```text
[ユーザー指示]
     │
     ▼
【Phase 1: Contract (型定義・インターフェース)】 ──> [Wasm型チェック + Structured Output検証]
     │
     ▼
【Phase 2: Test (テストコード生成)】 ───────────> [Wasmテスト事前検証 (Red)]
     │
     ▼
【Phase 3: Implementation (実装コード生成)】 ───> [Wasmテスト検証 (Green)]
     │
     ▼
【Phase 4: 承認ゲート (Approval Gate)】 ◀───────── [★ Human-in-the-Loop]
     │
     ├── ［ 画面に Live Diff & テスト結果 & コスト推計を表示 ］
     │      ├── [ 承認 (Approve) ] ──> IndexedDBへコミット ＆ スナップショット作成
     │      ├── [ 修正指示 (Revise) ] ──> 指示をフィードバックしてPhase 3へ差し戻し
     │      └── [ 却下 (Reject) ] ──> 変更を破棄 ＆ スナップショット復元
```

### 6.5 設定可能な動作モード
- Interactive Mode（推奨・デフォルト）: パッチ適用前に必ずDiffの承認を要求。
- Auto-Pilot Mode: 型チェックとテストがパスした場合のみ自動適用（ワンクリックで切り替え可能）。
- Cost-Aware Mode: 推定コストが閾値を超える場合、必ず承認を要求。

---

## 7. 堅牢なパッチ＆検証エンジン

### 7.1 曖昧性を排除した Fuzzy Search & Replace パッチエンジン
スマホの非力な環境でも一瞬で完了し、既存コードを壊さない「差分置換方式」を採用。

```text
<<<<<<< SEARCH
export const Button = ({ text }: { text: string }) => {
  return <button>{text}</button>;
};
=======
export const Button = ({ text, onClick }: { text: string; onClick?: () => void }) => {
  return <button onClick={onClick} className="btn-primary">{text}</button>;
};
>>>>>>> REPLACE
```

LLMが生成する差分パッチの失敗を防ぐため、3段階のフォールバック・マッチングを行う。

```typescript
export interface PatchResult {
  success: boolean;
  patchedContent?: string;
  error?: "NO_MATCH" | "AMBIGUOUS_MATCH" | "SYNTAX_ERROR" | "VALIDATION_FAILED";
}

function applySearchReplace(
  original: string,
  searchBlock: string,
  replaceBlock: string
): PatchResult {
  // Step 1: 完全一致チェック
  const exactMatches = original.split(searchBlock).length - 1;
  if (exactMatches === 1) {
    return { success: true, patchedContent: original.replace(searchBlock, replaceBlock) };
  }
  if (exactMatches > 1) {
    return { success: false, error: "AMBIGUOUS_MATCH" };
  }

  // Step 2: 空白・インデント・改行コードを正規化した Fuzzy 一致チェック
  const normalizedOriginal = normalizeWhitespace(original);
  const normalizedSearch = normalizeWhitespace(searchBlock);
  const fuzzyIndex = normalizedOriginal.indexOf(normalizedSearch);
  if (fuzzyIndex !== -1) {
    const fixedContent = applyFuzzyPatch(original, searchBlock, replaceBlock);
    return { success: true, patchedContent: fixedContent };
  }

  // Step 3: 一致しない場合
  return { success: false, error: "NO_MATCH" };
}
```

#### パッチ適用失敗時のリカバリー戦略
1. `AMBIGUOUS_MATCH`: エージェントに「周辺の行（コンテキスト）を前後に5行増やしてSEARCHブロックを再生成してください」と指示（最大2リトライ）。
2. `NO_MATCH`: 対象関数のスコープを AST から再取得してプロンプトへ再注入。
3. `SYNTAX_ERROR`: パッチ適用後のコードをWasmコンパイラで検証し、失敗時は自動ロールバック。

### 7.2 コンテキスト注入の使い分け基準（AST Skeleton vs フルコード vs キャッシュ）

| ケース | 渡すコンテキスト | 判定基準 | キャッシュ戦略 |
| :--- | :--- | :--- | :--- |
| 他ファイルへの参照 / プロジェクト全容把握 | AST Skeleton（型・シグネチャのみ） | 参照先ファイル全般 | Context Cache推奨 |
| 編集対象の局所修正（関数単位） | 対象関数ブロック + 前後5行 | 該当ファイルが300行以上の場合 | なし |
| 編集対象の全面改修 / 新規作成 | 対象ファイル全文 | 該当ファイルが300行未満の場合 | なし |
| プロジェクト全体の設計レビュー | ファイルツリー + 主要ファイルのSkeleton | アーキテクチャ相談時 | Context Cache必須 |

---

## 8. 1作業1ログ（Immutable Markdown Log）× Scribe Agent 仕様

### 8.1 非同期書き込みの競合制御（Mutex Lock + Write-Ahead Log）
メインスレッドと Scribe Agent（記録役）のIndexedDB書き込みが重複してデータが破損するのを防ぐため、非同期排他制御（Mutex） と Write-Ahead Log（WAL） を実装する。

```typescript
class ScribeMutex {
  private locked = false;
  private queue: (() => void)[] = [];

  async acquire(): Promise<() => void> {
    if (!this.locked) {
      this.locked = true;
      return () => this.release();
    }
    return new Promise(resolve => {
      this.queue.push(() => resolve(() => this.release()));
    });
  }

  private release() {
    this.locked = false;
    const next = this.queue.shift();
    if (next) next();
  }
}
```

### 8.2 ログフォーマット（Frontmatter + Markdown + 構造化データ＋コスト追跡）
- パス: `.agent/logs/SEQ_YYYY-MM-DD_kebab-case.md`
- コスト追跡: 各ログに使用トークン数・推定コストを記録

```markdown
---
seq: 5
timestamp: "2026-08-17T01:45:00Z"
type: "feature"
model_used: "gemini-3.7-flash"
tier_used: "priority"
touched_files:
  - "src/components/Header.tsx"
snapshot_id: "snap_005_e8f2a1"
verified_by_tests: true
approved_by_user: true
cost_estimate:
  input_tokens: 15234
  output_tokens: 892
  cached_tokens: 45000
  estimated_usd: 0.023
---

# 🛠️ 作業ログ: モバイル対応ヘッダーコンポーネントの追加

## 🎯 指示内容
> "スマホ表示でハンバーガーメニューになるヘッダーを作って"

## ⚠️ 発生したエラー
- `AssertionError: expected 108.9 to equal 108`

## 💡 解決内容 ＆ 教訓 (Lessons Learned)
- Tailwind CSS の `md:hidden` クラスを用いてレスポンシブナビゲーションを実装。
- **Lesson:** このプロジェクトではアイコンライブラリに `lucide-react` を使用する。
- **教訓:** このプロジェクトの金額計算はすべて整数化（Integer）を前提とする。
```

---

## 9. ストレージ永続化 ＆ エクスポート / インポート仕様

### 9.1 ブラウザストレージの永続化宣言
IndexedDBがブラウザの容量逼迫時に自動削除される（Eviction）のを防止する（3.2節参照）。

### 9.2 成果物のエクスポート / インポート機能
1. GitHub API 直接連携 (BYOK):
   - ユーザーの GitHub Personal Access Token を使って、スマホから直接GitHubリポジトリを作成、コミット、プルリクエスト（PR）作成 が可能。
   - スマホでAIに指示 → そのままGitHubにPR作成 → VercelやCloudflare Pagesで自動デプロイ という完全モバイル開発フローが成立。
2. Zip一括ダウンロード (`JSZip`):
   - IndexedDB内のプロジェクト全ファイルを `.zip` でスマホの「ファイル」アプリにワンタップ保存。
   - ログ・スナップショットも含めた完全バックアップモードと、ソースコードのみの軽量モードを選択可能。
3. File System Access API 連携:
   - ユーザーが指定したPC内のローカルフォルダと、IndexedDBの仮想ファイルを1クリックで双方向同期。
   - `.agent/` ディレクトリは同期対象外とし、IDE内部データと明確に分離。

---

## 10. IndexedDB スキーマ定義 ＆ マイグレーション戦略 (Version 4)

データベース名: `UnifiedAgentIDE_DB` (Version: 4)

```typescript
export interface IDBSchemaV4 {
  // 仮想ファイルシステム (完全ローカル保管)
  files: {
    key: string;               // path: "src/App.tsx"
    value: {
      path: string;
      content: string;
      updatedAt: number;
      checksum: string;        // SHA-256ハッシュで改竄検知
    };
  };

  // タイムトラベル（スナップショット）
  snapshots: {
    key: string;               // snapshotId: "snap_005_e8f2a1"
    value: {
      id: string;
      seq: number;
      timestamp: number;
      files: Record<string, string>;
      logPath: string;
      parentSnapshotId?: string; // 差分ベースの親スナップショット（圧縮）
    };
  };

  // 暗号化セキュリティ (APIキー完全ローカル保管)
  security: {
    key: string;               // "gemini_api_key" | "github_pat"
    value: {
      cipher: ArrayBuffer;
      salt: Uint8Array;
      iv: Uint8Array;
      createdAt: number;       // 暗号化設定日時
    };
  };

  // Context Cache メタデータ
  contextCaches: {
    key: string;               // cacheName: "cachedContents/abc123"
    value: {
      name: string;
      model: string;
      displayName: string;
      ttlSeconds: number;
      createdAt: number;
      expiresAt: number;
      tokenCount: number;
    };
  };

  // エージェント設定・プリファレンス
  preferences: {
    key: string;
    value: {
      defaultModel: string;
      defaultTier: "flex" | "priority";
      autoPilotThreshold: number; // 自動承認のコスト閾値（USD）
      masterPasswordHint?: string; // パスワードヒント（平文OK）
    };
  };
}

// マイグレーションハンドラー
export function openDatabase(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open("UnifiedAgentIDE_DB", 4);

    request.onupgradeneeded = (event) => {
      const db = request.result;
      const oldVersion = event.oldVersion;

      // v1 -> v2 マイグレーション
      if (oldVersion < 1) {
        db.createObjectStore("files", { keyPath: "path" });
        db.createObjectStore("snapshots", { keyPath: "id" });
        db.createObjectStore("security", { keyPath: "key" });
      }
      if (oldVersion < 2) {
        db.createObjectStore("contextCaches", { keyPath: "name" });
        db.createObjectStore("preferences", { keyPath: "key" });
        
        const filesStore = request.transaction!.objectStore("files");
        if (!filesStore.indexNames.contains("updatedAt")) {
          filesStore.createIndex("updatedAt", "updatedAt", { unique: false });
        }
      }
      // v2 -> v3 マイグレーション (Web-Native版統合)
      if (oldVersion < 3) {
        const snapshotStore = request.transaction!.objectStore("snapshots");
        if (!snapshotStore.indexNames.contains("seq")) {
          snapshotStore.createIndex("seq", "seq", { unique: false });
        }
      }
      // v3 -> v4 マイグレーション (統合版最新)
      if (oldVersion < 4) {
        const securityStore = request.transaction!.objectStore("security");
        if (!securityStore.indexNames.contains("createdAt")) {
          securityStore.createIndex("createdAt", "createdAt", { unique: false });
        }
      }
    };

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}
```

---

## 11. 実装ロードマップ（優先順位順）

- Milestone 1: セキュア基盤 ＆ モバイルUIプロトタイプ
  - PWA対応（マニフェスト、ServiceWorker）とレスポンシブなClaude Code風チャットUI
  - `Web Crypto API` による API キー暗号化・IndexedDB v4 初期化＆マイグレーション
  - `@google/genai` (Interactions API) のブラウザ直接疎通（CORS検証）
  - `navigator.storage.persist()` によるストレージ永続化宣言

- Milestone 2: ローカルファイルシステム ＆ 承認ゲート
  - IndexedDB 仮想ファイルシステムと Live Preview（Blob URL表示）
  - Fuzzy Search & Replace パッチエンジン
  - モバイル向け「Live Diff プレビュー ＆ 承認/却下/修正指示」UI
  - コスト推計表示機能（トークン数 → USD換算）

- Milestone 3: ゼロトラストサンドボックスとコンパイラ Wasm
  - `<iframe sandbox="allow-scripts">` の JSON-RPC 2.0 通信基盤構築
  - Wasm による TypeScript Language Service（型チェック）の稼働
  - Structured Output Validator（Zodスキーマによる応答検証）
  - AST Context Router（Tree-sitter / Babel Wasm）によるスケルトン抽出

- Milestone 4: Gemini 3.x オーケストレーター ＆ TDD ループ
  - Gemini 3.7 Flash を主軸とした TDD ステートマシン（Contract → Test → Impl → Approval）
  - Context Caching によるシステムプロンプト・参照ドキュメントの永続キャッシュ
  - Flex/Priority Tier 自動選択ロジック
  - 指数バックオフ ＆ Tier フォールバック（429制限対策）

- Milestone 5: ログ自己改善 ＆ 外部連携
  - 非同期 Scribe Agent による 1作業1Markdown ログ生成（コスト追跡付き）
  - Mutex Lock + WAL による書き込み競合制御
  - スナップショット巻き戻し（タイムトラベル）機能
  - GitHub API 連携（スマホからの直接コミット/PR作成）
  - `JSZip` によるプロジェクト一括エクスポート（完全バックアップ / 軽量モード）
  - File System Access API によるローカルフォルダ双方向同期