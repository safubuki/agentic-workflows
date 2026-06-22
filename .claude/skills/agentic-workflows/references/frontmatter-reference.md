# フロントマター早見表

Agentic Workflow の `.md` 冒頭、`---` で囲む YAML 設定です。

## 全項目

| フィールド | 用途 | 例 |
|-----------|------|-----|
| `name` | 表示名 | `PR AI Review` |
| `description` | 説明 | `指定 PR を AI レビュー` |
| `on` | トリガー | `workflow_dispatch` / `push` / `pull_request` / `issues` / `schedule` |
| `permissions` | API 権限 | `contents: read` |
| `engine` | AI プロバイダ（とモデル） | `claude` |
| `tools` | 利用機能 | `github` / `web-search` / `playwright` |
| `safe-outputs` | 安全な書き込み | `add-comment` / `create-pull-request` |
| `network` | ネットワーク制御 | `defaults` |
| `timeout_minutes` | 実行時間上限 | `20` |
| `roles` | 実行許可ロール | `[admin, maintainer, write]` |

## トリガー（on）

### 手動実行 + 入力

```yaml
on:
  workflow_dispatch:
    inputs:
      pr_number:
        description: "PR 番号"
        type: string
        required: true
      model:
        description: "使う AI モデル"
        type: choice
        options:
          - claude-sonnet-4.6
          - gpt-5.4
          - gpt-5.3-codex
          - claude-haiku-4.5
        default: claude-sonnet-4.6
        required: true
```

`type`: `string` / `choice` / `boolean` / `number`。`choice` は `options:` で選択肢、`default:` で既定値。

### その他

```yaml
on:
  push:
    branches: [main]
    paths: ["src/**"]          # / paths-ignore で除外
  pull_request:
    types: [opened, synchronize]
  issues:
    types: [opened]
  schedule:
    - cron: "0 9 * * *"
```

## 本文での参照

| 参照対象 | 書き方 |
|---------|--------|
| dispatch 入力 | `${{ github.event.inputs.<名前> }}` |
| PR 番号（PR トリガー時） | `${{ github.event.pull_request.number }}` |
| リポジトリ | `${{ github.repository }}` |
| 実行者 | `${{ github.actor }}` |
| イベント名 | `${{ github.event_name }}` |
| コミット SHA | `${{ github.sha }}` |

> 手動ディスパッチには PR コンテキストが付かないため、PR 番号は入力で受け取り `${{ github.event.inputs.pr_number }}` で参照する。

## 権限（permissions）

```yaml
permissions:
  contents: read
  pull-requests: read
  issues: read
```

最小権限が原則。書き込みは safe-outputs 経由なので read で足りることが多い。

## エンジン（engine）

> 🟢 **このプロジェクトの既定は `engine: copilot`**（GitHub Copilot で選べる中級モデルを使う）。詳細は [model-policy.md](model-policy.md)。

### 短縮形

```yaml
engine: copilot
```

### オブジェクト形（モデル・上限指定）

```yaml
engine:
  id: copilot
  model: claude-sonnet-4.6   # 実行時に切替: model: ${{ github.event.inputs.model }}
  max-turns: 20
```

| エンジン | `id` | シークレット |
|---------|------|-------------|
| Copilot（このプロジェクトの既定） | `copilot` | `COPILOT_GITHUB_TOKEN`（または `copilot-requests: write`） |
| Claude | `claude` | `ANTHROPIC_API_KEY` |
| Codex | `codex` | `OPENAI_API_KEY` |
| Gemini | `gemini` | `GEMINI_API_KEY` |

採用モデル（Copilot エンジン・choice 値）:

| モデル | choice 値 | 想定用途 |
|--------|----------|---------|
| Claude Sonnet 4.6 | `claude-sonnet-4.6` | バランス型・既定 |
| GPT-5.4 | `gpt-5.4` | 汎用・代替 |
| GPT-5.3 Codex | `gpt-5.3-codex` | コード調査・原因分析 |
| Claude Haiku 4.5 | `claude-haiku-4.5` | 高速・低コスト・定型 |

## ツール（tools）

```yaml
tools:
  github:       # PR/Issue/コメント等の GitHub 操作
  web-search:   # Web 検索
  playwright:   # ブラウザ自動化
```
