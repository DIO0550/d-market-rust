---
name: testing
description: 単体テストルール。モジュール内テスト、モック使用制限、パラメータ化テスト、テストピラミッドなどの規約を定義。Rustテスト実装時に参照。
---

# 単体テストルール

単体テスト実装における規約を定義するスキル。

## 基本ルール

- **網羅テスト**: 正常系・異常系・境界値のテストケースを作成（TDDと併用する場合、境界値テストの追加タイミングは `tdd` スキル参照）
- **振る舞いのテスト**: 実装詳細ではなく振る舞いを確認
- **モックは最小限**: 基本はモックを使用しない
- **テストケース名**: `test_<対象>_<条件>_<期待結果>` 形式・英語で命名（例: `test_login_with_invalid_email_returns_error`）
- **テスト内のunwrap/expect**: 使用してよい（本番コードの禁止事項の対象外）。失敗理由が分かるようメッセージ付き `expect()` を推奨

## テスト構造

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_login_with_valid_credentials_returns_token() {
        let result = login("test@example.com", "valid_password");
        let session = result.expect("valid credentials should succeed");
        assert!(!session.token.is_empty());
    }

    #[test]
    fn test_login_with_invalid_email_returns_error() {
        let result = login("invalid", "valid_password");
        assert!(matches!(result, Err(LoginError::InvalidEmail)));
    }
}
```

## assertの使い分け

- **値の比較**: `assert_eq!`（失敗時に左右の値が表示される）。比較する型には `PartialEq` と `Debug` を導出する
- **エラーバリアントの検証**: `assert!(matches!(result, Err(LoginError::InvalidEmail)))`。バリアントがフィールドを持ち完全一致を見たい場合は `assert_eq!` + `PartialEq` 導出
- **真偽の検証**: `assert!`。失敗時に状況が分かるようメッセージ引数を付ける

## テストヘルパー

```rust
#[cfg(test)]
mod tests {
    use super::*;

    // テスト用ヘルパー関数
    fn create_test_user() -> User {
        User {
            id: 1,
            name: "Test User".to_string(),
            email: "test@example.com".to_string(),
        }
    }

    #[test]
    fn test_user_display() {
        let user = create_test_user();
        assert_eq!(user.display_name(), "Test User");
    }
}
```

## パラメータ化テスト

同じ振る舞いに対する類似ケースが3件以上になったらパラメータ化を検討する。失敗時にどのケースか特定できるよう、アサーションにメッセージを必ず付ける。

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add_various_inputs() {
        let cases = vec![
            (1, 2, 3),
            (5, 5, 10),
            (-1, 1, 0),
            (0, 0, 0),
        ];

        for (a, b, expected) in cases {
            assert_eq!(add(a, b), expected, "add({}, {}) should be {}", a, b, expected);
        }
    }
}
```

## モックルール

### モック禁止対象
- 自作の関数・モジュール
- プロジェクト内のユーティリティ関数
- 内部状態管理ロジック

### モック許可対象
- HTTPリクエスト
- 外部API呼び出し
- ファイルシステムアクセス
- データベース接続
- 時間依存処理

## テストピラミッド

| レベル | 比率 | 対象 |
|:-|:-|:-|
| 単体テスト | 70-80% | 関数、メソッド、個別モジュール |
| 統合テスト | 15-25% | モジュール間連携、API統合 |
| E2Eテスト | 5-10% | ユーザーシナリオ全体 |

## ディレクトリ構成

```
src/
  lib.rs           # #[cfg(test)] mod tests { ... }
  user.rs          # 各モジュール内にテスト（mod.rsスタイルは使わない — coding-standards参照）
  user/
    profile.rs     # user::profile サブモジュール（テストも同ファイル内）
tests/
  integration_test.rs  # 統合テスト
```

## 適正化指針

- **重複テストの排除**: 同じ振る舞いを複数方法でテストしない
- **実装詳細のテスト禁止**: プライベート関数の直接テストは行わない
- **公開インターフェースのみテスト**: 外部から呼び出される関数に集中

## 関連スキル

- TDD: `tdd`
- 実装ワークフロー: `implementation-workflow`
