---
name: CI Doctor
description: CI/ビルドのワークフローが失敗したとき、原因を自動調査して原因と修正方針を Issue で報告する
on:
  workflow_run:
    workflows: ["*"]
    types: [completed]
    branches: [main]
  workflow_dispatch:
    inputs:
      run_id:
        description: "調査する失敗 run の ID（手動実行時）"
        type: string
        required: false

permissions:
  contents: read
  actions: read
  issues: read
  pull-requests: read

engine:
  id: copilot
  model: gpt-5.3-codex
  max-turns: 30

tools:
  github:

safe-outputs:
  create-issue:
    title-prefix: "[ci-doctor] "
    labels: [ci-failure, automated]
    max: 1
---

# CI Doctor — CI 失敗の自動原因調査

CI/ビルドのワークフローが失敗したとき、ログを調べて**失敗の原因と修正方針**を Issue で報告します。コード調査が中心のため、コーディングに強いモデル（GPT-5.3 Codex）を既定にしています。

## 入力・コンテキスト

- 対象 run: `${{ github.event.workflow_run.id }}`（手動実行時は `${{ github.event.inputs.run_id }}`）
- ワークフロー結果: `${{ github.event.workflow_run.conclusion }}`
- ログ URL: `${{ github.event.workflow_run.html_url }}`
- 対象コミット: `${{ github.event.workflow_run.head_sha }}`
- リポジトリ: `${{ github.repository }}`

## 早期終了の条件

- `${{ github.event.workflow_run.conclusion }}` が `failure` 以外（success / cancelled 等）の場合は、**何もせず終了**する。
- 自分自身（このワークフロー）や他の agentic ワークフローの失敗をループ調査しないよう、対象が無関係なら終了する。

## 手順

### Step 1: 失敗 run の情報を取得する

1. `github` ツールで対象 run のジョブ・ステップ・**失敗ログ**を取得する。
2. どのジョブ・ステップで失敗したかを特定する。

### Step 2: 原因を分析する

ログから根本原因を切り分ける:

| 兆候 | 想定原因 |
|------|---------|
| コンパイル/型エラー | コード変更の不整合 |
| テスト失敗 | ロジック不具合・期待値ズレ・フレーキー |
| 依存解決エラー | パッケージ/ロックファイルの不整合 |
| タイムアウト/OOM | リソース不足・無限ループ |
| 権限/シークレット | 設定不足 |

該当コミット `${{ github.event.workflow_run.head_sha }}` の変更内容も参照して、原因の当たりをつける。

### Step 3: Issue で報告する

`create-issue` で**1件**の調査レポートを作成する（`type: create_issue`）。

```
## 🩺 CI 失敗の調査レポート

- 失敗ワークフロー: {ワークフロー名} / run #{run_number}
- 結果: {conclusion}
- ログ: {html_url}

### 失敗箇所
{ジョブ・ステップ・該当ログの要点}

### 推定原因
{根本原因の説明}

### 修正方針
1. {具体的な修正案}
2. {代替案や確認事項}

### 補足
{フレーキーの可能性、再実行で直る可能性など}
```

## 厳守事項

- `failure` 以外では Issue を作らない（ノイズ防止）。
- 同じ失敗で重複 Issue を量産しない（既存の `[ci-doctor]` Issue があれば参照・更新を優先）。
- safe-outputs は宣言済みのもの（`create-issue`）のみ使う。
- 出力は日本語で記述する。
