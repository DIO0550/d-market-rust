#!/bin/bash

# Extract file path from TOOL_INPUT
file_path=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')

# Skip if not a .rs file
if [[ "$file_path" != *.rs ]]; then
  exit 0
fi

# Check format on the edited file
if command -v rustfmt &>/dev/null; then
  rustfmt --check "$file_path" 2>&1
fi

# Run cargo clippy
if command -v cargo &>/dev/null; then
  cargo clippy 2>&1 | head -50
fi
