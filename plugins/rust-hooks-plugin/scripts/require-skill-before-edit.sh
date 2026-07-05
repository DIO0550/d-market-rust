#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"
file="$(jq -r '.tool_input.file_path // .tool_input.path // empty' <<< "$input")"

case "$file" in
  *.rs) ;;
  *) exit 0 ;;
esac

case "$file" in
  */plugin-workspace/*|*/.claude/*|*/plugins/*|*/target/*) exit 0 ;;
esac
case "$file" in
  plugin-workspace/*|.claude/*|plugins/*|target/*) exit 0 ;;
esac

session_id="$(jq -r '.session_id // empty' <<< "$input")"
[ -z "$session_id" ] && exit 0
session_id="$(echo "$session_id" | sed 's/[^a-zA-Z0-9_-]/_/g')"

gate_skills=("implementation-workflow" "coding-standards" "tdd" "testing")
marker_dir="${CLAUDE_PROJECT_DIR:-.}/plugin-workspace/skill-fired/${session_id}"

missing=()
for skill in "${gate_skills[@]}"; do
  [ -f "$marker_dir/$skill" ] || missing+=("$skill")
done

[ ${#missing[@]} -eq 0 ] && exit 0

missing_list=""
for skill in "${missing[@]}"; do
  missing_list="${missing_list}
- rust-rules-plugin:${skill}"
done

jq -n --arg missing "$missing_list" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: ("Rustファイルを編集する前に、全ての実装ルールスキルを読み込んでください。\n\n以下の未発火スキルを Skill ツールで実行してください:" + $missing)
  }
}'
