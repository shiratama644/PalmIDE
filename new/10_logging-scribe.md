<!-- 統合版: docs/10_logging-scribe.md の Phase 4〜5 追記（G10 複数タブ競合 / G15 コストライフサイクル）を本文にマージ（元: Local_AI_Agent.md §8 Lines 416-482） -->
# 10 ログ仕様とScribe Agent

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local%20AI%20Agent.md)（§8 Lines 416-482）
> **インデックス**: [README.md](./README.md)
> **関連ファイル**: [12_db-schema.md](./12_db-schema.md)（snapshots/logs） | [07_model-caching-tier.md](./07_model-caching-tier.md)（ScribeはFlash-Lite/Flex） | [11_storage-export.md](./11_storage-export.md)（Zipバックアップにログ含む） | [14_shared-contracts.md](./14_shared-contracts.md)（§4 コストレート）

> **要約**: 本ファイルはMutex Lock+WALによる非同期書き込み競合制御（タブ内は `ScribeMutex`、跨タブは `navigator.locks`）と、Frontmatter+Markdown構造化ログ（cost_estimate含む、パス `.agent/logs/SEQ_YYYY-MM-DD_kebab-case.md`）を定義する。

> **ナビゲーション**: ← [09_patch-engine.md](./09_patch-engine.md) | [11_storage-export.md](./11_storage-export.md) →

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

### 8.1.1 複数タブ間の排他制御

`ScribeMutex` だけでは JS インスタンス内のメモリ排他のみであり、複数タブで同時に IndexedDB へ書き込むと `logs` や `snapshots` が破損しうる。跨タブ排他は **`navigator.locks` API** で実現する。

```typescript
navigator.locks.request("scribe-wal", { mode: "exclusive" }, async () => {
  /* WAL書き込み */
});
```

`navigator.locks` 非対応ブラウザでは `BroadcastChannel` によるフォールバックを検討する。単一タブ制約（警告のみ）では、ユーザーが誤って2タブ開いた際のデータ損失リスクが残るため採用しない。`navigator.locks` は Chrome 69+ で広く対応し、IndexedDB の競合をOSレベルで防げる。排他ユーティリティのコード雛形は [14_shared-contracts.md](./14_shared-contracts.md) §1 を参照。

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

### 8.2.1 コスト記録ライフサイクル

`cost_estimate` の計算式は [07_model-caching-tier.md](./07_model-caching-tier.md) §5.6 と同一である。ライフサイクルとして、Approval Gate では見積（`estimated_usd`）を表示し、Scribe がログを確定する時点で確定値（`actual_usd`）を再計算して記録する。見積と確定を分離することで、ユーザーが承認前にコストを判断できる。`tier_used: "flex" | "priority"` に応じてレートを切り替える詳細は [14_shared-contracts.md](./14_shared-contracts.md) §4 を参照。

---

> **出典**: `Local_AI_Agent.md` §8（Lines 416-482）。複数タブ排他（G10決定）とコストライフサイクル（G15）を本文に統合した統合版である。
> **相互参照**: [12_db-schema.md](./12_db-schema.md)（snapshots/logs） | [07_model-caching-tier.md](./07_model-caching-tier.md)（ScribeはFlash-Lite/Flex） | [11_storage-export.md](./11_storage-export.md)（Zipバックアップにログ含む） | [README.md](./README.md)
