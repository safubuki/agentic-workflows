# 利用モデルの方針（このプロジェクトの既定）

このプロジェクトの Agentic Workflow は、すべて **GitHub Copilot エンジン（`engine: copilot`）** で動かします。Copilot Pro で選べる**中級モデル**を使い、外部プロバイダ（Azure OpenAI 等）は使いません。

## 採用モデル（4種）

| モデル | choice 値 | 想定用途 |
|--------|----------|---------|
| Claude Sonnet 4.6 | `claude-sonnet-4.6` | バランス型・既定（レビュー/文章） |
| GPT-5.4 | `gpt-5.4` | 汎用・代替 |
| GPT-5.3 Codex | `gpt-5.3-codex` | コード調査・原因分析（CI 系） |
| Claude Haiku 4.5 | `claude-haiku-4.5` | 高速・低コスト（定型レポート） |

## エンジン設定（固定 / 切替）

```yaml
# 固定
engine:
  id: copilot
  model: claude-sonnet-4.6
```

```yaml
# 手動ディスパッチで切替
on:
  workflow_dispatch:
    inputs:
      model:
        type: choice
        options: [claude-sonnet-4.6, gpt-5.4, gpt-5.3-codex, claude-haiku-4.5]
        default: claude-sonnet-4.6
engine:
  id: copilot
  model: ${{ github.event.inputs.model }}
```

## シークレット / 認証

- 必要なのは `COPILOT_GITHUB_TOKEN`（`gh secret set COPILOT_GITHUB_TOKEN`）。
- 代替: `permissions: copilot-requests: write`（組織で Copilot 一元課金が有効な場合のみ）。

## モデル ID 文字列の注意

- `claude-sonnet-4.6` 等の文字列は **Copilot のモデル ID 表記**に合わせる必要がある。
- 合わないと実行時にモデル解決でエラー。正確な ID は GitHub の Copilot 設定や実行ログで確認して置き換える。
- 用途に応じて既定モデルを選ぶ（重い分析は Codex、定型・大量は Haiku、通常は Sonnet）。

> 詳細な背景は docs の [references/model-policy.md](../../../docs/references/model-policy.md) を参照。
