<!-- 統合版: docs/12_db-schema.md の Phase 4〜5 追記（G12 checksum / G17 バリデーション / G11 ダウングレード / R6 v5移行 / R9 snapshots checksum）を本文にマージ（元: Local_AI_Agent.md §10 Lines 501-615） -->
# 12 IndexedDBスキーマ定義とマイグレーション戦略 (Version 4)

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local%20AI%20Agent.md)（§10 Lines 501-615）
> **インデックス**: [README.md](./README.md)
> **関連ファイル**: [04_storage-persist.md](./04_storage-persist.md) | [10_logging-scribe.md](./10_logging-scribe.md) | [11_storage-export.md](./11_storage-export.md) | [03_security-byok.md](./03_security-byok.md)

> **要約**: 本ファイルは `UnifiedAgentIDE_DB` v4 の5ストア（files/snapshots/security/contextCaches/preferences）と、v1→v4マイグレーション（createObjectStore/Index）、checksum ライフサイクル（files+snapshots）、preferences バリデーション、ダウングレード時の扱い、および v5 マイグレーション計画を定義する。

> **ナビゲーション**: ← [11_storage-export.md](./11_storage-export.md) | [13_roadmap.md](./13_roadmap.md) →

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

### 10.1 checksum ライフサイクル（files / snapshots）

`checksum`（SHA-256）の計算・照合タイミングを以下に定義する。計算は `crypto.subtle.digest("SHA-256", content)` で行い、ブラウザ内で完結する（Wasm不要、計算コストは低い）。

- **計算**: `files` ストアへの `put` 時（パッチ適用直後）に計算し、`files.checksum` に保存。
- **照合**: `Preview` 表示前・`Export`（Zip / File System Access）直前・`snapshot` 復元時に `checksum` を再計算する。不一致なら `console.warn` + トースト「ファイルが破損している可能性があります。スナップショットから復元しますか？」
- **snapshots**: スナップショット復元時は、復元対象の `files` 全てについて `checksum` を再計算し、不一致があれば「スナップショットが破損している可能性があります。復元しますか？」の確認ダイアログを出す。
- **不一致時**: 自動上書きせず、人間に復元を委ねる（データ損失防止）。

### 10.2 preferences バリデーション

`preferences.defaultModel` / `defaultTier` の取りうる値を以下の通り列挙化し、不正値は `warn` ログを出しつつデフォルトにフォールバックする。`GEMINI_TIER_ORDER`（07）や `defaultTier: "flex" | "priority"` の既存記述と整合させ、将来のモデル追加時の差分を最小化する。

```typescript
const ALLOWED_MODELS = ["gemini-3.7-flash","gemini-3.6-flash","gemini-3.5-flash","gemini-3.5-flash-lite","gemini-3.1-pro"] as const;
const ALLOWED_TIERS = ["flex","priority"] as const;
function validatePreferences(p: IDBSchemaV4["preferences"]["value"]) {
  if (!ALLOWED_MODELS.includes(p.defaultModel as any)) p.defaultModel = "gemini-3.7-flash";
  if (!ALLOWED_TIERS.includes(p.defaultTier as any)) p.defaultTier = "priority";
  p.autoPilotThreshold = Math.min(Math.max(p.autoPilotThreshold, 0), 10); // 0〜10 USD にクランプ
}
```

### 10.3 ダウングレード時の扱い（v4超 → v4未満）

`oldVersion > 4` のダウングレードは**未対応（Skip）**とする。`onupgradeneeded` で `oldVersion > 4` の場合は `console.warn("Downgrade detected. Please clear site data.")` のみ出し、何もしない。ブラウザがDBを自動削除するか、ユーザにサイトデータ削除を促す運用とする。IndexedDB の仕様上 `oldVersion > currentVersion` は通常発生しない（ユーザが古いコードを再デプロイした時のみ）ため、過剰な実装は避ける。将来 v5 以降ができてからダウングレードマイグレーションを検討する。

### 10.4 v5 マイグレーション計画（maxReviseRetries の追加）

`preferences` への `maxReviseRetries`（[08_ui-ux-workflow.md](./08_ui-ux-workflow.md) §6.6）追加に伴う v4→v5 マイグレーションの叩き台を定義する。

```typescript
export function openDatabaseV5(): Promise<IDBDatabase> {
  const req = indexedDB.open("UnifiedAgentIDE_DB", 5);
  req.onupgradeneeded = (e) => {
    const db = req.result; const oldVersion = (e as IDBVersionChangeEvent).oldVersion;
    // v4までの処理は既存の openDatabase() と同一
    if (oldVersion < 5) {
      const prefStore = req.transaction!.objectStore("preferences");
      // 既存の preferences レコードに maxReviseRetries を追加
      // マイグレーション時は全レコードを走査し、maxReviseRetries ?? 3 を付与
    }
  };
}
```

本番では `openDatabase` を v5 に更新し、[14_shared-contracts.md](./14_shared-contracts.md) の `GenAIClientConfig` と整合させる。適用時期は `maxReviseRetries` が必要になる **Milestone 2**（[13_roadmap.md](./13_roadmap.md)）とする。

---

> **出典**: `Local_AI_Agent.md` §10（Lines 501-615）。checksum ライフサイクル（G12/R9）、preferences バリデーション（G17）、ダウングレード方針（G11）、v5 マイグレーション（R6）を本文に統合した統合版である。
> **相互参照**: [04_storage-persist.md](./04_storage-persist.md) | [10_logging-scribe.md](./10_logging-scribe.md) | [11_storage-export.md](./11_storage-export.md) | [03_security-byok.md](./03_security-byok.md) | [README.md](./README.md)
