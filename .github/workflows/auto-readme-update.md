---
name: Auto README Update
description: ファイル更新時に変更内容を解析し、既存 README の書き方・粒度に合わせて最適に README を更新する PR を作成する
on:
  push:
    branches: [main]
    paths-ignore:
      - "**/*.lock.yml"
      - "docs/**"
      - ".github/skills/**"
  workflow_dispatch:

permissions:
  contents: read
  issues: read
  pull-requests: read

engine:
  id: copilot
  model: claude-sonnet-4.6
  max-turns: 30

tools:
  github:

safe-outputs:
  # README の更新は直接 push せず、レビュー可能な PR として提案する
  create-pull-request:
    title-prefix: "[docs] "
    labels: [documentation, automated]
    max: 1
---

# README 自動更新（粒度・既存スタイル踏襲型）

直近の push でファイルが更新されました。変更内容に応じて、**既存 README の書き方・粒度・トーンに合わせて** README を最適に更新する Pull Request を作成してください。

## 入力・コンテキスト

- リポジトリ: `${{ github.repository }}`
- トリガー: `${{ github.event_name }}`
- 直近 push の HEAD コミット: `${{ github.event.head_commit.id }}`（`workflow_dispatch` 実行時は空。その場合は最新コミットを対象とする）

## 基本方針

1. **既存スタイルの踏襲が最優先**: 既存 README が存在する場合、その**見出し構成・粒度・口調・言語（日本語/英語）・テーブルや箇条書きの使い方**を踏襲する。新しい体裁を勝手に持ち込まない。
2. **適切な粒度**: 変更が大きければ相応に、軽微なら最小限だけ更新する。冗長にしない。
3. **過剰更新をしない**: 変更が README に反映すべき内容を含まない場合（内部リファクタ・テスト追加のみ等）は、**何も変更せず**その旨を報告して終了する。
4. **直接 push しない**: 変更は必ず `create-pull-request` で PR として提案する。人間がレビューしてマージする。

## 手順

### Step 1: 直近の変更を把握する

1. `github` ツールで、直近の push（HEAD コミット `${{ github.event.head_commit.id }}`。空なら最新コミット）で**変更されたファイル一覧と差分**を取得する。
2. 変更を分類する:
   - 新機能・公開 API・CLI コマンド・設定項目の追加/変更 → README 反映の候補
   - 依存関係・実行コマンド・セットアップ手順の変更 → README 反映の候補
   - ディレクトリ構成の大きな変更 → README 反映の候補
   - 内部実装のみ・テストのみ・コメント修正のみ → 原則 README 更新不要

### Step 2: 既存 README を読み、スタイルを学習する

1. リポジトリ直下（および該当サブプロジェクト）の `README.md` を探して読む。
2. 次を把握する:
   - 言語（日本語/英語）とトーン
   - 見出し構成（目次・機能一覧・セットアップ・使い方・構成など）
   - 粒度（コマンド数行で済ませているか、詳細に書いているか）
   - テーブル/箇条書き/コードブロックの使い方
3. README が存在しない場合は、プロジェクトの規模・技術スタックに見合った**簡潔な**新規 README を作る（最短で動かせるパスを最初に示す）。

### Step 3: 更新内容を決める

1. Step 1 の変更のうち、README に反映すべきものだけを抽出する。
2. 既存 README の該当セクションに、**既存の書き方に揃えて**追記・修正する。
   - 既存の記述を不必要に書き換えない。差分は最小限に。
   - セクションが無ければ既存構成に馴染む位置に追加する。
3. 反映すべき内容が無ければ、PR を作らず Step 5 の報告のみ行う。

### Step 4: PR を作成する

`create-pull-request` で、README の更新を含む PR を作成する（`type: create_pull_request`）。

- タイトル: `README を最新の変更に追従` のように簡潔に（プレフィックス `[docs] ` は自動付与）。
- 本文には次を含める:
  - 反映したファイル変更の要約
  - README のどのセクションを、なぜ更新したか
  - 既存スタイルに合わせた点（言語・粒度・体裁）

### Step 5: 報告

- 更新した場合: 作成した PR と更新セクションを簡潔にまとめる。
- 更新不要だった場合: 「今回の変更は README 反映が不要（理由）」と明記して終了する。

## 厳守事項

- README に**直接 push しない**。必ず PR 経由。
- 既存 README のスタイル・言語を**勝手に変えない**。
- 変更が README に無関係なら**何もしない**。
- 出力・PR 本文は、既存 README の言語に合わせる（本リポジトリは日本語）。
