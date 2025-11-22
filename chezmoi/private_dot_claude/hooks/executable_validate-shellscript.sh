#!/usr/bin/env bash
set -euo pipefail

# Validate shell scripts with shellcheck (PreToolUse and PostToolUse)
# PreToolUse: Validates content from tool input before write
# PostToolUse: Validates file on disk after write
# Exit codes: 0 = pass, 2 = fail

# Get file path from environment or first argument
FILE_PATH="${CLAUDE_FILE_PATH:-${1:-}}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Skip Fish scripts by extension
case "$FILE_PATH" in
    *.fish)
        exit 0
        ;;
    *)
        # Continue - might still be a shell script or Fish with .sh extension
        ;;
esac

# Check if shellcheck is available
if ! command -v shellcheck >/dev/null 2>&1; then
    echo "⚠️  shellcheck not found, skipping validation" >&2
    echo "Install: brew install shellcheck" >&2
    exit 0
fi

# Determine validation mode and file to check
CHECK_FILE=""
CLEANUP_TEMP=false
CONTENT=""

if [[ -n "$TOOL_INPUT" ]]; then
    # PreToolUse mode: Extract content from tool input
    CONTENT=$(echo "$TOOL_INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null || echo "")

    if [[ -z "$CONTENT" ]]; then
        # For Edit operations, we can't easily get the final content
        # Skip PreToolUse validation for Edit
        exit 0
    fi

    # Create temp file with content
    TEMP_FILE=$(mktemp)
    echo "$CONTENT" > "$TEMP_FILE"
    CHECK_FILE="$TEMP_FILE"
    CLEANUP_TEMP=true
elif [[ -f "$FILE_PATH" ]]; then
    # PostToolUse mode: Check file on disk
    CHECK_FILE="$FILE_PATH"
    CONTENT=$(cat "$FILE_PATH")
else
    # File doesn't exist and no tool input
    exit 0
fi

# Check shebang to detect Fish scripts with .sh extension
if [[ -n "$CONTENT" ]]; then
    SHEBANG=$(echo "$CONTENT" | head -n 1)
    if echo "$SHEBANG" | grep -qE '#!/.*fish'; then
        # Fish script detected via shebang - skip validation
        if [[ "$CLEANUP_TEMP" = true ]]; then
            rm -f "$TEMP_FILE"
        fi
        exit 0
    fi
fi

# Ensure cleanup on exit
if [[ "$CLEANUP_TEMP" = true ]]; then
    trap 'rm -f "$TEMP_FILE"' EXIT
fi

# Run shellcheck
echo "🔍 Running shellcheck on: $FILE_PATH" >&2

if shellcheck "$CHECK_FILE" 2>&1; then
    echo "✅ Shellcheck passed: $FILE_PATH" >&2
    exit 0
else
    echo "" >&2
    echo "❌ Shellcheck failed: $FILE_PATH" >&2
    echo "" >&2
    echo "Please fix the shellcheck issues before committing." >&2
    echo "Run: shellcheck $FILE_PATH" >&2
    exit 2
fi
