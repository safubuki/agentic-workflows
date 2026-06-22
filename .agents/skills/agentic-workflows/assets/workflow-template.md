# ワークフロー作成テンプレート

`.github/workflows/<名前>.md` の雛形です。`{...}` を置き換えてください。

````markdown
---
name: {ワークフロー表示名}
description: {何をするワークフローか1行で}
on:
  workflow_dispatch:
    inputs:
      {入力名}:
        description: "{入力の説明}"
        type: {string | choice | boolean | number}
        # choice の場合:
        # options:
        #   - 選択肢A
        #   - 選択肢B
        # default: 選択肢A
        required: true

permissions:
  contents: read
  # github ツールを使うなら下記も宣言（不足はコンパイル警告）:
  # issues: read
  # pull-requests: read

engine:
  id: copilot
  model: claude-sonnet-4.6        # 採用4種から。実行時に切替: ${{ github.event.inputs.model }}
  max-turns: 20

tools:
  github:

safe-outputs:
  {使う出力タイプ}:                 # 例: add-comment / create-pull-request / add-labels
    max: 1
---

# {ワークフローのタイトル}

{AI への依頼の概要を1〜2文で}

## 入力

- {入力の説明}: `${{ github.event.inputs.{入力名} }}`
- リポジトリ: `${{ github.repository }}`

## 手順

### Step 1: {情報収集}
{githubツールで必要なデータを取得する指示}

### Step 2: {処理}
{AI が行う作業の指示}

### Step 3: {出力}
{safe-output を発行する指示。例: add-comment で結果を1件コメントする}

## 厳守事項

- safe-outputs は宣言済みのものだけ使う。
- {このワークフロー固有の禁止事項}
- 出力は日本語で記述する。
````

## チェックリスト

- [ ] `name` / `on` / `engine` / `permissions` がある
- [ ] 本文で使う safe-output をフロントマターで宣言した
- [ ] 入力参照 `${{ github.event.inputs.* }}` のスペルが一致
- [ ] 禁止事項・出力言語を明記した
- [ ] `gh aw compile` 後、`.md` と `.lock.yml` を両方コミットする
