# CLAUDE.md

このリポジトリは Rust 開発向け Claude Code プラグインのマーケットプレイスである。Rust のソースコードは含まない。

## リポジトリの構成

- `plugins/` 配下に各プラグインを格納
- 各プラグインは `plugin.json`、`skills/`、必要に応じて `agents/` を持つ
- `.claude-plugin/marketplace.json` がマーケットプレイス全体の定義

## 開発ルール

- プラグインのスキルは `skills/<スキル名>/SKILL.md` に記述する
- エージェントは `agents/<エージェント名>.md` に記述する
- 新しいプラグインやスキルを追加した場合は `marketplace.json` と `README.md` を更新する
- ドキュメントは日本語で記述する
