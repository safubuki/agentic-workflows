# GitHub Agentic Workflows ドキュメント

このフォルダは **GitHub Agentic Workflows（gh-aw）** の利用手順書・マニュアル集です。
Markdown でワークフローを記述し、`gh aw compile` でコンパイルすると、AI が実行可能な GitHub Actions ワークフロー（`.lock.yml`）が生成されます。

## 目次

| ドキュメント | 内容 |
|-------------|------|
| [01-agentic-workflows-とは.md](01-agentic-workflows-とは.md) | Agentic Workflows の概念・仕組み・ライフサイクル |
| [02-セットアップ.md](02-セットアップ.md) | gh 本体 → 認証 → gh aw 拡張 → コンパイルまでの導入手順 |
| [03-ワークフローの書き方.md](03-ワークフローの書き方.md) | フロントマター全項目・本文・テンプレート構文の早見表 |
| [04-CLIコマンドリファレンス.md](04-CLIコマンドリファレンス.md) | `gh aw` コマンド一覧と使い方 |
| [05-同梱ワークフロー解説.md](05-同梱ワークフロー解説.md) | 本リポジトリの PR レビュー / README 自動更新ワークフローの解説 |
| [06-トラブルシューティング.md](06-トラブルシューティング.md) | よくある問題と対処、FAQ |
| [references/gh-auth-guide.md](references/gh-auth-guide.md) | GitHub 認証の意味と「ブラウザ方式 vs PAT 方式」の違い |
| [references/model-policy.md](references/model-policy.md) | 利用モデルの方針（Copilot エンジン・採用4モデル） |

## クイックスタート（3分）

```bash
# 0. gh 本体を導入（未導入の場合）
winget install --id GitHub.cli   # macOS は: brew install gh

# 1. GitHub 認証（ブラウザ方式 / PAT 方式 → references/gh-auth-guide.md 参照）
gh auth login

# 2. gh aw 拡張をインストール（認証後）
gh extension install github/gh-aw

# 3. オーサリング環境を初期化（VS Code 設定・MCP・ディスパッチャースキルを作成）
gh aw init

# 4. ワークフローを書く（.github/workflows/*.md）→ コンパイル
gh aw compile

# 5. シークレットを登録（Claude を使う場合）
gh secret set ANTHROPIC_API_KEY

# 6. .md と .lock.yml を両方コミットしてプッシュ
git add .github/workflows/*.md .github/workflows/*.lock.yml
git commit -m "Add agentic workflows"
```

> ℹ️ **重要**: `.md`（ソース）と `.lock.yml`（コンパイル結果）は**両方コミット**します。Actions が実際に実行するのは `.lock.yml` です。

## 本リポジトリの同梱ワークフロー

すべて **GitHub Copilot エンジン**で動作します（モデル方針は [references/model-policy.md](references/model-policy.md)）。

| ワークフロー | ファイル | トリガー | 概要 |
|-------------|---------|---------|------|
| PR AI レビュー | [.github/workflows/pr-ai-review.md](../.github/workflows/pr-ai-review.md) | `workflow_dispatch` 手動 | 指定 PR を選んだ AI モデルでレビュー。最大3回まで同一観点で再レビューし、修正のたびに指摘件数を収束させる |
| README 自動更新 | [.github/workflows/auto-readme-update.md](../.github/workflows/auto-readme-update.md) | `push`（既定ブランチ） | 変更内容に応じて既存 README の書き方・粒度に合わせて自動更新する PR を作成 |
| Issue トリアージ | [.github/workflows/issue-triage.md](../.github/workflows/issue-triage.md) | `issues`（opened/reopened） | 新規 Issue の内容を分析し、既存ラベル体系に沿ってラベルを自動付与 |
| CI Doctor | [.github/workflows/ci-doctor.md](../.github/workflows/ci-doctor.md) | `workflow_run`（失敗時） | CI/ビルド失敗の原因をログから調査し、原因と修正方針を Issue で報告 |
| Daily レポート | [.github/workflows/daily-report.md](../.github/workflows/daily-report.md) | `schedule`（平日朝） | 直近の Issue/PR/ブロッカーを要約した日次レポート Issue を作成 |

詳細は [05-同梱ワークフロー解説.md](05-同梱ワークフロー解説.md) を参照してください。

## 公式リソース

- 公式ドキュメント: <https://github.github.com/gh-aw/>
- リポジトリ: <https://github.com/github/gh-aw>
- GitHub Docs: <https://docs.github.com/en/copilot/how-tos/github-agentic-workflows/>
