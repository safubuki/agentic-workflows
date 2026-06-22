---
name: agentic-workflows
description: GitHub Agentic Workflows（gh-aw）を作成・更新・コンパイル・解説する汎用スキル。Markdown で書いたワークフロー定義（フロントマター+本文）から、AI が実行可能な GitHub Actions（.lock.yml）を生成する仕組みを支援する。新規ワークフロー作成、既存ワークフローの更新、`gh aw compile` 補助、フロントマター/safe-outputs/エンジン設定の解説、現状のワークフロー内容の説明に対応。「Agentic Workflowを作って」「ワークフロー作成」「gh-aw」「gh aw」「エージェントワークフロー」「AIワークフロー」「ワークフロー更新」「ワークフローをコンパイル」「ワークフローを解説」「workflow_dispatch」「safe-outputs」「frontmatter」「lock.yml」「agentic workflow」などで発火。
---

# Agentic Workflows スキル — gh-aw の作成・更新・コンパイル・解説

## スキル読み込み通知

このスキルが読み込まれたら、必ず以下の通知をユーザーに表示してください：

> 🤖 **Agentic Workflows スキルを読み込みました**  
> GitHub Agentic Workflows（gh-aw）の作成・更新・コンパイル・解説を行います。

## When to Use

- 新しい Agentic Workflow を作りたいとき（「PR をレビューするワークフローを作って」など）
- 既存のワークフローを更新・修正したいとき
- ワークフローのコンパイル（`gh aw compile` → `.lock.yml`）を行いたいとき
- フロントマター・safe-outputs・エンジン設定・トリガーの書き方が分からないとき
- 現状リポジトリにある Agentic Workflow の内容を説明してほしいとき
- 「こんな自動化を Actions × AI でやりたい」と漠然と相談したいとき

## 概要

GitHub Agentic Workflows は、**自然言語（Markdown）で書いた指示を AI エージェントが GitHub Actions 上で実行する仕組み**です。
`.github/workflows/<名前>.md` に **フロントマター（YAML 設定）** と **本文（自然言語の指示）** を書き、`gh aw compile` でコンパイルすると、堅牢化された GitHub Actions ワークフロー `.lock.yml` が生成されます。

このスキルは5つのモードで動作します。

| モード | 説明 | トリガー例 |
|--------|------|-----------|
| 🔨 **Create** | 新しいワークフローを作成 | 「〜するワークフローを作って」 |
| ✏️ **Update** | 既存ワークフローを更新 | 「このワークフローに〜を追加して」 |
| ⚙️ **Compile** | コンパイル（.lock.yml 生成）を支援 | 「コンパイルして」「lock を更新」 |
| 📖 **Explain** | 仕組み・記法を解説 | 「safe-outputs って何」「frontmatter の書き方」 |
| 🔍 **Describe** | 現状のワークフロー内容を説明 | 「今あるワークフローを説明して」 |

> 📚 まず仕様を確認すべきときは、リポジトリの [docs/](../../../docs/) のマニュアル（`docs/01`〜`docs/06`）を参照してください。本スキルの `references/` はその要点を凝縮したものです。

---

## Mode 1: Create — 新規ワークフロー作成

### Step 1: 要件のヒアリング

ユーザーから以下を確認する（不明な点は推測せず質問する）。

1. **目的**: 何を自動化したいか（PR レビュー、Issue トリアージ、README 更新など）
2. **トリガー**: いつ起動するか（手動 `workflow_dispatch` / `push` / `pull_request` / `issues` / `schedule`）
3. **入力**: 手動実行なら、どの入力（PR 番号・モデル選択・回数など）が必要か
4. **エンジン・モデル**: 既定は `engine: copilot`。モデルは採用4種（`claude-sonnet-4.6` / `gpt-5.4` / `gpt-5.3-codex` / `claude-haiku-4.5`）から用途に応じて選ぶ（→ [references/model-policy.md](references/model-policy.md)）
5. **書き込み**: AI に何をさせるか（コメント投稿・PR 作成・ラベル付与など → safe-outputs を選定）
6. **状態の永続化**: 実行間でカウントや前回結果を持ち越す必要があるか（→ ラベル/コメント/Issue を使う）

### Step 2: フロントマターの設計

各フィールドの早見表・選択肢は以下を参照：

📄 **[references/frontmatter-reference.md](references/frontmatter-reference.md)**

設計の要点：

- **エンジンは `copilot`、モデルは採用4種から**: 既定は `engine: id: copilot` / `model: claude-sonnet-4.6`。選択肢は `claude-sonnet-4.6` / `gpt-5.4` / `gpt-5.3-codex` / `claude-haiku-4.5`（→ [references/model-policy.md](references/model-policy.md)）
- **最小権限だが github ツールに必要な read は宣言**: `tools: github:` を使うなら `permissions` に `contents/issues/pull-requests: read` を入れる（不足はコンパイル警告になる）
- **入力は choice を活用**: モデル選択・回数などは `type: choice` + `options` + `default`
- **本文での参照は許可式のみ**: 入力は `${{ github.event.inputs.<名前> }}`、PR 番号は `${{ github.event.pull_request.number }}`。`github.sha` 等の非許可式は使わない（→ [references/compile-pitfalls.md](references/compile-pitfalls.md)）
- **safe-outputs は許可リスト**: 宣言したものだけ AI が実行できる

> ⚠️ **作成前に必読**: コンパイル検証でよく当たる落とし穴（許可式・必要権限・新規シークレット承認・workflow_run の branches 制限・自動生成される `agentics-maintenance.yml`）を先に潰しておくと一発で通る：
>
> 📄 **[references/compile-pitfalls.md](references/compile-pitfalls.md)**

safe-outputs の種類と書き方は以下を参照：

📄 **[references/safe-outputs-reference.md](references/safe-outputs-reference.md)**

### Step 3: 本文（指示）の作成

雛形は以下を参照：

📄 **[assets/workflow-template.md](assets/workflow-template.md)**

本文作成のルール：

1. **手順を Step で構造化**し、AI がやるべきことを明確にする
2. **safe-outputs の発行**を明示する（例: 「`add-comment` で結果をコメントせよ」）
3. **禁止事項を明記**する（観点を増やさない、水増ししない、直接 push しないなど）
4. 出力言語を指定する（本リポジトリは日本語）

> 💡 状態の永続化（カウント・前回結果の引き継ぎ）が必要なら、設計パターンを以下で確認：
>
> 📄 **[references/state-persistence-patterns.md](references/state-persistence-patterns.md)**

### Step 4: コンパイルとコミット

Mode 3（Compile）に従ってコンパイルし、**`.md` と `.lock.yml` を両方**コミットする。

### Step 5: 品質チェック

- [ ] `name` / `on` / `engine` / `permissions` が揃っているか
- [ ] 本文で使う safe-output がすべてフロントマターで宣言されているか
- [ ] 入力参照 `${{ github.event.inputs.* }}` のスペルが一致しているか
- [ ] `gh aw compile` が通るか（または通る前提で記述が妥当か）
- [ ] 禁止事項・出力言語が明記されているか

完全な作成例（PR レビュー・README 更新）は以下を参照：

📄 **[examples/pr-review-workflow.md](examples/pr-review-workflow.md)**
📄 **[examples/readme-update-workflow.md](examples/readme-update-workflow.md)**

---

## Mode 2: Update — 既存ワークフロー更新

### Step 1: 対象の読み込み

1. `.github/workflows/` 内の対象 `.md` を読み込む。
2. 対応する `.lock.yml` の有無を確認する（古ければ再コンパイルが必要）。
3. 変更要望を、フロントマター変更／本文変更／safe-outputs 追加のどれかに分類する。

### Step 2: 変更の実施

- **既存スタイルを踏襲**する（見出し構成・トーン・Step の粒度）。
- 新しい safe-output を本文で使う場合は、**フロントマターの宣言を必ず追加**する。
- 既存の禁止事項・出力言語を壊さない。

### Step 3: 再コンパイル（必須）

`.md` を変更したら**必ず** Mode 3 で再コンパイルし、`.lock.yml` を更新してから両方コミットする。

> ⚠️ `.lock.yml` を更新し忘れると、変更が Actions に反映されない。

---

## Mode 3: Compile — コンパイル支援

### 手順

1. `gh aw` がインストール済みか確認する：

   ```bash
   gh aw --help
   ```

   未インストールなら案内する：

   ```bash
   gh extension install github/gh-aw
   gh aw init
   ```

2. コンパイルを実行する（git リポジトリ内であること）：

   ```bash
   gh aw compile
   ```

   `.github/workflows/<名前>.lock.yml` が生成・更新される。新規シークレットを使う設定があると承認待ちになるため、その場合は内容を確認のうえ `gh aw compile --approve` を使う。

