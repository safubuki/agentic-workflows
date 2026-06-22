---
name: agentic-workflows-generator
description: GitHub Agentic Workflows（gh-aw）を生成・更新・コンパイル・解説・セットアップ支援する生成スキル。Markdown のワークフロー定義（フロントマター+本文）から AI 実行可能な GitHub Actions（.lock.yml）を生成する。新規生成・既存更新・`gh aw compile` 補助・フロントマター/safe-outputs/エンジン/モデル/認証の解説・現状ワークフローの説明に対応。会社（組織）か個人かなど判断が分かれる箇所は推測せずユーザーに確認・選択させる。「Agentic Workflowを作って」「ワークフロー作成」「ワークフロー生成」「gh-aw」「gh aw」「エージェントワークフロー」「AIワークフロー」「ワークフロー更新」「ワークフローをコンパイル」「workflow_dispatch」「safe-outputs」「frontmatter」「lock.yml」「gh aw セットアップ」「copilot-requests」などで発火。
---

# Agentic Workflows Generator — gh-aw の生成・更新・コンパイル・解説・セットアップ

## スキル読み込み通知

このスキルが読み込まれたら、必ず以下の通知をユーザーに表示してください：

> 🤖 **Agentic Workflows Generator スキルを読み込みました**  
> GitHub Agentic Workflows（gh-aw）の生成・更新・コンパイル・解説・セットアップを支援します。判断が分かれる箇所では確認させていただきます。

## When to Use

- 新しい Agentic Workflow を作りたいとき（「PR をレビューするワークフローを作って」など）
- 既存のワークフローを更新・修正したいとき
- ワークフローのコンパイル（`gh aw compile` → `.lock.yml`）を行いたいとき
- gh / gh aw のセットアップ・認証（組織 or 個人）でつまずいたとき
- フロントマター・safe-outputs・エンジン/モデル・認証設定の書き方が分からないとき
- 現状リポジトリにある Agentic Workflow の内容を説明してほしいとき
- 「こんな自動化を Actions × AI でやりたい」と漠然と相談したいとき

## 概要

GitHub Agentic Workflows は、**自然言語（Markdown）で書いた指示を AI エージェントが GitHub Actions 上で実行する仕組み**です。
`.github/workflows/<名前>.md` に **フロントマター（YAML 設定）** と **本文（自然言語の指示）** を書き、`gh aw compile` でコンパイルすると、堅牢化された GitHub Actions ワークフロー `.lock.yml` が生成されます。

このスキルは6つのモードで動作します。

| モード | 説明 | トリガー例 |
|--------|------|-----------|
| 🔨 **Create** | 新しいワークフローを生成 | 「〜するワークフローを作って」 |
| ✏️ **Update** | 既存ワークフローを更新 | 「このワークフローに〜を追加して」 |
| ⚙️ **Compile** | コンパイル（.lock.yml 生成）を支援 | 「コンパイルして」「lock を更新」 |
| 📖 **Explain** | 仕組み・記法を解説 | 「safe-outputs って何」「frontmatter の書き方」 |
| 🔍 **Describe** | 現状のワークフロー内容を説明 | 「今あるワークフローを説明して」 |
| 🧰 **Setup** | gh / gh aw 導入・認証の支援 | 「gh aw を入れたい」「認証どうする」 |

> 📚 まず仕様を確認すべきときは、リポジトリの [docs/](../../../docs/) のマニュアル（`docs/01`〜`docs/06`、`docs/references/`）を参照してください。本スキルの `references/` はその要点を凝縮したものです。

---

## ⚠️ 判断確認の原則（全モード共通・最重要）

このスキルは、**判断が分かれる箇所では推測で進めず、必ずユーザーに確認・選択させます**。
特に **会社（組織）で使うのか／個人で使うのか**で正解が変わる項目（認証方式・課金・シークレット運用など）は、勝手に決めてはいけません。

確認すべき分岐点の一覧・各選択肢・推奨デフォルトは以下を参照：

📄 **[references/decision-points.md](references/decision-points.md)**

運用ルール：

1. 分岐点に来たら、`references/decision-points.md` の該当項目の**選択肢を提示して質問**する（推奨があれば「推奨」と明示）。
2. ユーザーが選んだら、その選択に沿って続行する。**選択を勝手に変えない**。
3. 一度確認した内容（例: 「組織利用」）は、同じセッション内では繰り返し聞かない。
4. 破壊的・外向きの操作（シークレット登録、`workflow disable/enable`、push 等）は、実行前に確認する。

> 💡 代表例: 「Copilot の認証どうする？」と聞かれたら、**組織なら `copilot-requests: write`（シークレット不要・推奨）／個人なら `COPILOT_GITHUB_TOKEN`** の2択を提示し、どちらの利用形態かを確認してから進める。

---

## Mode 1: Create — 新規ワークフロー作成

### Step 1: 要件のヒアリング

ユーザーから以下を確認する（不明な点は推測せず質問する）。**判断が分かれる項目は [references/decision-points.md](references/decision-points.md) に従って選択肢を提示して確認する。**

