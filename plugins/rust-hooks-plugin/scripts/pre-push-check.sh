#!/bin/bash

# Read hook input from stdin
input=$(cat /dev/stdin)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Skip if not a git push command
if [[ "$command" != *"git push"* ]]; then
  exit 0
fi

# Rust プロジェクト以外の push はブロックしない
if [[ ! -f "Cargo.toml" ]]; then
  exit 0
fi

nl=$'\n'
errors=""

# Run cargo fmt --all -- --check
# パイプで head に繋ぐと $? が head の終了コードになり失敗を検出できないため、実行してから切り詰める
if command -v cargo &>/dev/null; then
  fmt_output=$(cargo fmt --all -- --check 2>&1)
  if [[ $? -ne 0 ]]; then
    fmt_output=$(echo "$fmt_output" | head -50)
    errors+="[cargo fmt --all -- --check failed]${nl}${fmt_output}${nl}"
  fi
fi

# Run cargo clippy -- -D warnings
if command -v cargo &>/dev/null; then
  clippy_output=$(cargo clippy -- -D warnings 2>&1)
  if [[ $? -ne 0 ]]; then
    clippy_output=$(echo "$clippy_output" | head -50)
    errors+="[cargo clippy -- -D warnings failed]${nl}${clippy_output}${nl}"
  fi
fi

# If errors found, block the push
if [[ -n "$errors" ]]; then
  context="push前チェックでエラーが検出されました。修正してからpushしてください。${nl}${errors}"
  jq -n --arg ctx "$context" '{
    "decision": "block",
    "reason": $ctx
  }'
  exit 0
fi

exit 0
