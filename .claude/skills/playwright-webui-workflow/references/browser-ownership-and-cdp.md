# Browser Ownership And CDP

## これは何のためのメモか

Playwright で詰まりやすいのは、操作そのものよりも「どのブラウザを誰が持つか」です。
ここでは、Playwright 管理ブラウザと既存ブラウザ + CDP の使い分けを整理します。`r`n`r`n認証が絡むページでは、`警告が出たら CDP に切り替える` より `最初から CDP-first にする` 方が実務では安定します。

## 2 つの持ち方

### Playwright 管理ブラウザ

向いている場面:

- 公開ページやログイン不要ページ
- テスト専用環境
- 完全自動 E2E
- 認証が自動化ブラウザで問題なく通る

利点:

- Playwright だけで起動から終了まで閉じられる
- 再現しやすい
- テストコードにまとめやすい

弱点:

- Google、Microsoft、Okta などで自動化ブラウザが警戒されることがある
- 新規プロファイル扱いでログインが通りにくいことがある

### 既存ブラウザ + CDP

向いている場面:

- ログイン、2FA、CAPTCHA は人間が行う
- 既存ブラウザのセッションやパスキーを使いたい
- Google などで「安全ではない」と出る
- ログイン後のページ確認や read-only 取得が主目的

利点:

- 普段使うブラウザに近い条件で認証できる
- 既存セッションをそのまま使える
- 認証後だけ Playwright に渡せる

弱点:

- ブラウザ起動と終了がユーザー管理になりやすい
- 接続前提の確認が増える

## 切り替え条件

次のどれかが出たら、Playwright 管理ブラウザに固執せず CDP へ切り替えます。

- 「このブラウザまたはアプリは安全ではありません」などの警告
- ログインページで自動化ブラウザや新規プロファイルが弾かれる
- 既存の Cookie、パスキー、認証済みセッションを使いたい
- 主目的がログイン後の read-only 観測や取得

## 汎用フロー

1. 通常の Edge / Chrome を `--remote-debugging-port=9222` 付きで起動する
2. 必要なら専用プロファイルで起動する
3. `127.0.0.1:9222` が開いていることを確認する
4. Playwright は `--cdp-url=http://127.0.0.1:9222` で接続する
5. ユーザーが手動ログインし、対象ページを開く
6. Playwright は取得や確認だけを行う

## Windows 例

```powershell
Start-Process -FilePath 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe' -ArgumentList '--remote-debugging-port=9222','https://example.com/'
```

```powershell
Start-Process -FilePath 'C:\Program Files\Google\Chrome\Application\chrome.exe' -ArgumentList '--remote-debugging-port=9222','https://example.com/'
```

```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 9222
```

```text
--cdp-url=http://127.0.0.1:9222
```

## ガードレール

- ログイン、2FA、CAPTCHA の肩代わりはしない
- CDP 接続後も、保存や更新はモードに応じて制限する
- CDP モードではブラウザをユーザー所有として扱い、終了時に勝手に閉じない
- 既存ブラウザの実プロファイルを直接使うより、必要に応じて専用プロファイルを使う