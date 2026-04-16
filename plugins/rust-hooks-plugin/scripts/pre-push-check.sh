#!/bin/bash

# Read hook input from stdin
input=$(cat /dev/stdin)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Skip if not a git push command
if [[ "$command" != *"git push"* ]]; then
  exit 0
fi

errors=""

# Run cargo fmt --all -- --check
if command -v cargo &>/dev/null; then
  fmt_output=$(cargo fmt --all -- --check 2>&1 | head -50)
  if [[ $? -ne 0 ]]; then
    errors+="[cargo fmt --all -- --check failed]\n${fmt_output}\n"
  fi
fi

# Run cargo clippy -- -D warnings
if command -v cargo &>/dev/null; then
  clippy_output=$(cargo clippy -- -D warnings 2>&1 | head -50)
  if [[ $? -ne 0 ]]; then
    errors+="[cargo clippy -- -D warnings failed]\n${clippy_output}\n"
  fi
fi

# If errors found, block the push
if [[ -n "$errors" ]]; then
  context="push前チェックでエラーが検出されました。修正してからpushしてください。\n${errors}"
  jq -n --arg ctx "$context" '{
    "decision": "block",
    "reason": $ctx
  }'
  exit 0
fi

exit 0
