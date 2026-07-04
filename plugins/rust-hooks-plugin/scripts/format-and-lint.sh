#!/bin/bash

# Read hook input from stdin
input=$(cat /dev/stdin)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Skip if not a .rs file
if [[ "$file_path" != *.rs ]]; then
  exit 0
fi

# 編集されたファイルが属する Cargo プロジェクトを探す
project_dir=$(dirname "$file_path")
while [[ "$project_dir" != "/" && ! -f "$project_dir/Cargo.toml" ]]; do
  project_dir=$(dirname "$project_dir")
done

nl=$'\n'
errors=""

# Check format on the edited file
if command -v rustfmt &>/dev/null; then
  fmt_output=$(rustfmt --check "$file_path" 2>&1)
  if [[ $? -ne 0 ]]; then
    errors+="[rustfmt --check failed for ${file_path}]${nl}${fmt_output}${nl}"
  fi
fi

# Run cargo clippy in the file's project directory
# パイプで head に繋ぐと $? が head の終了コードになるため、実行してから切り詰める
if command -v cargo &>/dev/null && [[ -f "$project_dir/Cargo.toml" ]]; then
  clippy_output=$(cd "$project_dir" && cargo clippy -- -D warnings 2>&1)
  if [[ $? -ne 0 ]]; then
    clippy_output=$(echo "$clippy_output" | head -50)
    errors+="[cargo clippy failed]${nl}${clippy_output}${nl}"
  fi
fi

# If errors found, feed back to Claude via additionalContext
if [[ -n "$errors" ]]; then
  context="フォーマットまたはlintエラーがあります。次のアクションで修正してください。${nl}${errors}"
  jq -n --arg ctx "$context" '{
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "additionalContext": $ctx
    }
  }'
fi

exit 0
