# safe-outputs リファレンス

`safe-outputs` は AI の出力を**検証済みの GitHub 操作**に変換する仕組みです。
**AI は既定で読み取り専用**。フロントマターで宣言した safe-output だけを実行できます（許可リスト）。

## 主要な種類

| カテゴリ | タイプ |
|---------|--------|
| Issue/Discussion | `create-issue`, `update-issue`, `close-issue`, `create-discussion` |
| Pull Request | `create-pull-request`, `update-pull-request`, `create-pull-request-review-comment`, `submit-pull-request-review`, `push-to-pull-request-branch` |
| ラベル/コメント | `add-comment`, `hide-comment`, `add-labels`, `remove-labels` |
| その他 | `upload-artifact`, `dispatch-workflow`, `missing-tool` |

## よく使う設定例

### コメント投稿（add-comment）

```yaml
safe-outputs:
  add-comment:
    max: 1
    target: "*"          # "triggering"(既定) / "*" / 番号
```

AI の出力（本文中の JSON）:

```json
{ "type": "add_comment", "body": "コメント本文" }
```

### コード行へのレビューコメント（create-pull-request-review-comment）

```yaml
safe-outputs:
  create-pull-request-review-comment:
    max: 20
    target: "triggering"
```

### レビューをまとめて提出（submit-pull-request-review）

```yaml
safe-outputs:
  submit-pull-request-review:
    max: 1
    allowed-events: [COMMENT, REQUEST_CHANGES]
```

AI は `review_body` と `event`（`APPROVE` / `REQUEST_CHANGES` / `COMMENT`）を指定。

### ラベル付与（add-labels）— 状態管理に有用

```yaml
safe-outputs:
  add-labels:
    allowed: [ai-review-1, ai-review-2, ai-review-3, ai-review-done]
    max: 1
    target: "*"
```

```json
{ "type": "add_labels", "labels": ["ai-review-2"] }
```

### Issue 作成（create-issue）

```yaml
safe-outputs:
  create-issue:
    title-prefix: "[ai] "
    labels: [automation]
    max: 1
```

```json
{ "type": "create_issue", "title": "タイトル", "body": "本文（20〜65000文字）" }
```

### PR 作成（create-pull-request）

```yaml
safe-outputs:
  create-pull-request:
    title-prefix: "[ai] "
    labels: [automated]
    max: 1
```

AI は構造化されたコード変更を提供。直接 push せず PR として提案する。

## AI が safe-output を発行する仕組み

AI は本文の指示に従い、応答中に **JSON オブジェクト**を出力します。`type` フィールド（スネークケース: `add_comment` / `add_labels` / `create_issue` / `create_pull_request` 等）で操作を指定します。

> 🔑 **本文で使う safe-output は、必ずフロントマターで宣言**してください。未宣言のものは実行されません。
