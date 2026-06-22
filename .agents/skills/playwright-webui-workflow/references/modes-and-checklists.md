# Modes And Checklists

## モード早見表

### read-only

使う場面:

- 情報取得が目的
- 内部 API を調べたい
- 一覧や詳細を md / json / html に落としたい

やること:

- DOM 観察
- Network 観察
- `GET` 中心の API 利用
- 出力ファイル作成

やらないこと:

- 保存
- 更新
- 削除
- 投稿

### safe-ui

使う場面:

- 検索やフィルタの動作確認
- ページ遷移やモーダル表示確認
- 保存しない UI テスト

やること:

- 画面遷移
- タブ切替
- フィルタ
- ソート
- モーダル表示

やらないこと:

- 状態変更を伴う保存操作

### mutating-test

使う場面:

- 保存を含む E2E テスト
- 作成 / 更新 / 削除の確認
- フォーム送信後の結果確認

開始前に確認:

- 本番ではないか
- テストデータ方針があるか
- 後始末方法が決まっているか
- 成功条件が定義されているか

## 実行前チェック

- 今回のモードは何か
- ブラウザ所有権は Playwright 管理ブラウザか、既存ブラウザ + CDP か
- 認証は誰が行うか
- どのページが対象か
- 到達条件は何か
- 完了条件は何か
- 出力先はどこか

## 一覧取得チェック

- UI 上の総件数表示はあるか
- 無限スクロールかページネーションか
- 実際にスクロールしている要素はどれか
- DOM から ID を拾えるか
- Network に JSON があるか
- 内部 API で詳細を再取得できるか
- 出力件数は UI 件数と合うか

## 動作確認チェック

- URL は合っているか
- 見出しや選択状態は合っているか
- 主要要素は表示されているか
- 保存を伴うか伴わないか
- 結果確認は DOM か Network か保存結果か

## 入力系 preflight チェック

- source data の canonical key は決まっているか
- alias を受けるなら解決順は決まっているか
- required field と optional field を分けたか
- `skip-empty` と `schema-missing` を区別しているか
- target field ごとの widget type を把握したか
- text / token / toggle / slider / combobox のどれで検証するか決めたか
- selector が外れた場合の fallback を決めたか
- 失敗理由を `field-not-found` / `state-unverified` まで分けるか

## フォーム反映チェック

- text / textarea は `.value` または textContent で読めるか
- tokenized input は chip 表示や近傍 container text で検証すべきではないか
- toggle / radio は `aria-pressed` / `aria-selected` / `aria-checked` / `data-state` を見ているか
- slider は `aria-valuenow` を見ているか
- combobox は選択済みラベルまで読めているか
- 反映失敗が `データ不足` なのか `selector 不一致` なのか `verification 不適合` なのか切り分けられているか

## よくあるつまずき

- 待機条件が厳しすぎて永遠に待つ
- `window` をスクロールしていて、本当の一覧が動いていない
- DOM や Network から拾った候補に対象外データが混ざる
- UI 件数と出力件数を照合していない
- 前回の出力が残っていて件数がずれる
- 自動化ブラウザが危険扱いされているのに、既存ブラウザ + CDP へ切り替えない
- 処理は終わっているのに終了ログや終了処理がなく、止まって見える
- 入力失敗を selector 問題と決めつけ、source data 側の key mismatch を見落とす
- tokenized input を通常の textarea と同じ `.value` 検証で扱い、実際は入っているのに失敗扱いする

## 報告テンプレート

- モード:
- ブラウザ所有権:
- 認証担当:
- 今の段階:
- source contract:
- widget type:
- 待っている条件:
- 見つかった件数:
- 次の処理:
- 完了条件:
