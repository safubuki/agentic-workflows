---
name: Issue Triage
description: 新しく開かれた/再オープンされた Issue の内容を分析し、適切なラベルを付与してトリアージする
on:
  issues:
    types: [opened, reopened]
  workflow_dispatch:
    inputs:
      issue_number:
        description: "トリアージする Issue 番号（手動実行時）"
        type: string
        required: false

permissions:
  contents: read
  issues: read
  pull-requests: read

engine:
  id: copilot
  model: claude-sonnet-4.6
  max-turns: 20

tools:
  github:

safe-outputs:
  add-labels:
    # 既存ラベルから選んで付与する。許可パターンは運用に合わせて調整する
    allowed:
      - bug
      - enhancement
      - documentation
      - question
      - "good first issue"
      - "help wanted"
      - "area/*"
      - "priority/*"
    max: 3
  add-comment:
    max: 1
---

# Issue 自動トリアージ

新しく開かれた（または再オープンされた）Issue を分析し、**内容に最も合うラベルを付与**します。必要なら短いトリアージコメントを残します。

## 入力・コンテキスト

- 対象 Issue 番号: `${{ github.event.issue.number }}`（手動実行時は `${{ github.event.inputs.issue_number }}`）
- Issue タイトル: `${{ github.event.issue.title }}`
- リポジトリ: `${{ github.repository }}`

## 方針

1. **既存ラベルの体系を尊重**する。リポジトリに無いラベルを勝手に作らない。`add-labels` の許可リストにあるものだけを使う。
2. **過剰なラベル付けをしない**。本当に該当するものだけ（最大3つ）。
3. **断定できないときは付けない**。曖昧な場合はコメントで確認を促す。

## 手順

### Step 1: Issue 内容を取得する

1. `github` ツールで対象 Issue のタイトル・本文・既存ラベルを取得する。
2. 既にラベルが十分付いている場合は、過剰に追加しない。

### Step 2: 内容を分類する

Issue 本文から種別・領域・優先度を読み取る:

| 観点 | 判断材料 | 対応ラベル例 |
|------|---------|-------------|
| 種別 | バグ報告か機能要望か質問か | `bug` / `enhancement` / `question` / `documentation` |
| 着手しやすさ | 初心者向けか、協力募集か | `good first issue` / `help wanted` |
| 領域 | どのコンポーネントか | `area/*` |
| 優先度 | 緊急度・影響範囲 | `priority/*` |

### Step 3: ラベルを付与する

`add-labels` で該当ラベルを付与する（`type: add_labels`）。許可リストに無いラベルは使わない。

### Step 4: 必要ならコメントする

- 情報が不足している場合は、`add-comment` で**1件だけ**、不足情報（再現手順・期待動作・環境など）を丁寧に尋ねる。
- 十分な情報があり機械的にトリアージできた場合は、コメントは不要（または「自動トリアージ済み」の短い一文のみ）。

## 厳守事項

- 許可リストにあるラベルのみ使用する。
- 断定できないラベルは付けない。
- 出力は日本語で記述する。
