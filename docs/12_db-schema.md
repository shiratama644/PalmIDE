<!-- 元ファイル: Local_AI_Agent.md §10 Lines 501-615 -->
# 12 IndexedDBスキーマ定義とマイグレーション戦略 (Version 4)

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local_AI_Agent.md)
> **インデックス**: [README.md](../README.md) | [Phase0設計書](../PHASE0_design.md)
> **関連ファイル**: [04_storage-persist.md](./04_storage-persist.md) | [10_logging-scribe.md](./10_logging-scribe.md) | [11_storage-export.md](./11_storage-export.md) | [03_security-byok.md](./03_security-byok.md) | [README.md](../README.md)
> **元セクション**: §10（Lines 501-615）

> **要約**: 本ファイルは UnifiedAgentIDE_DB v4 の5ストア（files/snapshots/security/contextCaches/preferences）と、v1→v4マイグレーション（createObjectStore/Index）を定義する。

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

---


> 🆕 **詳細化補足（Phase 4）— G12 checksumライフサイクル**
> - **対象**: `checksum`（SHA-256）の計算・照合タイミング未定義
> - **種別**: 🟡要確認の解消
> - **内容**: 以下のライフサイクルを叩き台として提案する。
>   - **計算**: `files` ストアへの `put` 時（パッチ適用直後）に `crypto.subtle.digest("SHA-256", content)` で計算し、`files.checksum` に保存。
>   - **照合**: `Preview` 表示前・`Export`（Zip/File System Access）直前・`snapshot` 復元時に `checksum` を再計算し不一致なら `console.warn` + トースト「ファイルが破損している可能性があります。スナップショットから復元しますか？」
>   - **不一致時**: 自動上書きせず、人間に復元を委ねる（データ損失防止）。
> - **根拠**: 仕様書の `checksum: string // SHA-256ハッシュで改竄検知` というコメントを具体化したもの。計算コストは低く、Wasm不要でブラウザ内で完結。

> 🆕 **詳細化補足（Phase 4）— G17 preferencesバリデーション**
> - **対象**: `preferences.defaultModel` / `defaultTier` の取りうる値未定義
> - **種別**: 🟢補足
> - **内容**: 以下のバリデーションを推奨する。
>   ```typescript
>   const ALLOWED_MODELS = ["gemini-3.7-flash","gemini-3.6-flash","gemini-3.5-flash","gemini-3.5-flash-lite","gemini-3.1-pro"] as const;
>   const ALLOWED_TIERS = ["flex","priority"] as const;
>   function validatePreferences(p: IDBSchemaV4["preferences"]["value"]) {
>     if (!ALLOWED_MODELS.includes(p.defaultModel as any)) p.defaultModel = "gemini-3.7-flash";
>     if (!ALLOWED_TIERS.includes(p.defaultTier as any)) p.defaultTier = "priority";
>     p.autoPilotThreshold = Math.min(Math.max(p.autoPilotThreshold, 0), 10); // 0〜10 USD にクランプ
>   }
>   ```
>   不正値はログに `warn` しつつデフォルトにフォールバック。`preferences` は `12_db-schema.md` の `preferences` ストアに保存。
> - **根拠**: `GEMINI_TIER_ORDER`（07）や `defaultTier: "flex"|"priority"` の既存記述を列挙化し、将来のモデル追加時の差分を最小化するため。

> 🆕 **詳細化補足（Phase 4）— G11 ダウングレード時の扱い（Skipの理由付き）**
> - **対象**: `oldVersion > 4` のダウングレード時
> - **種別**: 🟢補足（軽量・Skip相当）
> - **内容**: 現時点では**未対応（Skip）**とする。`onupgradeneeded` で `oldVersion > 4` の場合は `console.warn("Downgrade detected. Please clear site data.")` のみ出し、何もしない。ブラウザがDBを自動削除するか、ユーザにサイトデータ削除を促す運用とする。将来v5ができてからダウングレードマイグレーションを検討。
> - **根拠**: ダウングレードは稀で、IndexedDBの仕様上 `oldVersion > currentVersion` は通常発生しない（ユーザが古いコードを再デプロイした時のみ）。過剰な実装を避けるため。

> 🆕 **詳細化補足（Phase 5・レビュー反映）— R6 v4→v5マイグレーション**
> - **指摘元**: REVIEW_DESIGN.md R6
> - **内容**: `maxReviseRetries`（G09）と `RATE_TABLE` の `preferences` 追加に伴い、DB v4→v5 マイグレーションの叩き台を追加する。
>   ```typescript
>   export function openDatabaseV5(): Promise<IDBDatabase> {
>     const req = indexedDB.open("UnifiedAgentIDE_DB", 5);
>     req.onupgradeneeded = (e) => {
>       const db = req.result; const oldVersion = (e as IDBVersionChangeEvent).oldVersion;
>       // v4までの処理は既存の openDatabase() と同一
>       if (oldVersion < 5) {
>         const prefStore = req.transaction!.objectStore("preferences");
>         // 既存の preferences レコードに maxReviseRetries を追加
>         // マイグレーション時は全レコードを走査し、maxReviseRetries ?? 3 を付与
>       }
>     };
>   }
>   ```
>   本番では `12_db-schema.md` の `openDatabase` を v5 に更新し、`14` の `GenAIClientConfig` と整合させる。

> 🆕 **詳細化補足（Phase 5・レビュー反映）— R9 snapshotsへのchecksum拡張**
> - **指摘元**: REVIEW_DESIGN.md R9
> - **内容**: `checksum` ライフサイクルは `files` だけでなく `snapshots` にも拡張する。`snapshots` 復元時は、復元対象の `files` 全てについて `checksum` を再計算し、不一致があれば「スナップショットが破損している可能性があります。復元しますか？」の確認ダイアログを出す。本追記により `12` の G12 補足は `files` と `snapshots` の両方をカバーする。

---

> **出典**: `Local_AI_Agent.md` §10（Lines 501-615）を一字一句維持して分割
> **相互参照**: [04_storage-persist.md](./04_storage-persist.md) | [10_logging-scribe.md](./10_logging-scribe.md) | [11_storage-export.md](./11_storage-export.md) | [03_security-byok.md](./03_security-byok.md) | [README.md](../README.md)
