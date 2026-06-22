# 利用モデルの方針（GitHub Copilot エンジン）

本リポジトリの Agentic Workflow は、すべて **GitHub Copilot エンジン（`engine: copilot`）** で動かし、Copilot で選べる**中級モデル**を使います。

## なぜ Copilot エンジンか

- **GitHub Copilot Pro で選べるモデル**をそのまま使える（追加の外部 API キー不要）。
- 認証は `COPILOT_GITHUB_TOKEN`（または `copilot-requests: write` 権限）だけで済む。
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

## 必要なシークレット / 権限

```bash
gh secret set COPILOT_GITHUB_TOKEN
```

> 💡 **代替の認証方法**: `permissions: copilot-requests: write` を付けると、PAT（`COPILOT_GITHUB_TOKEN`）ではなく GitHub Actions のトークンベース推論を使えます。ただし**組織で Copilot の一元課金が有効**な場合のみで、利用できない環境もあります。詳細は [課金リファレンス](https://github.github.com/gh-aw/reference/billing/)。

## モデル ID 文字列の注意

- ここで使う `claude-sonnet-4.6` などの文字列は、**Copilot が公開しているモデル ID 表記**に合わせる必要があります。
- 表記が合わないと実行時にモデル解決でエラーになることがあります。その場合は、Copilot のモデル一覧（GitHub の Copilot 設定や `gh copilot` の表示、ワークフロー実行ログ）で**正確な ID を確認して置き換え**てください。
- モデルを増減・変更したいときは、各ワークフローの `model:`（および choice の `options:`）を編集して `gh aw compile` し直すだけです。
