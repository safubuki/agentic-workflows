# gh aw CLI コマンドリファレンス

`gh aw` は GitHub CLI の拡張です。

## インストール / 初期化

```bash
gh extension install github/gh-aw   # 拡張をインストール
gh aw init                          # オーサリング環境を初期化（最初に1回）
gh extension upgrade gh-aw          # 更新
```

## コマンド一覧

| コマンド | 用途 |
|---------|------|
| `gh aw init` | VS Code 設定・MCP・ディスパッチャースキルを作成 |
| `gh aw new <名前>` | ワークフロー `.md` の雛形を作成 |
| `gh aw add <ソース>` | 既存ワークフローを取り込む |
| `gh aw compile` | `.md` → `.lock.yml` にコンパイル（編集のたびに実行） |
| `gh aw run <名前>` | ワークフローを手動実行 |
| `gh aw status` | ワークフローの状態を確認 |

## 典型フロー

```bash
# 初回
gh extension install github/gh-aw
gh aw init
gh secret set ANTHROPIC_API_KEY

# 開発サイクル
# (1) .github/workflows/foo.md を編集
gh aw compile
git add .github/workflows/foo.md .github/workflows/foo.lock.yml
git commit -m "Update foo workflow"
git push

# 実行
gh aw run foo
gh aw status
```

## workflow_dispatch に入力を渡して実行

```bash
gh workflow run "PR AI Review" \
  -f pr_number=42 \
  -f model=claude-sonnet-4.6 \
  -f max_reviews=3
```

または **Actions タブ → ワークフロー選択 → Run workflow**。

## デバッグ

```bash
gh run list --workflow "PR AI Review"
gh run view <run-id> --log
```

## 重要原則

- `.md` 編集後は**必ず `gh aw compile`**。`.lock.yml` が古いと変更が反映されない。
- `.md` と `.lock.yml` を**両方コミット**。Actions が実行するのは `.lock.yml`。
- `gh aw` 未導入の環境では compile できない。記述の妥当性だけ確認し、導入環境で compile してもらう。