1. **目的**: 何を自動化したいか（PR レビュー、Issue トリアージ、README 更新など）
2. **利用形態（会社/組織 か 個人 か）**: 認証・課金・シークレット運用が変わるため**必ず確認**（→ [decision-points.md](references/decision-points.md) §1）
3. **トリガー**: いつ起動するか（手動 `workflow_dispatch` / `push` / `pull_request` / `issues` / `schedule`）。`schedule` は放置で動くため自動実行の是非も確認（§3）
4. **入力**: 手動実行なら、どの入力（PR 番号・モデル選択・回数など）が必要か
5. **エンジン・モデル**: 既定は `engine: copilot`。モデルは採用4種から用途に応じて選ぶ（固定 or 選択も確認 → §2、[model-policy.md](references/model-policy.md)）
6. **書き込み**: AI に何をさせるか（コメント投稿・PR 作成・ラベル付与など → safe-outputs を選定。変更系は PR 提案が安全 → §4）
7. **状態の永続化**: 実行間でカウントや前回結果を持ち越す必要があるか（→ §5、ラベル/コメント/Issue を使う）

> 💡 各分岐で迷ったら、決め打ちせず「A/B どちらにしますか？（推奨: …）」と聞く。一度確認した内容は同一セッションで繰り返し聞かない。

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
| 「認証はどうする / 組織と個人の違い / `copilot-requests`」 | [references/auth-and-secrets.md](references/auth-and-secrets.md) |
| 「`gh auth login` 済みなのにシークレットが要るのはなぜ」 | [references/auth-and-secrets.md](references/auth-and-secrets.md)（2レイヤー） |
| 「回数カウント・状態の持ち方」 | [references/state-persistence-patterns.md](references/state-persistence-patterns.md) |
| 「コンパイルでエラー/警告が出る」 | [references/compile-pitfalls.md](references/compile-pitfalls.md) |
| 「gh / gh aw のセットアップ」 | [references/setup-guide.md](references/setup-guide.md) |
| 「gh aw コマンド」 | [references/cli-commands.md](references/cli-commands.md) |

回答は簡潔に、必要なら最小の YAML 例を添える。**判断が分かれる質問（認証など）には、決め打ちで答えず選択肢を提示**する（[decision-points.md](references/decision-points.md)）。深掘りが必要なら該当ドキュメントへ誘導する。

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

## Mode 6: Setup — gh / gh aw 導入・認証支援

### 手順

1. 現状を確認する（`gh --version` / `gh auth status` / `gh aw version`）。何が未導入かを切り分ける。
2. 不足している段階から順に案内する（gh 本体 → ローカル認証 → gh aw 拡張 → エンジン認証）。詳細は：

   📄 **[references/setup-guide.md](references/setup-guide.md)**

3. **エンジン認証は組織/個人で分岐するため必ず確認**する（[references/decision-points.md](references/decision-points.md) §1）。
4. `gh auth login`（対話的）や `gh secret set`（トークン入力）は**ユーザー自身に実行してもらう**。トークンはチャットに出させない。
5. 「ローカル認証」と「エンジン認証（シークレット/権限）」は別物である点を必ず伝える（[references/auth-and-secrets.md](references/auth-and-secrets.md)）。

---

## 厳守事項（全モード共通）

- **判断が分かれる箇所は推測で進めず確認する**（特に会社/組織 か 個人 か → [references/decision-points.md](references/decision-points.md)）。
- `.md` 編集後は**必ず再コンパイル**し、`.md` と `.lock.yml` を両方コミットする。
- AI の書き込みは**宣言済みの safe-outputs のみ**。本文で使うものは必ずフロントマターに宣言する。
- 最小権限を守る（`permissions` は読み取り中心。ただし `github` ツールに必要な read は宣言する）。
- 既存ワークフローのスタイル・出力言語を勝手に変えない。
- エンジンは `copilot`、モデルは採用4種（`claude-sonnet-4.6` / `gpt-5.4` / `gpt-5.3-codex` / `claude-haiku-4.5`）から選ぶ。
- 複数人開発で**個人トークンを共有シークレットに入れない**（[references/auth-and-secrets.md](references/auth-and-secrets.md)）。
- 破壊的・外向きの操作（シークレット登録・`workflow disable/enable`・push 等）は実行前に確認する。

## 参照ドキュメント

| ドキュメント | 内容 |
|-------------|------|
| [references/decision-points.md](references/decision-points.md) | **判断確認ポイント一覧**（会社/個人など、ユーザーに選ばせる箇所） |
| [assets/workflow-template.md](assets/workflow-template.md) | ワークフロー `.md` の作成テンプレート |
| [references/frontmatter-reference.md](references/frontmatter-reference.md) | フロントマター全項目・エンジン・トリガー早見表 |
| [references/safe-outputs-reference.md](references/safe-outputs-reference.md) | safe-outputs の種類と書き方 |
| [references/model-policy.md](references/model-policy.md) | 採用モデル（Copilot エンジン・4種）と指定方法 |
| [references/auth-and-secrets.md](references/auth-and-secrets.md) | 認証2レイヤー・組織/個人の認証・シークレット運用 |
| [references/setup-guide.md](references/setup-guide.md) | gh / gh aw 導入・認証のセットアップ手順 |
| [references/state-persistence-patterns.md](references/state-persistence-patterns.md) | 回数カウント・前回結果引き継ぎ等の状態永続化パターン |
| [references/compile-pitfalls.md](references/compile-pitfalls.md) | コンパイル検証の落とし穴と回避策（許可式・権限・承認・自動生成） |
| [references/cli-commands.md](references/cli-commands.md) | `gh aw` CLI コマンドリファレンス |
| [examples/pr-review-workflow.md](examples/pr-review-workflow.md) | PR レビューワークフローの完全な例 |
| [examples/readme-update-workflow.md](examples/readme-update-workflow.md) | README 自動更新ワークフローの完全な例 |
| [examples/event-triggered-workflows.md](examples/event-triggered-workflows.md) | Issue トリアージ / CI Doctor / Daily レポートの例 |
| [docs/](../../../docs/) | リポジトリの利用手順書・マニュアル |
