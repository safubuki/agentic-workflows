# GitHub 認証ガイド（gh auth login の意味と方式の違い）

`gh aw` を使うには GitHub への認証が必要です。このドキュメントは **各手順が何をしているのか**と、**ブラウザ方式と PAT（自分でトークンを取る）方式の違い**を解説します。

> ⚠️ **最初に押さえる：認証は「2つのレイヤー」がある（別物）**
>
> | | `gh auth login`（このガイドの主題） | `COPILOT_GITHUB_TOKEN`（シークレット） |
> |---|---|---|
> | 誰が認証する | **あなたのPCの `gh` コマンド** | **GitHub Actions のランナー（クラウド）** |
> | 置き場所 | あなたのPCの keyring（ローカル） | **リポジトリのシークレット**（GitHub 上） |
> | 何に使う | ローカルから `gh` で操作（push / secret set / compile） | ワークフロー実行中に **AI が Copilot を呼ぶ** |
>
> **`gh auth login` でブラウザ方式の認証を済ませても、`COPILOT_GITHUB_TOKEN` は別途必要**です。ローカルのトークンはクラウドのランナーから見えないためです。本ガイドの「ブラウザ方式 vs PAT 方式」は**左側（ローカル `gh` 認証）の中の選択肢**であって、右側（Actions 用シークレット）の話ではありません。
> Copilot シークレットの取得・登録は [02-セットアップ.md](../02-セットアップ.md) を参照。

## なぜ認証が必要か

`gh`（および `gh aw`）は、あなたの代わりに GitHub API を叩きます。具体的には次のような操作に認証情報（トークン）が要ります。

- `gh extension install github/gh-aw` … 拡張の取得
- `gh aw run` / `gh aw compile` 後の push … ワークフローの実行・反映
- `gh secret set` … リポジトリへのシークレット登録

認証すると、`gh` は**アクセストークン**を取得し、OS の安全な保管領域（Windows は資格情報マネージャー/keyring）に保存します。以降のコマンドはこのトークンを自動で使います。

## gh auth login の対話プロンプトの意味

`gh auth login` を実行すると順に聞かれます。それぞれの意味は次の通り。

| 質問 | 選ぶもの | 意味 |
|------|---------|------|
| What account do you want to log into? | **GitHub.com** | 通常はこれ。GitHub Enterprise Server を使う組織だけ別ホストを選ぶ |
| What is your preferred protocol for Git operations? | **HTTPS**（推奨） | `git push` 等を HTTPS で行う。SSH 鍵を使いたい人は SSH |
| Authenticate Git with your GitHub credentials? | **Yes** | `git` の認証も `gh` のトークンに任せる（資格情報ヘルパー設定） |
| How would you like to authenticate? | **ブラウザ** または **トークン貼り付け** | ここが方式の分かれ目（下記） |

## 方式A: ブラウザでログイン（Login with a web browser）

`gh` が**自動でトークンを発行・管理**してくれる、最も手軽な方式です。

### 流れ

1. `gh auth login` →「Login with a web browser」を選ぶ
2. ターミナルに **8桁のワンタイムコード**（例: `ABCD-1234`）が表示される
3. Enter でブラウザが開く（または表示された URL を手動で開く）
4. ブラウザでコードを貼り付け、GitHub にログイン＆**認可（Authorize）**
5. ターミナルに戻ると認証完了

### 特徴

| 項目 | 内容 |
|------|------|
| トークン発行 | `gh` が自動で発行（OAuth）。自分で作らない |
| スコープ | `gh` が必要なもの（`repo`, `read:org`, `gist`, `workflow` 等）を自動付与 |
| 保管 | OS の資格情報マネージャー/keyring に自動保存 |
| 手間 | 少ない（ブラウザでポチっと認可するだけ） |
| 向いている人 | 個人の開発マシン、対話操作ができる環境 |
| 注意 | ブラウザが開ける環境が必要 |

> 今回このプロジェクトで使ったのもこの方式です（`gh auth status` のトークンが `gho_` 始まり = OAuth トークン）。

