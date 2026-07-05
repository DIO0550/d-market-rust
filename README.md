# d-market-rust

Rust 開発向け Claude Code プラグインのマーケットプレイスリポジトリ。

Claude Code で Rust プロジェクトを開発する際に活用できるルール・ワークフロー系プラグインを提供する。

## プラグイン一覧

### rust-rules-plugin

Rust 開発における基本ルールを定義するプラグイン。

| スキル | 説明 |
|:--|:--|
| `implementation-workflow` | 実装フローのエントリーポイント。ブランチ運用、TDD サイクル、品質チェックの流れを定義 |
| `coding-standards` | コーディング規約。所有権・借用、エラーハンドリング、命名規則、不変性、並行・非同期、lint 抑制、設計ガイドライン（振る舞いの配置・型変換・重複排除。詳細は `references/design-guidelines.md`） |
| `tdd` | TDD Red-Green-Refactor サイクルのルール |
| `testing` | 単体テスト・統合テストの規約。テスト構造、モック方針、テストピラミッド |
| `setup` | プロジェクトの指示ファイルにスキル活用ガイドを追記するセットアップ |

### rust-workflow-plugin

Rust プロジェクトの操作をエージェント経由で実行するワークフロープラグイン。

| スキル | 説明 |
|:--|:--|
| `test` | `cargo test` によるテスト実行（エージェント経由） |
| `type-check` | `cargo check` による型チェック・コンパイル確認（エージェント経由） |
| `file-search` | Rust ファイル・シンボル検索（エージェント経由） |

| エージェント | 説明 |
|:--|:--|
| `test-agent` | テスト実行・結果解析を担当 |
| `type-check-agent` | 型チェック・コンパイルエラー解析を担当 |
| `file-search-agent` | ファイル名・コード・シンボル検索を担当 |

### rust-hooks-plugin

Rust ファイル編集後に品質チェックを自動実行する hooks プラグイン。

| hooks イベント | トリガー | 実行内容 |
|:--|:--|:--|
| `PostToolUse` | Write / Edit で `.rs` ファイルを変更 | `rustfmt --check` でフォーマット検査、`cargo clippy` で lint チェック（エラーは Claude にフィードバック） |
| `PreToolUse` | Bash で `git push` を実行 | `cargo fmt --all -- --check` と `cargo clippy -- -D warnings` を実行し、エラーがあれば push をブロック（Cargo プロジェクト以外ではスキップ） |

## ディレクトリ構成

```
d-market-rust/
├── .claude-plugin/
│   └── marketplace.json    # マーケットプレイス定義
├── plugins/
│   ├── rust-rules-plugin/
│   │   ├── plugin.json
│   │   └── skills/
│   │       ├── implementation-workflow/
│   │       ├── coding-standards/
│   │       │   └── references/     # 設計ガイドライン等の詳細リファレンス
│   │       ├── setup/
│   │       ├── testing/
│   │       └── tdd/
│   ├── rust-hooks-plugin/
│   │   ├── plugin.json
│   │   ├── hooks/
│   │   │   └── hooks.json
│   │   └── scripts/
│   │       ├── format-and-lint.sh
│   │       └── pre-push-check.sh
│   └── rust-workflow-plugin/
│       ├── plugin.json
│       ├── skills/
│       │   ├── test/
│       │   ├── type-check/
│       │   ├── file-search/
│       │   └── setup/
│       └── agents/
│           ├── test-agent.md
│           ├── type-check-agent.md
│           └── file-search-agent.md
├── CLAUDE.md
├── README.md
└── LICENSE
```

## ライセンス

MIT
