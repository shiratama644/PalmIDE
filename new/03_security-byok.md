<!-- 統合版: docs/03_security-byok.md の Phase 4 追記（G02 decryptApiKey）を本文にマージ（元: Local_AI_Agent.md §3.1 Lines 89-132） -->
# 03 セキュリティ — 暗号化BYOK（APIキーの完全ローカル保護）

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local%20AI%20Agent.md)（§3.1 Lines 89-132）
> **インデックス**: [README.md](./README.md)
> **関連ファイル**: [02_architecture.md](./02_architecture.md) | [04_storage-persist.md](./04_storage-persist.md)（§3.2） | [05_sandbox.md](./05_sandbox.md)（ゼロトラスト） | [12_db-schema.md](./12_db-schema.md)（securityストア）

> **要約**: 本ファイルはAES-GCM-256 / PBKDF2 (600,000 iterations, SHA-256, 256-bit Salt) によるAPIキー暗号化・復号、2つの暗号化モード（暗号化保存/セッション限定）、セッション破棄（5分無操作でnull化）を定義する。ファイル永続化の詳細は [04_storage-persist.md](./04_storage-persist.md) を参照。

> **ナビゲーション**: ← [02_architecture.md](./02_architecture.md) | [04_storage-persist.md](./04_storage-persist.md) →

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

### 3.1.1 復号と誤パスワード時の挙動

`encryptApiKey` に対応する復号関数とエラーハンドリングを以下に定義する。`encrypt` と対称な導出パラメータ（600,000 iterations / SHA-256 / 256-bit Salt）を用いるため round-trip が保証される。

```typescript
async function decryptApiKey(
  cipher: ArrayBuffer, salt: Uint8Array, iv: Uint8Array, masterPass: string
): Promise<string> {
  const enc = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey("raw", enc.encode(masterPass), "PBKDF2", false, ["deriveKey"]);
  const key = await crypto.subtle.deriveKey(
    { name: "PBKDF2", salt, iterations: 600000, hash: "SHA-256" },
    keyMaterial, { name: "AES-GCM", length: 256 }, false, ["decrypt"]
  );
  try {
    const plain = await crypto.subtle.decrypt({ name: "AES-GCM", iv }, key, cipher);
    return new TextDecoder().decode(plain);
  } catch (e) {
    // Web Crypto は誤パスワード/破損データで OperationError を投げる
    throw new Error("DECRYPT_FAILED: パスワードが間違っているかデータが破損しています");
  }
}
// 呼び出し側
try { apiKey = await decryptApiKey(cipher, salt, iv, inputPass); }
catch (e) { showToast("パスワードが違います。再入力してください（残り試行3回）"); }
```

- **UI**: 誤パスワード時は「パスワード再入力モーダル」を表示し、3回失敗で「暗号化保存モードをリセットしますか？」の導線を出す。
- **整合性**: 5分無操作破棄後はメモリ上の鍵を `null` 化し、再入力を求める既存仕様と整合させる。
- **将来**: `NIST SP 800-132` 準拠の `salt` 長は維持すること。将来 `salt` を更新する際のマイグレーションは [12_db-schema.md](./12_db-schema.md) で扱う。

---

> **出典**: `Local_AI_Agent.md` §3.1（Lines 89-132）。復号仕様（G02補足）を本文に統合した統合版である。
> **相互参照**: [02_architecture.md](./02_architecture.md) | [04_storage-persist.md](./04_storage-persist.md)（§3.2） | [05_sandbox.md](./05_sandbox.md)（ゼロトラスト） | [12_db-schema.md](./12_db-schema.md)（securityストア） | [README.md](./README.md)
