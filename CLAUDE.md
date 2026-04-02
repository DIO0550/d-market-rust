# CLAUDE.md

## リポジトリ概要

**d-market-rust** は Rust 開発向け Claude Code プラグインのマーケットプレイスリポジトリである。

Claude Code で Rust プロジェクトを開発する際に活用できるルール・ワークフロー・hooks 系プラグインを提供する。Rust のソースコードは含まず、プラグイン定義（スキル、エージェント、hooks）のみで構成される。

## 提供プラグイン

| プラグイン | 概要 |
|:--|:--|
| `rust-rules-plugin` | コーディング規約、TDD、テスト規約、実装ワークフローなど Rust 開発の基本ルールを定義 |
| `rust-workflow-plugin` | テスト実行・型チェック・ファイル検索をエージェント経由で実行するワークフロー |
| `rust-hooks-plugin` | `.rs` ファイル編集後に `rustfmt` と `cargo clippy` を自動実行する hooks |

## リポジトリの構成

- `plugins/` 配下に各プラグインを格納
- 各プラグインは `plugin.json`、`skills/`、必要に応じて `agents/` を持つ
- `.claude-plugin/marketplace.json` がマーケットプレイス全体の定義

## 開発ルール

- プラグインのスキルは `skills/<スキル名>/SKILL.md` に記述する
- エージェントは `agents/<エージェント名>.md` に記述する
- 新しいプラグインやスキルを追加した場合は `marketplace.json` と `README.md` を更新する
- ドキュメントは日本語で記述する
