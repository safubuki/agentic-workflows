# コンパイル時の落とし穴と回避策（gh aw compile）

`gh aw compile` は単なる変換ではなく、**検証とセキュリティ強化**を行います。新規作成時によく当たるポイントを、症状（出るメッセージ）ごとに整理します。スキルでワークフローを作る際は、**書く前にこれらを満たす**ようにします。

## 1. git リポジトリが必要

- 症状: `compile without arguments requires being in a git repository`
- 回避: リポジトリ直下で `git init` してから `gh aw compile`。

## 2. 式（expression）は許可リスト制

- 症状: `unauthorized expressions found`（例: `github.sha`）
- 原因: 本文・フロントマターで使える `${{ ... }}` は**限られている**。任意の context 式は使えない。
- 回避: 許可式に置き換える。よく使う対応:

| やりたいこと | 使う式 |
|-------------|--------|
| push の HEAD コミット | `github.event.head_commit.id` |
| PR 番号 | `github.event.pull_request.number` |
| Issue 番号 | `github.event.issue.number` |
| 手動入力 | `github.event.inputs.<名前>` |
| workflow_run の結果 | `github.event.workflow_run.conclusion` / `.id` / `.head_sha` / `.html_url` |
| リポジトリ / 実行者 / イベント | `github.repository` / `github.actor` / `github.event_name` |

> ❌ 使えない代表例: `github.sha`（→ `github.event.head_commit.id` を使う）

## 3. ツールセットに必要な権限を宣言する

- 症状: `Missing required permissions for GitHub toolsets`
- 原因: `tools: github:` を使うと、その操作に応じて `permissions` が要求される。
- 回避: 警告に出た権限を `permissions` に追加。`github` ツールを使うなら、まず次を入れておくと安全:

```yaml
permissions:
  contents: read
  issues: read
  pull-requests: read
```

## 4. 新規シークレットは承認が要る（safe update mode）

- 症状: `safe update mode detected unapproved changes` + `New restricted secret(s)`
- 原因: 新しいシークレット（例: `COPILOT_GITHUB_TOKEN`、`ANTHROPIC_API_KEY`）を使う設定を足すと、安全のため**承認待ち**になる（エラーではない）。
- 回避: 中身が正当（流出・サプライチェーン攻撃等でない）ことを確認のうえ `gh aw compile --approve`。

## 5. workflow_run は branches 制限を付ける

- 症状: `workflow_run trigger should include branch restrictions ...`
- 回避: 全ブランチで走らないよう `branches:` を付ける。

```yaml
on:
  workflow_run:
    workflows: ["*"]
    types: [completed]
    branches: [main]
```

## 6. 自動生成される agentics-maintenance.yml

- `expires` 付きの safe-output を使うと、`agentics-maintenance.yml` が**自動生成**される（対の `.md` は無い。正常）。
- 手で編集しない。不要なら `.github/workflows/aw.json` に `{"maintenance": false}`。

## チェックリスト（作成前に満たす）

- [ ] git リポジトリ内で作業しているか
- [ ] 使う式はすべて許可式か（`github.sha` 等を使っていないか）
- [ ] `tools: github:` を使うなら `permissions` に read を宣言したか
- [ ] `workflow_run` を使うなら `branches:` を付けたか
- [ ] 本文で使う safe-output をフロントマターで宣言したか
- [ ] 新規シークレットがあるなら `--approve` を案内するか
