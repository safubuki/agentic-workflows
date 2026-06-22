# 例: PR レビューワークフロー

要件「指定 PR を選んだ AI モデルでレビュー、回数カウント（既定3回）、同一観点で再レビューして指摘を収束」を満たす実例です。

完全な実装は本リポジトリの実ファイルにあります:

📄 **[.github/workflows/pr-ai-review.md](../../../../.github/workflows/pr-ai-review.md)**

## フロントマターの要点

```yaml
on:
  workflow_dispatch:
    inputs:
      pr_number: { type: string, required: true }
      model:
        type: choice
        options: [claude-sonnet-4.6, gpt-5.4, gpt-5.3-codex, claude-haiku-4.5]
        default: claude-sonnet-4.6
      max_reviews:
        type: choice
        options: ["1", "2", "3"]
        default: "3"
engine:
  id: copilot
  model: ${{ github.event.inputs.model }}   # ← 入力でモデルを切替
safe-outputs:
  add-comment: { max: 1, target: "*" }       # 結果コメント
  add-labels:                                 # 回数カウンタ
    allowed: [ai-review-1, ai-review-2, ai-review-3, ai-review-done]
    max: 1
```

## 設計のキモ

| 要件 | 実装 |
|------|------|
| モデルを選択肢で指定 | `model` を `type: choice` → `engine.model` に式で渡す |
| 回数カウント | ラベル `ai-review-N` で永続化。実行時にラベルから N を判定 |
| 規定回数で完了 | N==MAX でコメントに「完了→人間の最終確認へ」を明記 |
| 同一観点で再レビュー | 固定5観点（正しさ/設計/セキュリティ/性能/保守性）だけ使用、新観点追加を禁止 |
| 指摘を収束 | 前回コメントを読み戻し、解消済みは消す・水増ししない・件数が減る |

## 学べるパターン

- **入力でエンジンのモデルを動的切替**する書き方
- **ラベル＋過去コメント**による状態永続化（[state-persistence-patterns.md](../references/state-persistence-patterns.md)）
- 本文で**観点固定・水増し禁止**を明示して AI の振る舞いを制御する書き方
