# 例: README 自動更新ワークフロー

要件「ファイル更新時に、変更内容に応じた粒度で、既存 README の書き方に合わせて README を最適更新」を満たす実例です。

完全な実装は本リポジトリの実ファイルにあります:

📄 **[.github/workflows/auto-readme-update.md](../../../../.github/workflows/auto-readme-update.md)**

## フロントマターの要点

```yaml
on:
  push:
    branches: [main]
    paths-ignore:                 # 無限ループ・無関係変更を除外
      - "**/*.lock.yml"
      - "docs/**"
      - ".github/skills/**"
  workflow_dispatch:
engine: { id: copilot, model: claude-sonnet-4.6 }
safe-outputs:
  create-pull-request:            # 直接 push せず PR 提案
    title-prefix: "[docs] "
    labels: [documentation, automated]
    max: 1
```

## 設計のキモ

| 要件 | 実装 |
|------|------|
| ファイル更新で自動起動 | `on: push` + `paths-ignore` で対象外を除外 |
| 適切な粒度 | 変更を分類し、README 反映が必要なものだけ最小差分で反映 |
| 既存 README の書き方に合わせる | 先に既存 README を読み、言語・トーン・見出し構成・粒度を学習してから更新 |
| 安全に更新 | `create-pull-request` で PR 提案（直接 push しない） |
| 過剰更新の防止 | 内部実装・テストのみなど README に無関係なら何もしない |

## 学べるパターン

- **push トリガー + paths-ignore** で自動起動しつつループを防ぐ書き方
- **既存スタイルを学習してから書く**指示の与え方（AI に体裁を勝手に変えさせない）
- 書き込みを **PR 提案**にして人間レビューを挟む安全設計
