---
name: skill-update
description: ワークスペース内の複数プロジェクトから .agents/skills（Codex）・.claude/skills（Claude Code）・.github/skills（GitHub Copilot）・旧 .agent/skills を収集し、turtle-skills-neo へ新規追加・差分更新・同名スキルの新旧判定とマージを行うスキル。正本は .agents/skills、ミラーは .claude/skills と .github/skills。「スキルアップデート」「スキル更新」「skills update」「turtle-skills-neo 更新」「ワークスペースのスキルを集約」「.agents/skills を収集」「.claude/skills を収集」「.github/skills を収集」などで発火。
---

# Skill Update

## スキル読み込み通知

このスキルが読み込まれたら、必ず以下の通知をユーザーに表示してください：

> **Skill Update スキルを読み込みました**  
> ワークスペース内の Agent Skills を収集し、turtle-skills-neo に安全に集約・更新します。

## When to Use

- ユーザーが「スキルアップデート」「スキル更新」と依頼したとき
- 複数プロジェクト配下の `.agents/skills` / `.claude/skills` / `.github/skills`（および旧 `.agent/skills`）を棚卸ししたいとき
- `turtle-skills-neo` に未収録のスキルを追加したいとき
- 同名スキルの差分を確認し、新しそうな内容だけを反映したいとき
- 既存の `turtle-skills-neo/.agents/skills` / `.claude/skills` / `.github/skills` を同期したいとき

## 概要

このスキルは、ワークスペース直下または配下にあるプロジェクトの `.agents/skills` / `.claude/skills` / `.github/skills`（後方互換として旧 `.agent/skills` も）を収集し、`turtle-skills-neo` に集約する。更新はファイル単位で行い、ターゲットにしか存在しないスキルは削除しない。

実行ロジックは `scripts/update-turtle-skills.ps1` にまとめてある。マージ判断の詳細は [references/merge-policy.md](references/merge-policy.md) を読む。

## 手順

### Step 1: 対象の確認

既定では、このスキルが置かれている `turtle-skills-neo` をターゲットとし、その親フォルダをワークスペースとして扱う。コマンドは `turtle-skills-neo` 直下で実行するか、スクリプトパスを絶対パスで指定する。

明示する場合：

```powershell
powershell -ExecutionPolicy Bypass -File .agents/skills/skill-update/scripts/update-turtle-skills.ps1 -WorkspaceRoot C:\git_home -TargetRoot C:\git_home\turtle-skills-neo
```

### Step 2: ドライラン

まず `-Apply` なしで実行し、追加・更新・競合数を確認する。

```powershell
powershell -ExecutionPolicy Bypass -File .agents/skills/skill-update/scripts/update-turtle-skills.ps1
```

ドライランではファイルを書き換えない。結果に `ConflictingFiles` が出た場合は、必要に応じて `.skills-aggregation-manifest.json` と `.skill-variants/` を確認する。

### Step 3: 更新の適用

ユーザーが更新を求めている場合は、ドライラン後に `-Apply` で適用する。

```powershell
powershell -ExecutionPolicy Bypass -File .agents/skills/skill-update/scripts/update-turtle-skills.ps1 -Apply
```

適用時の動作：

- `.agents/skills` を正本として追加・更新する
- `.claude/skills` と `.github/skills` に `.agents/skills` の内容をミラーする
- 同名スキルの同一相対パスに複数内容がある場合は、選定した版を正本に置く
- 非採用の差分版は `.skill-variants/{skill}/{hash}/...` に保存する
- `.skills-aggregation-manifest.json` に採用元、非採用版、ターゲットのみのスキルを記録する

### Step 4: 検証

更新後に以下を確認する。

```powershell
Get-ChildItem .agents/skills -Directory | Measure-Object
Get-ChildItem .claude/skills -Directory | Measure-Object
Get-ChildItem .github/skills -Directory | Measure-Object
powershell -ExecutionPolicy Bypass -File .agents/skills/skill-update/scripts/update-turtle-skills.ps1
```

最後のドライランで不要な更新が大量に残る場合は、manifest の `chosenSource` と `.skill-variants` を確認する。

## 注意

- ターゲット配下のスキルは収集元から除外する。自己取り込みで差分が膨らむのを防ぐため。
- ターゲットにしかないスキルは削除しない。例えば `skill-update` 自身はそのまま残る。
- 破壊的なリセットや削除は行わない。
- 新旧判定は絶対ではない。Git の最終コミット日時、ファイル更新日時、ファイルサイズ、同一内容の出現数を組み合わせて判断する。

## 参照ドキュメント

- [references/merge-policy.md](references/merge-policy.md) — 同名スキルと競合ファイルの選定・保存方針
- [scripts/update-turtle-skills.ps1](scripts/update-turtle-skills.ps1) — 収集・差分更新・ミラー処理の実行スクリプト
