<!-- 統合版: docs/04_storage-persist.md の Phase 4 追記（G18 persist()フォールバック）を本文にマージ（元: Local_AI_Agent.md §3.2 Lines 133-150） -->
# 04 ローカルストレージ — ゼロ・クラウドファイル保持

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local%20AI%20Agent.md)（§3.2 Lines 133-150）
> **インデックス**: [README.md](./README.md)
> **関連ファイル**: [03_security-byok.md](./03_security-byok.md)（§3.1） | [11_storage-export.md](./11_storage-export.md)（§9.1で3.2節を参照） | [12_db-schema.md](./12_db-schema.md)（filesストア）

> **要約**: 本ファイルはIndexedDBローカル永続化（ファイル実体隔離・通信最小化・`navigator.storage.persist()`）と、永続化拒否時のフォールバック仕様を定義する。永続化宣言の再掲は [11_storage-export.md](./11_storage-export.md) §9.1 でも参照される。

> **ナビゲーション**: ← [03_security-byok.md](./03_security-byok.md) | [05_sandbox.md](./05_sandbox.md) →

---

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

### 3.2.1 persist() 拒否時のフォールバック

`navigator.storage.persist()` はユーザのブラウザ設定やOSポリシーで拒否されうる（MDN）。`false` が返った場合でもアプリ自体は動作させるが、OSの容量逼迫によるエビクションリスクをユーザーに必ず警告し、以下のフォールバックを実行する。

```typescript
const ok = await navigator.storage.persist();
if (!ok) {
  showToast("永続化が拒否されました。ブラウザ設定で『サイトデータを保持』を有効にしてください。", {
    action: { label: "再試行", onClick: () => requestPersistentStorage() }
  });
  // IndexedDB自体は使えるが、OSの容量逼迫で削除されるリスクを警告
  showBanner("この端末ではプロジェクトが自動削除される可能性があります。こまめにZipエクスポートを推奨します。", "warning");
}
```

あわせて `StorageManager.estimate()` で定期的に残容量を監視することを推奨する。永続化状態の型 `PersistState: "granted" | "denied" | "prompt"` は [14_shared-contracts.md](./14_shared-contracts.md) §6 の共通契約を参照。

---

> **出典**: `Local_AI_Agent.md` §3.2（Lines 133-150）。persist() 拒否時フォールバック（G18補足）を本文に統合した統合版である。
> **相互参照**: [03_security-byok.md](./03_security-byok.md)（§3.1） | [11_storage-export.md](./11_storage-export.md)（§9.1で3.2節を参照） | [12_db-schema.md](./12_db-schema.md)（filesストア） | [README.md](./README.md)