## 方式B: 自分で PAT を取って貼り付ける（Paste an authentication token）

GitHub の設定画面で **Personal Access Token（PAT）を自分で発行**し、ターミナルに貼り付ける方式です。

### 流れ

1. GitHub Web → **Settings → Developer settings → Personal access tokens** でトークンを発行
   - **Fine-grained tokens**（推奨・新しい）か **Tokens (classic)** のどちらか
   - 必要スコープを**自分で**選ぶ（後述）
2. `gh auth login` →「Paste an authentication token」を選ぶ
3. 発行したトークン文字列を貼り付ける

または環境変数で渡すこともできます（CI や非対話環境向け）:

```bash
# 一時的に環境変数で渡す（画面にトークンが残る点に注意）
export GH_TOKEN=ghp_xxxxxxxx        # bash
$env:GH_TOKEN = "ghp_xxxxxxxx"      # PowerShell
gh extension install github/gh-aw
```

### 必要なスコープ（自分で選ぶ場合）

PAT 方式では**スコープを自分で過不足なく付ける責任**があります。gh aw 用途では最低限:

| スコープ（classic） | 用途 |
|--------------------|------|
| `repo` | リポジトリの読み書き（コミット・シークレット等） |
| `workflow` | **`.github/workflows/` 配下の push に必須**（これが無いとワークフロー更新が弾かれる） |
| `read:org` | 組織リポジトリを使う場合 |

Fine-grained token の場合は、対象リポジトリに対し **Contents: Read and write** と **Workflows: Read and write**、（必要なら）**Secrets: Read and write** を付与します。

### 特徴

| 項目 | 内容 |
|------|------|
| トークン発行 | **自分で**発行・管理する |
| スコープ | 自分で選ぶ（最小権限に絞れる／付け忘れると失敗する） |
| 有効期限 | 自分で設定（期限切れたら再発行が必要） |
| 保管 | 貼り付ければ `gh` が保管。環境変数で渡す場合は自分で管理 |
| 手間 | 多い（発行・スコープ選定・期限管理） |
| 向いている人 | CI/CD・サーバー・非対話環境、権限を厳密に絞りたい場合、組織ポリシーで PAT 指定がある場合 |

## どちらを使うべきか（使い分け）

| 状況 | 推奨方式 |
|------|---------|
| 自分の PC で対話的に使う | **方式A（ブラウザ）** — 手軽でスコープ自動 |
| ブラウザが開けない / サーバー上 | **方式B（PAT）** — トークンを貼る/環境変数で渡す |
| CI/CD・自動化パイプライン | **方式B（PAT）** または GitHub Actions の `GITHUB_TOKEN` |
| 権限を最小限に厳密管理したい | **方式B（PAT・Fine-grained）** |
| 組織が PAT 運用を必須化している | **方式B（PAT）** |

### 一言でいうと

- **ブラウザ方式 = `gh` にトークン管理を任せる（楽・自動）**
- **PAT 方式 = 自分でトークンを発行して管理する（自由・厳密だが手間）**

機能的にできることは同じです。違いは「**誰がトークンを作り・スコープを決め・期限を管理するか**」です。

## 認証の確認・切替・取り消し

```bash
gh auth status      # 現在の認証状態とスコープを確認
gh auth refresh -s workflow   # 後から workflow スコープを追加
gh auth logout      # 認証を取り消す
gh auth switch      # 複数アカウントを切り替える
```

> 🔑 `gh auth status` の `Token scopes` に **`workflow` が無い**と、ワークフローファイルの push でエラーになります。その場合は `gh auth refresh -s workflow`（ブラウザ方式）か、`workflow` スコープ付きの PAT で入れ直してください。

## セキュリティ上の注意

- トークンは**パスワード同等**。コミットや共有チャットに貼らない。
- PAT には**有効期限**を設定し、不要になったら GitHub の設定画面で**失効**させる。
- 環境変数（`GH_TOKEN`）で渡すと**画面やログに残る**ことがある。共有端末では避ける。
- 最小権限（必要なスコープだけ）を心がける。
