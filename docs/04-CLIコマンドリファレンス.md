# 04. CLI コマンドリファレンス（`gh aw`）

`gh aw` は GitHub CLI の拡張です。`gh extension install github/gh-aw` でインストールします。

## コマンド一覧

| コマンド | 用途 |
|---------|------|
| `gh aw init` | オーサリング環境を初期化（VS Code 設定・MCP・ディスパッチャースキル作成）。**最初に1回実行** |
| `gh aw new <名前>` | 新しいワークフロー `.md` の雛形を作成 |
| `gh aw add <ソース>` | 既存ワークフロー（テンプレート/他リポジトリ）を取り込む |
| `gh aw compile` | `.md` を `.lock.yml` にコンパイル。**編集のたびに実行** |
| `gh aw run <名前>` | ワークフローを手動実行 |
| `gh aw status` | ワークフローの状態を確認 |

## 典型的な作業フロー

```bash
# 初回のみ
gh extension install github/gh-aw
gh aw init
gh secret set ANTHROPIC_API_KEY

# 開発サイクル（編集 → コンパイル → 確認 → コミット）
# 1. .github/workflows/foo.md を編集
gh aw compile
git add .github/workflows/foo.md .github/workflows/foo.lock.yml
git commit -m "Update foo workflow"
git push

# 実行
gh aw run foo
gh aw status
```

## `gh aw compile` の役割

1. フロントマターの**構文・スキーマ検証**
2. **セキュリティ強化**（権限の絞り込み、safe-outputs の許可リスト化）
3. 最終的な GitHub Actions YAML（`.lock.yml`）の生成

> ⚠️ `.md` を編集したら**必ず再コンパイル**してください。`.lock.yml` が古いと、変更が Actions に反映されません。

## ワークフローの手動実行（2通り）

### CLI から

```bash
# 入力なし
gh aw run hello

# workflow_dispatch の入力を渡す（GitHub UI / gh workflow run でも可）
gh workflow run "PR AI Review" \
  -f pr_number=42 \
  -f model=claude-sonnet-4.6 \
  -f max_reviews=3
```

### GitHub UI から

1. リポジトリの **Actions** タブを開く
2. 左メニューから対象ワークフローを選ぶ
3. **Run workflow** ボタン → 入力を埋める → 実行

## よく使う補助コマンド

```bash
gh aw --help            # ヘルプ
gh extension upgrade gh-aw   # 拡張を更新
gh run list             # 実行履歴（標準 gh コマンド）
gh run view <run-id> --log   # 実行ログを見る
```

困ったときは [06-トラブルシューティング.md](06-トラブルシューティング.md) を参照してください。
