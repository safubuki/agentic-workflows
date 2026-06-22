# Form Input Preflight

## 目的

フォーム入力系の Playwright 作業で失敗しやすいのは、selector そのものよりも `source data` と `target field` の契約が曖昧なまま UI を触ってしまうことです。

このメモでは、サービス固有ではない汎用的な preflight を整理します。

## 1. Source Contract を先に決める

最低限、次を表にします。

- canonical key
- accepted aliases
- required / optional
- default / inference の有無
- skip reason

例:

| target | canonical key | aliases | required | inference | skip reason |
| --- | --- | --- | --- | --- | --- |
| title | `title` | `songTitle`, `Song Title` | optional | なし | `skip-empty` |
| styles | `styles` | `style`, `Style of Music` | optional | なし | `skip-empty` or `schema-missing` |
| vocal gender | `vocalGender` | `gender`, `Vocal Gender` | optional | style text から推論可 | `skip-empty` |

重要なのは、`値が無い` と `別名しか無い` を同じ失敗にしないことです。

## 2. Widget Type を分類する

同じ「入力」でも検証方法は違います。

- text / textarea
- tokenized input / chips
- toggle / segmented control
- radio
- checkbox
- slider
- combobox / autocomplete
- contenteditable

widget type を決めないまま `.value` だけで検証すると誤判定しやすくなります。

## 3. Verification Plan を先に持つ

### text / textarea

- `.value` で読む
- `input` / `change` の発火を確認する

### tokenized input / chips

- chip の生成結果を見る
- 近傍 container text を読む
- 区切り文字や自動整形後の token 単位で比較する

### toggle / radio / segmented control

- `aria-pressed`
- `aria-selected`
- `aria-checked`
- `data-state`
- `data-selected`

### slider

- `aria-valuenow`
- 表示中のパーセンテージラベル

### combobox / autocomplete

- 入力欄の text
- 展開後の active option
- 選択済み label / chip

## 4. Fallback を分ける

次の順で fallback を考えます。

1. 直接 selector
2. placeholder / aria-label / name
3. label 近傍探索
4. container 起点の editable 探索
5. typing fallback や blur 後再確認

最初から複雑にせず、失敗理由が分かる順に積みます。

## 5. 失敗理由を混ぜない

最低限、次は分けてログに残します。

- `skip-empty`: canonical key 解決後も値が空
- `schema-missing`: source data に期待 key / alias が無い
- `field-not-found`: DOM 上で対象 field が見つからない
- `option-not-found`: toggle / radio の候補が見つからない
- `state-unverified`: クリック後の selected state が読めない
- `field-mismatch`: 入れた値と読み戻し値が一致しない

この分離がないと、data 側の問題を UI 側の問題と誤認しやすくなります。

## 6. Dry-run / Preflight Output を残す

mutating 前に出したいもの:

- canonicalized payload
- alias 解決結果
- required field の充足状況
- widget type 一覧
- 予定 verification method

これがあれば、ブラウザを触る前に `そもそも何を入れるつもりか` を確認できます。
