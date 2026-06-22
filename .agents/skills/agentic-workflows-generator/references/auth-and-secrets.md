# 認証とシークレット（2レイヤー・組織/個人）

gh-aw の認証は**2つの別レイヤー**があり、混同しやすい。生成・セットアップ支援の際は、この区別を踏まえて案内する。

## 2つのレイヤー（別物）

| | `gh auth login`（ローカル認証） | エンジン認証（Actions 用） |
|---|---|---|
| 誰が認証 | **あなたのPCの `gh` コマンド** | **GitHub Actions のランナー（クラウド）** |
| 置き場所 | PC の keyring（ローカル） | リポジトリのシークレット or ワークフロー権限 |
| 何に使う | ローカル操作（push / secret set / compile） | 実行中に **AI がエンジン（Copilot等）を呼ぶ** |

> 🔑 **`gh auth login` 済みでもエンジン認証は別途必要**。ローカルのトークンはクラウドのランナーから見えない。

`gh auth login` 内の「ブラウザ方式 vs PAT 方式」は**左側（ローカル認証）の選択肢**であり、エンジン認証とは無関係。ローカル認証の詳細は docs の [gh-auth-guide.md](../../../docs/references/gh-auth-guide.md)。

## Copilot エンジンの認証（組織 か 個人 か）

→ どちらを使うかは必ずユーザーに確認する（[decision-points.md](decision-points.md) §1）。

### 方法1（推奨・組織/複数人）: `copilot-requests: write`

```yaml
permissions:
  copilot-requests: write
```

- **シークレット不要**。Actions のトークンベース推論で Copilot を呼ぶ。
- 個人トークンを共有しない → なりすまし・課金付け替えなし。課金は組織の一元課金。
- **組織で Copilot の一元課金が有効**な場合に使える。会社組織では基本これ。

### 方法2（個人・自分専用リポジトリ）: `COPILOT_GITHUB_TOKEN`

```bash
gh secret set COPILOT_GITHUB_TOKEN
```

- Copilot 権限を持つトークンをシークレット登録。

> ⚠️ **複数人開発で個人トークンをリポジトリシークレットに入れない**。リポジトリのワークフローを動かせる全員が間接的に使えてしまい、なりすまし・課金付け替え・権限過剰共有・退職時の停止が起きる。共有リポジトリでは方法1、またはチーム用 **Bot アカウント / GitHub App** のトークンを使う。個人トークンは自分しか触らない個人所有リポジトリに限る。

## 他エンジンのシークレット（参考）

| エンジン | シークレット |
|---------|-------------|
| Claude | `ANTHROPIC_API_KEY` |
| Codex | `OPENAI_API_KEY` |
| Gemini | `GEMINI_API_KEY` |

## 確認コマンド

```bash
gh secret list        # 登録済みシークレット
gh auth status        # ローカル認証の状態とスコープ
```