3. 失敗・警告が出た場合は、症状別に対処する（許可式・必要権限・workflow_run の branches・新規シークレット承認など）：

   📄 **[references/compile-pitfalls.md](references/compile-pitfalls.md)**

4. `.md` と `.lock.yml`（および自動生成された `agentics-maintenance.yml` があればそれも）を両方コミットするよう案内する。

> ℹ️ 環境に `gh aw` が無い場合は、コンパイルは実行できない旨を伝え、`.md` の記述が正しいことを確認した上で、ユーザーの環境で `gh aw compile` を実行してもらう。

CLI コマンドの詳細は以下を参照：

📄 **[references/cli-commands.md](references/cli-commands.md)**

---

## Mode 4: Explain — 仕組み・記法の解説

ユーザーの質問に応じて、該当リファレンスを参照しながら解説する。

| 質問の例 | 参照先 |
|---------|--------|
| 「Agentic Workflow って何」 | [docs/01-agentic-workflows-とは.md](../../../docs/01-agentic-workflows-とは.md) |
| 「frontmatter の書き方」 | [references/frontmatter-reference.md](references/frontmatter-reference.md) |
| 「safe-outputs とは / 一覧」 | [references/safe-outputs-reference.md](references/safe-outputs-reference.md) |
| 「エンジン・モデルの指定方法 / どのモデルを使う」 | [references/model-policy.md](references/model-policy.md) |
| 「回数カウント・状態の持ち方」 | [references/state-persistence-patterns.md](references/state-persistence-patterns.md) |
| 「コンパイルでエラー/警告が出る」 | [references/compile-pitfalls.md](references/compile-pitfalls.md) |
| 「gh aw コマンド」 | [references/cli-commands.md](references/cli-commands.md) |

回答は簡潔に、必要なら最小の YAML 例を添える。深掘りが必要なら該当ドキュメントへ誘導する。

---

## Mode 5: Describe — 現状ワークフローの説明

### 手順

1. `.github/workflows/*.md` を列挙し、各ファイルのフロントマターと本文を読む。
2. 各ワークフローについて以下をまとめて報告する：
   - **名前 / トリガー / エンジン**
   - **入力パラメータ**（workflow_dispatch の場合）
   - **何をするか**（本文の要約）
   - **safe-outputs**（どんな書き込みをするか）
   - **`.lock.yml` の有無**（コンパイル済みか）
3. 一覧表＋各ワークフローの短い説明で提示する。

---

## 厳守事項（全モード共通）

- `.md` 編集後は**必ず再コンパイル**し、`.md` と `.lock.yml` を両方コミットする。
- AI の書き込みは**宣言済みの safe-outputs のみ**。本文で使うものは必ずフロントマターに宣言する。
- 最小権限を守る（`permissions` は読み取り中心。ただし `github` ツールに必要な read は宣言する）。
- 既存ワークフローのスタイル・出力言語を勝手に変えない。
- エンジンは `copilot`、モデルは採用4種（`claude-sonnet-4.6` / `gpt-5.4` / `gpt-5.3-codex` / `claude-haiku-4.5`）から選ぶ。

## 参照ドキュメント

| ドキュメント | 内容 |
|-------------|------|
| [assets/workflow-template.md](assets/workflow-template.md) | ワークフロー `.md` の作成テンプレート |
| [references/frontmatter-reference.md](references/frontmatter-reference.md) | フロントマター全項目・エンジン・トリガー早見表 |
| [references/safe-outputs-reference.md](references/safe-outputs-reference.md) | safe-outputs の種類と書き方 |
| [references/model-policy.md](references/model-policy.md) | 採用モデル（Copilot エンジン・4種）と指定方法 |
| [references/state-persistence-patterns.md](references/state-persistence-patterns.md) | 回数カウント・前回結果引き継ぎ等の状態永続化パターン |
| [references/compile-pitfalls.md](references/compile-pitfalls.md) | コンパイル検証の落とし穴と回避策（許可式・権限・承認・自動生成） |
| [references/cli-commands.md](references/cli-commands.md) | `gh aw` CLI コマンドリファレンス |
| [examples/pr-review-workflow.md](examples/pr-review-workflow.md) | PR レビューワークフローの完全な例 |
| [examples/readme-update-workflow.md](examples/readme-update-workflow.md) | README 自動更新ワークフローの完全な例 |
| [examples/event-triggered-workflows.md](examples/event-triggered-workflows.md) | Issue トリアージ / CI Doctor / Daily レポートの例 |
| [docs/](../../../docs/) | リポジトリの利用手順書・マニュアル |
