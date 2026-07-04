# スキル評価レポート（2026-07-04）

d-market-skill の `skill-evaluator` スキルの手法に基づき、本リポジトリの全プラグイン（スキル・エージェント・hooks）を評価した記録。

## 評価方法

- **実行ベース評価**: 各スキルを「スキルとして与えられたAI（サブエージェント）」に渡し、典型タスク（median）を実際に実行させ、`execution_report`（不明瞭点 `ambiguity_points`・裁量補完 `discretionary_fills`）を収集
  - coding-standards: 設定パーサモジュールの実装（fmt/clippy/test全パス）
  - tdd + testing: パスワードバリデータのTDD実装（4サイクル、Red/Greenをcargo testの実出力で確認）
  - implementation-workflow: FizzBuzz追加をブランチ作成〜コミットまで完走
  - rust-workflow-plugin: エージェント定義記載の全コマンドを実プロジェクトで実行検証
- **コード採点**: hooksスクリプトは実際に入力を与えて動作検証（機械的に検証できるものはコード採点を優先）
- **回帰スイート**: 評価で作成したテストケースを各スキルの `evals/evals.json` にコミットし、今後のスキル修正時の回帰チェックに使用する

## 主な発見と対応

### 重大（バグ・構造的欠陥）

| 発見 | 対応 |
|:--|:--|
| **hooks: pre-push-check.sh が機能していなかった** — `$(cargo ... \| head -50)` 直後の `$?` はパイプ末尾 `head` の終了コード（常に0）となり、fmt/clippy失敗を検出できずpushを一切ブロックしない（実行で確認） | パイプを分離して終了コードを正しく捕捉。修正後にブロック動作を実機確認 |
| **hooks: format-and-lint.sh のclippy側も同じパイプバグ**。またclippyがフック実行時のcwdで走るため、編集ファイルのプロジェクト外だと誤動作。エラーメッセージの `\n` がリテラル出力 | 終了コード捕捉を修正、編集ファイルから `Cargo.toml` を遡って探索しそのディレクトリで実行、`$'\n'` に修正 |
| **hooks: 非Rustリポジトリのpushもブロックし得る**（cargo fmtが「Cargo.tomlなし」で失敗扱い） | `Cargo.toml` がなければスキップするガードを追加 |
| **workflow: エージェント参照が解決不能** — 3スキルとも「`agents/*.md` の指示に従え」とサブエージェントに指示するが、サブエージェントは親コンテキストを引き継がず、cwd（ユーザープロジェクト）から相対パスも解決できないため、手順書が届く経路が存在しなかった | agents/*.md にYAMLフロントマターを追加してカスタムエージェント化し、SKILL.md から `subagent_type` で直接指定する方式に変更 |
| **implementation-workflow: 参照断絶** — `commit`／`pull-request` スキル（git-workflow-plugin）が本マーケットプレイスに存在しない | 参照を削除し、コミット規約（Conventional Commits）をスキル内に直接定義 |

### スキル間の矛盾

| 発見 | 対応 |
|:--|:--|
| testing の「ディレクトリ構成」例が `user/mod.rs` を使用。coding-standards は mod.rs スタイルを明確に禁止 | testing の例を `user.rs` + `user/profile.rs` 形式に修正 |
| testing のサンプルが `result.unwrap()`・`len() > 0` を使用（unwrap禁止・clippy::len_zero と緊張） | サンプルを `expect()` + `is_empty()` に修正し、テストコードでのunwrap/expect可を両スキルに明文化 |
| tdd の「失敗するテストを書く」と testing の「網羅テスト（境界値）」が両立不能（実装後の境界値テストはRedにできない） | 境界値テストは最後のRefactorで回帰テストとして追加する旨をtddに明記 |

### 不足していたルール（追加）

- **coding-standards**: エラー型の設計（ライブラリ=thiserror/手書き、アプリ末端=anyhow可、コンテキスト保持、sourceチェーン）、依存クレート追加ルール、derive指針（Debug必須等）、clone許容基準、`Result<T>`エイリアスの運用、docコメントの言語と `# Errors`、clippyの実行コマンド明記、`#[allow]` の例外規定
- **tdd**: サイクル粒度（1振る舞い=1サイクル）、RustにおけるRedの定義（コンパイルエラー含む）、Refactorの具体的観点、既存コードへのテスト追加の扱い、雛形コードの扱い
- **testing**: テスト命名規約の明文化、assertの使い分け（assert_eq!/matches!/assert!）、パラメータ化の適用基準
- **implementation-workflow**: コミット規約、自律実行環境での承認フォールバック、チェックリストの運用方法、git未初期化時の手順、clippyの推奨フラグ
- **test-agent / type-check-agent**: Cargo.toml探索・ワークスペースの扱い、RUST_BACKTRACE=1、テスト0件/コンパイル失敗/警告のみの報告方法、誤情報の修正（`--package`はモジュール単位ではない、`head -100`は厳密チェックではない）

### その他の修正

- rust-rules-plugin / rust-workflow-plugin の plugin.json `repository` が別リポジトリ（d-market）を指していたのを修正
- rust-workflow-plugin の plugin.json description に file-search を追記
- README / CLAUDE.md に pre-push フックの記載を追加（実装済みなのに未記載だった）

## バージョン

| プラグイン | 変更 |
|:--|:--|
| rust-rules-plugin | 1.0.0 → 1.1.0（ルール追加・矛盾修正・evals追加） |
| rust-workflow-plugin | 1.0.0 → 1.1.0（カスタムエージェント化・エージェント定義拡充） |
| rust-hooks-plugin | 1.0.0 → 1.0.1（バグ修正） |

## 今後の評価の回し方

1. スキルを修正したら、該当スキルの `evals/evals.json` のケース（`holdout: false`）を新規サブエージェントで実行する
2. `execution_report` の不明瞭点・裁量補完を収集し、最もインパクトの大きい1テーマだけ修正する（1イテレーション1テーマ）
3. 収束判定（新規不明瞭点0・パス率向上≤3pt が連続2回）後、`holdout: true` のケースで過適合を検出する
