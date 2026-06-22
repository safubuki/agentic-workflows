# 例: イベント駆動の3ワークフロー（トリアージ / CI Doctor / Daily）

手動ディスパッチ以外の代表的なトリガー（`issues` / `workflow_run` / `schedule`）の実例です。完全な実装は実ファイルを参照してください。

| ワークフロー | トリガー | 実ファイル | 既定モデル |
|-------------|---------|-----------|-----------|
| Issue トリアージ | `issues: [opened, reopened]` | [issue-triage.md](../../../../.github/workflows/issue-triage.md) | `claude-sonnet-4.6` |
| CI Doctor | `workflow_run: [completed]` + `branches` | [ci-doctor.md](../../../../.github/workflows/ci-doctor.md) | `gpt-5.3-codex` |
| Daily レポート | `schedule: cron` | [daily-report.md](../../../../.github/workflows/daily-report.md) | `claude-haiku-4.5` |

## Issue トリアージ — `issues` トリガー + ラベル付与

```yaml
on:
  issues:
    types: [opened, reopened]
permissions: { contents: read, issues: read, pull-requests: read }
engine: { id: copilot, model: claude-sonnet-4.6 }
safe-outputs:
  add-labels:
    allowed: [bug, enhancement, documentation, question, "area/*", "priority/*"]
    max: 3
```

学べる点: **既存ラベル体系の尊重**（`allowed` で許可リスト化）、`${{ github.event.issue.number }}` の参照。

## CI Doctor — `workflow_run` トリガー（失敗調査）

```yaml
on:
  workflow_run:
    workflows: ["*"]
    types: [completed]
    branches: [main]          # ← セキュリティ/性能のため必須級
permissions: { contents: read, actions: read, issues: read, pull-requests: read }
engine: { id: copilot, model: gpt-5.3-codex }   # コード調査に強いモデル
safe-outputs:
  create-issue: { title-prefix: "[ci-doctor] ", labels: [ci-failure, automated], max: 1 }
```

学べる点: **`branches` 制限**（無いとコンパイル警告）、本文での**早期終了**（`conclusion != failure` なら何もしない）、`github.event.workflow_run.*` の許可式、**用途に応じたモデル選択**（コード調査=Codex）。

## Daily レポート — `schedule` トリガー + expires

```yaml
on:
  schedule:
    - cron: "0 0 * * 1-5"     # 平日 9:00 JST
engine: { id: copilot, model: claude-haiku-4.5 }   # 定型・安価
safe-outputs:
  create-issue: { title-prefix: "[daily] ", labels: [report, automated], max: 1, expires: 14 }
```

学べる点: **cron スケジュール**、**安価なモデルで定型処理**、`expires` 付き safe-output（→ `agentics-maintenance.yml` が自動生成され後始末を定期実行。[compile-pitfalls.md](../references/compile-pitfalls.md) 参照）。

## 共通の学び

- すべて **`engine: copilot`** に統一（[model-policy.md](../references/model-policy.md)）。
- **用途でモデルを使い分ける**: コード調査=Codex、定型・大量=Haiku、通常=Sonnet。
- `tools: github:` を使うので、**必要な read 権限を `permissions` に宣言**する（不足は警告）。
- 作成前に [compile-pitfalls.md](../references/compile-pitfalls.md) を確認すると一発で通る。
