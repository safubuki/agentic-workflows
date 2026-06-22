---
name: Daily Activity Report
description: 毎日定時にリポジトリの直近アクティビティ（新規 Issue・マージ済み PR・未解決のブロッカー）を要約したレポート Issue を作成する
on:
  schedule:
    - cron: "0 0 * * 1-5"   # 平日 9:00 JST（00:00 UTC）
  workflow_dispatch:
    inputs:
      days:
        description: "集計対象の日数"
        type: string
        default: "1"
        required: false

permissions:
  contents: read
  issues: read
  pull-requests: read

engine:
  id: copilot
  model: claude-haiku-4.5
  max-turns: 20

tools:
  github:

safe-outputs:
  create-issue:
    title-prefix: "[daily] "
    labels: [report, automated]
    max: 1
    expires: 14
---

# デイリー アクティビティレポート

リポジトリの直近の動きを要約した、**前向きで読みやすい**レポート Issue を1件作成します。チームが朝に状況を把握できることが目的です。軽量・低コストなモデル（Haiku 4.5）を既定にしています。

## 入力・コンテキスト

- 集計日数: `${{ github.event.inputs.days }}`（既定は前日分。schedule 実行時は直近1日）
- リポジトリ: `${{ github.repository }}`

## 集計内容

直近の期間について、次を `github` ツールで集計する:

| 項目 | 内容 |
|------|------|
| 新規 Issue | 期間内に開かれた Issue（件数とハイライト） |
| クローズ Issue | 解決された Issue |
| マージ済み PR | 期間内にマージされた PR |
| オープン中の PR | レビュー待ち・停滞している PR |
| ブロッカー | `priority/*` や停滞ラベルが付いた未解決項目 |

## 手順

### Step 1: アクティビティを集計する

1. 対象期間（既定は直近1日）の Issue・PR を取得する。
2. 上表の各カテゴリに分類し、件数と注目項目を抽出する。

### Step 2: レポートを作成する

`create-issue` で**1件**のレポートを作成する（`type: create_issue`）。

```
## 📊 デイリーレポート（{日付}）

おはようございます！直近の動きをまとめました。

### 🆕 新しい Issue（{件数}）
- #{番号} {タイトル}

### ✅ 解決した Issue（{件数}）
- #{番号} {タイトル}

### 🔀 マージされた PR（{件数}）
- #{番号} {タイトル}

### 👀 レビュー待ち・停滞 PR（{件数}）
- #{番号} {タイトル}（{停滞日数}）

### 🚧 ブロッカー
- {未解決の重要項目、なければ「なし 🎉」}

### ひとこと
{その日の総括を前向きに1文}
```

## 厳守事項

- 動きが無い日は、無理に内容を作らず「本日は大きな動きはありませんでした」と簡潔に報告する。
- 数字は実データに基づき、推測で水増ししない。
- safe-outputs は宣言済みのもの（`create-issue`）のみ使う。
- 出力は日本語で記述する。
