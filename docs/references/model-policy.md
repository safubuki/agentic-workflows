# 利用モデルの方針（GitHub Copilot エンジン）

本リポジトリの Agentic Workflow は、すべて **GitHub Copilot エンジン（`engine: copilot`）** で動かし、Copilot で選べる**中級モデル**を使います。

## なぜ Copilot エンジンか

- **GitHub Copilot で選べるモデル**をそのまま使える（追加の外部 API キー不要）。
- 認証は `copilot-requests: write` 権限（組織）または `COPILOT_GITHUB_TOKEN`（個人）だけで済む（下記）。
- Azure OpenAI など外部プロバイダの利用は**別枠**。本リポジトリでは使いません。
- 自動化は大量に走るため、最上位モデルではなく**現実的な中級モデル**で十分という見立て。

## 採用モデル（4種）

| モデル | choice 値 | 想定用途 |
|--------|----------|---------|
| Claude Sonnet 4.6 | `claude-sonnet-4.6` | バランス型。レビュー・文章生成の既定 |
| GPT-5.4 | `gpt-5.4` | 汎用。Sonnet の代替・比較に |
| GPT-5.3 Codex | `gpt-5.3-codex` | コード調査・原因分析に強い（CI Doctor の既定） |
| Claude Haiku 4.5 | `claude-haiku-4.5` | 高速・低コスト。定型レポートの既定（Daily） |

## フロントマターでの指定

固定する場合:

```yaml
engine:
  id: copilot
  model: claude-sonnet-4.6
```

手動ディスパッチで切り替える場合:

```yaml
on:
  workflow_dispatch:
    inputs:
      model:
        type: choice
        options:
          - claude-sonnet-4.6
          - gpt-5.4
          - gpt-5.3-codex
          - claude-haiku-4.5
        default: claude-sonnet-4.6
engine:
  id: copilot
  model: ${{ github.event.inputs.model }}
```

## 認証方法（2通り・優先順）

Copilot エンジンの認証は2通りあります。**組織・複数人開発では方法1、個人の検証用では方法2**を使います。

### 方法1（推奨・組織/複数人）: `copilot-requests: write`

ワークフローに権限を付けるだけ。**シークレット登録は不要**で、GitHub Actions のトークンベース推論で Copilot を呼びます。

```yaml
permissions:
  copilot-requests: write
```

- 個人トークンを共有しないので**なりすまし・課金の付け替えが起きない**（課金は組織の一元課金へ）。
- ローテーションや退職の影響を受けない。
- **組織で Copilot の一元課金（centralized billing）が有効**な場合に使えます。会社組織では基本これ。
- 詳細は [課金リファレンス](https://github.github.com/gh-aw/reference/billing/)。

### 方法2（個人・自分専用リポジトリ）: `COPILOT_GITHUB_TOKEN`

組織の一元課金が使えない個人環境では、Copilot 権限を持つトークンをシークレットに登録します。

```bash
gh secret set COPILOT_GITHUB_TOKEN
```

> ⚠️ **複数人開発では個人トークンをリポジトリシークレットに入れない**。リポジトリのワークフローを動かせる全員が間接的にそのトークンを使えてしまい、なりすまし・課金の付け替え・権限の過剰共有・退職時の停止といった問題が起きます。共有リポジトリでは**方法1**、またはチーム用の Bot アカウント/GitHub App のトークンを使ってください。個人トークンは**自分しか触らない個人所有リポジトリに限る**のが安全です。

## モデル ID 文字列の注意

- ここで使う `claude-sonnet-4.6` などの文字列は、**Copilot が公開しているモデル ID 表記**に合わせる必要があります。
- 表記が合わないと実行時にモデル解決でエラーになることがあります。その場合は、Copilot のモデル一覧（GitHub の Copilot 設定や `gh copilot` の表示、ワークフロー実行ログ）で**正確な ID を確認して置き換え**てください。
- モデルを増減・変更したいときは、各ワークフローの `model:`（および choice の `options:`）を編集して `gh aw compile` し直すだけです。
