# Rust設計ガイドライン（リファレンス）

コードの構造・配置に関する設計判断の詳細な基準とコード例。要点は `coding-standards` スキル本体の「設計ガイドライン」セクションを参照。

## 振る舞いの配置 — 基本は impl

型に紐づく振る舞い・生成・変換は impl のメソッド/関連関数にまとめる（Rust API Guidelines C-METHOD / C-CTOR / C-CONV）。

- コンストラクタは関連関数 `new`。`make_user()` のような自由関数は作らない
- 型変換は `as_` / `to_` / `into_` プレフィックスのメソッドで提供する
- struct のフィールドを丸ごと引数で受ける自由関数は、impl に入れるべきサイン

自由関数が正当になる例外：

- **借用分割の回避**: `&mut self` はシグネチャだけで構造体全体の排他借用と判定されるため、別々のフィールドへの並行アクセスでも E0499 になる。必要なフィールドだけを個別引数で受ける自由関数への切り出しは正当な設計判断
- **型と結びつかない純粋計算**（例: `fn clamp(x: f64, lo: f64, hi: f64) -> f64`）
- **FFI**: `extern "C"` の公開関数はトップレベル自由関数が必須

```rust
// ❌ 借用分割で詰まる: self 全体が可変借用扱いになり E0499
impl Parser {
    fn step(&mut self) {
        let tok = self.lexer.next();
        self.state = transition(tok);
    }
}

// ✅ 必要なフィールドだけ個別借用する自由関数に切り出す
fn advance(lexer: &mut Lexer, state: &mut State) {
    let tok = lexer.next();
    *state = transition(tok);
}
```

## ファイル肥大化の分割 — impl ブロックを複数ファイルへ

ファイルが肥大化しても「struct はデータだけにして自由関数群に開く」方向は取らない（名前空間・auto-ref・rustdoc の発見可能性を失い、貧血ドメインモデル化する）。

Rust は同一型への inherent impl を複数ファイルに分割できるため、**責務ごとに impl ブロックを別ファイルへ分ける**のが慣用パターン。

```rust
// src/user.rs — 型定義とサブモジュール宣言
mod validation;
mod serialization;

pub struct User {
    pub name: String,
    pub email: String,
}

impl User {
    pub fn new(name: String, email: String) -> Self { ... }
}
```

```rust
// src/user/validation.rs — バリデーション系の impl
use super::User;

impl User {
    pub fn validate(&self) -> Result<(), ValidationError> { ... }
}
```

呼び出し側は `user.validate()` とメソッドの見た目のまま使える。

## 型変換 — From を実装し、置き場所で依存方向を制御

- `impl Into` は書かない（clippy `from_over_into`）。`From` を実装すれば `Into` は自動で手に入る
- 失敗しうる変換は `TryFrom`（`TryInto` が自動で付く）
- 呼び出しは、引数渡しなど変換先が文脈から決まる場面では `.into()`、変換を強調したい単独行では `Type::from(x)` を使い分ける

trait impl は型定義と別のクレート・モジュールに置ける。**依存の向きを決めるのは impl の置き場所**であり、型の組み合わせではない。

外部 DTO → ドメイン型の変換は、**DTO 側（外側）のクレート・モジュールに置く**。ドメイン側は DTO を一切知らずに済み、孤児ルールも DTO がローカル型なので満たされる。

```rust
// ✅ api-client 側に置く（api-client → domain の依存だけが残る）
use domain::User;

impl From<ApiUser> for User {
    fn from(api: ApiUser) -> User {
        User::new(api.id as u64, api.full_name)
    }
}

// ❌ 同じ impl を domain 側に置くと domain → api-client の依存逆流になる
```

## enum の命名 — 概念名そのものを使う

- `~Result` サフィックスは `std::result::Result` のエイリアス専用（例: `io::Result`）。成功/失敗を意味しない enum に付けない
- 処理の結末・分岐を表す enum には `~Result` / `~Outcome` / `~Status` のような汎用サフィックスを付けず、std スタイルで**その概念を表す名詞そのもの**を型名にする（参考: `ControlFlow`, `Ordering`, `Poll`, `Entry`, `Cow`）

```rust
// ❌ Result と勘違いされる
enum TomlEditResult { Changed(String), Unchanged, SkippedFalse }

// ✅ 概念名そのもの
enum TomlEdit { Changed(String), Unchanged, SkippedFalse }
```

## 重複排除の手段 — 弱い順に検討する

重複を消す手段は役割が違う。**上から順に検討し、足りなければ一段降りる**。下ほど強力だが、複雑さ・ビルド時間・読みにくさのコストが上がる。

| 順序 | 手段 | 使う場面 |
|:-|:-|:-|
| 1 | 関数 | ロジックが共通。まずこれで考える |
| 2 | ジェネリクス + トレイト境界 | 型だけが違う共通処理 |
| 3 | トレイトのデフォルト実装 | 共通の振る舞いがあり差分だけ書きたい |
| 4 | `const fn` | コンパイル時に**値**が欲しい |
| 5 | 宣言マクロ（`macro_rules!`） | 型・識別子まで引数にして関数定義や impl の**コード**を生成したい |
| 6 | 手続き型マクロ | `#[derive]` など構造体定義を解析した自動実装（別クレート必須） |
| 7 | build.rs | 外部データ・スキーマからのコード生成 |

判断の目安: **「値が欲しいなら `const fn`、コードが欲しいならマクロ」**。ジェネリクスで吸収できるのは型違いまでで、関数名・フィールド名まで違うならマクロを検討する。
