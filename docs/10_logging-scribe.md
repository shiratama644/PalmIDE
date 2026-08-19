<!-- 元ファイル: Local_AI_Agent.md §8 Lines 416-482 -->
# 10 ログ仕様とScribe Agent

> **親ドキュメント**: [Local_AI_Agent.md](../uploads/Local_AI_Agent.md)
> **インデックス**: [README.md](../README.md) | [Phase0設計書](../PHASE0_design.md)
> **関連ファイル**: [12_db-schema.md](./12_db-schema.md)（snapshots/logs） | [07_model-caching-tier.md](./07_model-caching-tier.md)（ScribeはFlash-Lite/Flex） | [11_storage-export.md](./11_storage-export.md)（Zipバックアップにログ含む） | [README.md](../README.md)
> **元セクション**: §8（Lines 416-482）

> **要約**: 本ファイルはMutex Lock+WALによる非同期書き込み競合制御と、Frontmatter+Markdown構造化ログ（cost_estimate含む、パス .agent/logs/SEQ_YYYY-MM-DD_kebab-case.md）を定義する。

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


> ⚠️ **要人間判断（Phase 4で未解決）— G10 複数タブの競合**
> **→ 決定済み: 下記 `🆕（Phase 5・決定反映）` を参照（本⚠️は履歴として残存）**
> - **論点**: `ScribeMutex` はJSインスタンス内のメモリ排他のみで、複数タブで同時に `IndexedDB` に書き込むと競合し `logs` や `snapshots` が破損する可能性がある
> - **選択肢**:
>   - **A案（制約）**: 「単一タブでのみ利用」という制約を明記し、複数タブを開いた場合はトーストで警告（実装コスト最小）
>   - **B案（技術）**: `navigator.locks` API（`navigator.locks.request("scribe", ...)`) で跨タブ排他、または `BroadcastChannel` でリーダー選出
>   - **C案（楽観）**: IndexedDBの `put` を冪等にし、競合時は `seq` の大きい方を採用する楽観ロック
> - **影響**: Aは実装1行だがUX制約、B/Cは実装コスト増だが堅牢。**プロダクトが複数タブ利用を想定するかで人間が選択**すること。
> - **根拠**: `ScribeMutex` の `private locked` はタブ間で共有されないため、仕様書の「Mutex WAL」だけでは不十分。

> 🆕 **詳細化補足（Phase 4）— G15 コスト記録ライフサイクル**
> - **対象**: ログのコスト追跡（`cost_estimate`）の確定タイミング
> - **種別**: 🟡要確認の解消（参照）
> - **内容**: `cost_estimate` の計算式は [07_model-caching-tier.md](./07_model-caching-tier.md) の G15 補足と同一。Approval Gateでは `estimated_usd`（見積）、Scribeがログを確定する時点で `actual_usd`（確定）を再計算して記録する。`tier_used: "flex"|"priority"` に応じてレートを切り替える詳細は [14_shared-contracts.md](./14_shared-contracts.md) §4 を参照。
> - **根拠**: 見積と確定を分離することで、ユーザが承認前にコストを判断できるライフサイクルとするため。

> 🆕 **詳細化補足（Phase 5・決定反映）— G10 複数タブ競合**
> - **決定**: **B案 `navigator.locks`** を採用する。`ScribeMutex` に加え、跨タブ排他は `navigator.locks.request("scribe-wal", {mode:"exclusive"}, async () => { /* WAL書き込み */ })` で実現する。`locks` 非対応ブラウザでは `BroadcastChannel` によるフォールバックを検討。
> - **不採用案**:
>   - **A案 単一タブ制約**: 実装は1行だが、ユーザが誤って2タブ開いた際に警告だけでデータ損失リスクが残るため、MVPとしては弱い。
>   - **C案 楽観ロック**: 実装は可能だが、競合検出後のマージ処理が複雑で、本プロダクトの「1作業1ログ」には過剰。
> - **根拠**: Phase 5-0で G10 を B に決定。`navigator.locks` は Chrome 69+ で広く対応し、IndexedDBの競合をOSレベルで防げるため。コード雛形は `14_shared-contracts.md` §1 の排他ユーティリティを参照。

---

> **出典**: `Local_AI_Agent.md` §8（Lines 416-482）を一字一句維持して分割
> **相互参照**: [12_db-schema.md](./12_db-schema.md)（snapshots/logs） | [07_model-caching-tier.md](./07_model-caching-tier.md)（ScribeはFlash-Lite/Flex） | [11_storage-export.md](./11_storage-export.md)（Zipバックアップにログ含む） | [README.md](../README.md)
