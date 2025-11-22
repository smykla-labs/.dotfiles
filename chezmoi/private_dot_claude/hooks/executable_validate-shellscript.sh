#!/usr/bin/env bash
set -euo pipefail

# Validate shell scripts with shellcheck
# Triggers on file writes to shell script files
# Exit codes: 0 = pass, 2 = fail

# Get file path from environment or first argument
FILE_PATH="${CLAUDE_FILE_PATH:-${1:-}}"

if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Only check shell scripts (skip fish scripts)
case "$FILE_PATH" in
    *.sh|*.bash)
        # Shell script detected
        ;;
    *.fish)
        # Fish script - skip
        exit 0
        ;;
    *)
        # Check shebang if no extension
        if [[ -f "$FILE_PATH" ]]; then
            SHEBANG=$(head -n 1 "$FILE_PATH" 2>/dev/null || echo "")
            case "$SHEBANG" in
                *'/env bash'|*'/env sh'|*/bash|*/sh)
                    # Shell script detected via shebang
                    ;;
                *fish*)
                    # Fish script - skip
                    exit 0
                    ;;
                *)
                    # Not a shell script
                    exit 0
                    ;;
            esac
        else
            exit 0
        fi
        ;;
esac

# File doesn't exist yet (pre-write validation)
if [[ ! -f "$FILE_PATH" ]]; then
    echo "⚠️  File doesn't exist yet, skipping shellcheck validation" >&2
    exit 0
fi

# Run shellcheck
if command -v shellcheck >/dev/null 2>&1; then
    echo "🔍 Running shellcheck on: $FILE_PATH" >&2
    
    if shellcheck "$FILE_PATH" 2>&1; then
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
else
    echo "⚠️  shellcheck not found, skipping validation" >&2
    echo "Install: brew install shellcheck" >&2
    exit 0
fi
