---
name: coding-standards
description: Rust基本実装ルール。所有権、エラーハンドリング、命名規則、不変性などのコーディング規約を定義。実装時に参照すべき基本ルールを提供する。
---

# Rust基本実装ルール

Rust開発における基本的なコーディング規約を定義するスキル。

## 基本方針

- 早期returnでネストを浅くする
- `cargo clippy --all-targets -- -D warnings` の警告をすべて解消する（テストコードも対象）
- `rustfmt` でフォーマットを統一
- マジックナンバーは使用せず定数を定義（数値だけでなく `'='` のような意味を持つ文字リテラルも対象。`+1` のような自明なオフセットまで定数化する必要はない）

## 一般原則

- **単一責任の原則**: 関数・モジュールは「1つのこと」に集中
- **所有権を意識**: 必要最小限の借用、可能な限り参照を使用
- **不変性を優先**: `let` を基本、`mut` は必要な場合のみ
- **明示的なインターフェース**: `pub` は最小限に
- **命名は意図を表現**: 略語・あいまい語を避け、ドメイン語彙を使用

## 所有権と借用

```rust
// ✅ 参照を優先
fn process(data: &str) -> String { ... }

// ❌ 不必要な所有権の移動
fn process(data: String) -> String { ... }

// ✅ 変更が必要な場合のみ可変参照
fn update(data: &mut Vec<i32>) { ... }
```

## エラーハンドリング

```rust
// ✅ Result型を使用
fn parse_config(path: &str) -> Result<Config, ConfigError> { ... }

// ✅ ?演算子で伝播
fn load_data() -> Result<Data, Error> {
    let config = parse_config("config.toml")?;
    let data = fetch_data(&config)?;
    Ok(data)
}

// ❌ unwrap/expectの乱用
let value = result.unwrap(); // パニックの可能性

// ✅ 適切なエラー処理
let value = result.map_err(|e| CustomError::from(e))?;
```

`unwrap()` / `expect()` の禁止は**本番コード（非テストコード）のみ**が対象。`#[cfg(test)]` 内・doctestでは使用してよい（失敗理由が分かるようメッセージ付きの `expect()` を推奨）。

## エラー型の設計

エラー型の実装方法は、クレートの性質で使い分ける：

- **ライブラリ・共有クレート**: 呼び出し側が `match` で分岐できるよう、独自の `enum` エラー型を定義する。実装は `thiserror` を推奨（依存を増やせない場合は `Display` + `std::error::Error` を手書き）
- **アプリケーションの末端（main近く）**: 分岐の必要がないエラー伝播には `anyhow` を使用してよい

```rust
// ✅ ライブラリ: thiserrorによる独自エラー型
#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    #[error("invalid line {line}: {content}")]
    InvalidLine { line: usize, content: String },
    #[error("failed to read config file")]
    Io(#[from] std::io::Error),
}
```

設計の指針：
- エラーには診断に必要なコンテキスト（行番号、対象名など）をフィールドで持たせる
- 原因となったエラーは握りつぶさず `#[from]` / `source()` でチェーンする
- エラーメッセージ（`Display`）は英語で書く（ツール・ログとの親和性のため）

## 依存クレートの追加

- 標準ライブラリで無理なく実現できるものは標準ライブラリを優先する
- 追加する場合はデファクトの定番クレート（`thiserror`, `serde`, `clap` など）を選び、選定理由を説明できること
- 迷う場合や大きな依存（asyncランタイムなど）を新規導入する場合はユーザーに確認する

## 型定義

```rust
// ✅ 型エイリアスで意図を明確に
type UserId = u64;
type Result<T> = std::result::Result<T, AppError>;

// ✅ newtypeパターンで型安全性
struct Email(String);
struct Password(String);
```

`Result<T>` エイリアスは、同一エラー型を返す関数が多いモジュール（またはクレートルート）に1つ定義する。関数が2〜3個しかない小さなモジュールで無理に定義する必要はない。

## deriveとcloneの指針

- 公開型には `#[derive(Debug)]` を必ず付ける（デバッグ・テストの前提）
- テストで比較する型には `PartialEq`（必要なら `Eq`）を導出する
- `Clone` / `Default` は実際に必要になってから付ける
- `clone()` の呼び出しは「所有権が本質的に複数箇所で必要」な場合のみ許容。借用・`Cow`・`Rc/Arc` で回避できるなら回避する。テストコードでの `clone()` は許容

## 命名規則

| 種類 | 規則 | 例 |
|:-|:-|:-|
| 構造体・列挙型・トレイト | PascalCase | `UserAccount`, `ParseError` |
| 関数・変数・モジュール | snake_case | `parse_config`, `user_name` |
| 定数 | SCREAMING_SNAKE_CASE | `MAX_CONNECTIONS` |
| ライフタイム | 短い小文字 | `'a`, `'de` |

## Option/Resultの扱い

```rust
// ✅ コンビネータを活用
let name = user.name.as_ref().map(|n| n.to_uppercase());

// ✅ if letで簡潔に
if let Some(value) = optional {
    process(value);
}

// ✅ matchで網羅的に
match result {
    Ok(value) => handle_success(value),
    Err(e) => handle_error(e),
}
```

## コメントルール

- **docコメント**: `///` で公開APIにはdocコメントを記載。`Result` を返す公開関数には `# Errors` セクションを付ける
- **docコメントの言語**: プロジェクトの既存慣習に合わせる（慣習がなければ日本語でよい）
- **実装の意図**: 特別な理由で実装している箇所はコメントを記載
- **その他**: 上記以外はコメントを記載しない

## モジュール構成

```rust
// ✅ ファイル名ベースのモジュール定義（Rust 2018+推奨）
// src/
//   lib.rs
//   config.rs        ← config モジュール本体
//   config/
//     parser.rs      ← config::parser サブモジュール

// ❌ mod.rs スタイルは使用しない
// src/
//   config/
//     mod.rs          ← 古いスタイル
//     parser.rs

// ✅ 公開範囲を最小限に
pub(crate) fn internal_helper() { ... }
pub fn public_api() { ... }
```

## 禁止事項

- `unsafe` の不必要な使用
- `clone()` の乱用（パフォーマンス低下。許容基準は「deriveとcloneの指針」参照）
- `unwrap()` / `expect()` の本番コードでの使用（テストコードは対象外）
- `#[allow(...)]` によるclippy警告の無効化。clippyの提案がAPI設計上どうしても不適切な場合に限り、理由コメントを添えて最小スコープ（項目単位）で許可する
