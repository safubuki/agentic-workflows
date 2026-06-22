# セットアップ支援ガイド（gh / gh aw 導入・認証）

Setup モードで使う、導入から実行までの流れ。詳細手順は docs の [02-セットアップ.md](../../../docs/02-セットアップ.md) を参照。

## 依存関係（上から順に揃える）

```
gh 本体 → ローカル認証(gh auth login) → gh aw 拡張 → コンパイル → エンジン認証 → 実行
```

## 手順

### Step 1: gh 本体

```bash
# Windows
winget install --id GitHub.cli
# macOS
brew install gh
gh --version
```

> インストール直後は PATH が現在のターミナルに反映されないことがある。`gh` が見つからなければターミナルを開き直す。

### Step 2: ローカル認証

```bash
gh auth login        # ブラウザ方式 or PAT 方式（→ auth-and-secrets.md）
gh auth status       # repo / workflow スコープがあるか確認
```

> `workflow` スコープが無いとワークフローファイルの push が弾かれる。

### Step 3: gh aw 拡張（認証後）

```bash
gh extension install github/gh-aw
gh aw version
```

### Step 4: オーサリング初期化（任意）

```bash
gh aw init
```

> ⚠️ 既存の `.github/skills/agentic-workflows-generator/` を上書きしうる。事前バックアップ・`git diff` 確認を提案する（[decision-points.md](decision-points.md) §6）。

### Step 5: エンジン認証（組織/個人で分岐）

→ **必ずユーザーに確認**（[decision-points.md](decision-points.md) §1）。
- 組織: `permissions: copilot-requests: write`（シークレット不要・推奨）
- 個人: `gh secret set COPILOT_GITHUB_TOKEN`

### Step 6: コンパイル & コミット

```bash
gh aw compile          # 新規シークレット使用時は --approve
git add .github/workflows/*.md .github/workflows/*.lock.yml
```

## つまずきポイント（先回りで案内）

- `not in a git repository` → `git init`
- ローカル認証済みでも**エンジン認証は別**（[auth-and-secrets.md](auth-and-secrets.md)）
- `schedule` は**デフォルトブランチに push して初めて有効**・以後は放置で動く
- 別リポジトリへ移植したら**移植先で再コンパイル**（`.lock.yml` は環境依存）

コンパイル時の警告・エラーの詳細は [compile-pitfalls.md](compile-pitfalls.md)。
