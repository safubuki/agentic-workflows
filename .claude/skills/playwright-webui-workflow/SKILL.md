---
name: playwright-webui-workflow
description: Playwright で Web UI を段階的に調査・取得・安全確認する skill。「Playwright調査」「Web UI調査」「内部API調査」「DOM確認」「Network確認」「read-only調査」「safe-ui確認」「E2E前調査」「ログイン後確認」「フォーム入力調査」「入力検証」「field mapping確認」「schema mismatch調査」などで発火。最初に mode を read-only / safe-ui / mutating-test に分け、Google / SSO は手動ログイン + CDP を優先する。入力系では実行前に source data と target field の contract を確認し、widget type ごとに検証方法を分ける。
---

# Playwright WebUI Workflow

## When to Use

- Playwright でページ構造や挙動を調べたい
- DOM / Network / 内部 API のどこから取れるか見極めたい
- UI テスト前に read-only で安全に調査したい
- Google / SSO 後のページを CDP 経由で確認したい
- フォーム入力前に field mapping や selector / verification 方針を固めたい

## Scope

この skill は Web UI 調査の入口を整理し、`read-only`、`safe-ui`、`mutating-test` のどれで進めるかを決めるための skill です。top-level の `.agents/rules` や `.agents/workflows` には依存せず、この skill と skill 配下の `references/` だけで完結させます。

フォーム入力や反映確認を伴う場合でも、この skill は個別サービス固有の field 名を決め打ちするためのものではありません。ここで扱うのは、どの Web UI にも共通する `入力前 preflight`、`selector fallback`、`widget 別 verification`、`skip reason の切り分け` です。

## Mode Definitions

### read-only

- DOM 読み取り
- Network 観察
- `GET` 中心の内部 API 再利用
- JSON / Markdown / HTML 出力

### safe-ui

- ページ移動
- 展開 / フィルタ / ソート
- モーダル表示
- URL や表示結果の確認

### mutating-test

- 保存、更新、削除、送信を伴う操作
- 元に戻す手順や検証条件が必要なテスト
- 事前承認が必要な変更系の確認

## Workflow

### 1. Choose the mode first

最初に `read-only` / `safe-ui` / `mutating-test` のどれかを決めます。迷う場合は `read-only` を既定にします。

### 2. Decide browser ownership

ログインや 2FA が必要なら `手動ログイン + CDP` を優先します。Playwright 専用ブラウザは未ログイン確認や単純な公開ページ調査に限ります。

### 3. Narrow the target page

1 回の調査で見るページは 1 つに絞ります。
- URL
- ページ名
- 見たい要素
- 取りたいデータ

### 4. Validate the input contract first

フォーム入力や反映確認がある場合は、ブラウザ操作の前に source data と target field の対応を明文化します。

- canonical key は何か
- alias をどこまで受けるか
- required / optional はどれか
- widget type は text / tokenized input / toggle / radio / slider / combobox のどれか
- verification は `.value`、選択状態、chip 表示、近傍 container text のどれで行うか
- `skip-empty`、`schema-missing`、`field-not-found`、`state-unverified` のどれで失敗を記録するか

source data が曖昧なまま UI に触らないことを優先します。

### 5. Inspect in order

基本は次の順で見ます。
1. DOM
2. Network
3. 内部 API

最初から重い UI 操作へ行かず、まずは DOM と Network で足りるかを確認します。

### 6. Pick the extraction path

優先順位は次です。
1. DOM only
2. DOM + Network
3. Internal API reuse
4. UI interaction fallback

### 7. Verify one action at a time

`safe-ui` と `mutating-test` では 1 操作ごとに前後差分を確認します。
- URL
- DOM 変化
- Network レスポンス
- エラーメッセージ

フォーム入力では widget ごとに検証方法を変えます。
- text / textarea: `.value` または textContent
- tokenized input / chips: 生成された token や近傍 container text
- toggle / radio: `aria-pressed` / `aria-selected` / `aria-checked` / `data-state`
- slider: `aria-valuenow`
- combobox / select: 展開後の選択済みラベル

単に「入らなかった」で終わらせず、`データが無かった` のか `selector が弱かった` のか `検証方法が UI に合っていなかった` のかを分離します。

### 8. Stop when evidence is enough

必要な識別子、URL、API 形状、再現手順が揃ったらそこで止めます。調査のしすぎで不要な変更を増やさないことを優先します。

## Deliverables

- 対象ページの要約
- DOM / Network / API の観察結果
- 再利用できるエンドポイントや識別子
- 入力系なら canonical field map と alias 方針
- 入力系なら widget type ごとの verification 方針
- `skip-empty` / `schema-missing` / `field-not-found` / `state-unverified` の切り分け
- 必要なら `json` / `md` / `html` 形式の出力
- 変更系テストの場合は前提条件とロールバック条件

## References

- [references/modes-and-checklists.md](references/modes-and-checklists.md)
- [references/browser-ownership-and-cdp.md](references/browser-ownership-and-cdp.md)
- [references/form-input-preflight.md](references/form-input-preflight.md)
