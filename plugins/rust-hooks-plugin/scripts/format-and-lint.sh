#!/bin/bash

# Read hook input from stdin
input=$(cat /dev/stdin)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Skip if not a .rs file
if [[ "$file_path" != *.rs ]]; then
  exit 0
fi

errors=""

# Check format on the edited file
if command -v rustfmt &>/dev/null; then
  fmt_output=$(rustfmt --check "$file_path" 2>&1)
  if [[ $? -ne 0 ]]; then
    errors+="[rustfmt --check failed for ${file_path}]\n${fmt_output}\n"
  fi
fi

# Run cargo clippy
if command -v cargo &>/dev/null; then
  clippy_output=$(cargo clippy 2>&1 | head -50)
  if [[ $? -ne 0 ]]; then
    errors+="[cargo clippy failed]\n${clippy_output}\n"
  fi
fi

# If errors found, feed back to Claude via additionalContext
if [[ -n "$errors" ]]; then
  context="フォーマットまたはlintエラーがあります。次のアクションで修正してください。\n${errors}"
  jq -n --arg ctx "$context" '{
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "additionalContext": $ctx
    }
  }'
fi

exit 0
