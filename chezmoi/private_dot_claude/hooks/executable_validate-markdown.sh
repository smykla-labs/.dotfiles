#!/usr/bin/env bash
set -euo pipefail

# Validate markdown formatting rules
# 1. Empty line before code blocks (```)
# 2. Empty line before first list item (-, *, 1.)
# 3. Empty line after headers (##)

# Exit codes: 0 = pass, 2 = fail

# Get text content from first argument or stdin
if [[ -n "${1:-}" ]]; then
    TEXT_CONTENT="$1"
else
    TEXT_CONTENT=$(cat)
fi

if [[ -z "$TEXT_CONTENT" ]]; then
    exit 0
fi

ERRORS=()
WARNINGS=()

# Split into lines for analysis
mapfile -t LINES <<< "$TEXT_CONTENT"

# Track previous line and code block state
PREV_LINE=""
LINE_NUM=0
IN_CODE_BLOCK=false

for line in "${LINES[@]}"; do
    LINE_NUM=$((LINE_NUM + 1))

    # Skip first line
    if [[ "$LINE_NUM" -eq 1 ]]; then
        PREV_LINE="$line"
        continue
    fi

    # Check for code block start/end
    if echo "$line" | grep -qE '^```'; then
        if [[ "$IN_CODE_BLOCK" = false ]]; then
            # Opening code block
            if [[ -n "$PREV_LINE" ]] && ! echo "$PREV_LINE" | grep -qE '^[[:space:]]*$'; then
                WARNINGS+=("⚠️  Line $LINE_NUM: Code block should have empty line before it")
                WARNINGS+=("   Previous line: '${PREV_LINE:0:60}'")
            fi
            IN_CODE_BLOCK=true
        else
            # Closing code block
            IN_CODE_BLOCK=false
        fi
    fi

    # Skip list checks inside code blocks
    if [[ "$IN_CODE_BLOCK" = true ]]; then
        PREV_LINE="$line"
        continue
    fi

    # Check for first list item (after non-list content)
    # Matches: -, *, +, ordered lists (1.), checkbox lists (- [ ], - [x])
    if echo "$line" | grep -qE '^[[:space:]]*[-*+][[:space:]]|^[[:space:]]*[0-9]+\.[[:space:]]'; then
        # Only check if previous line is not a list item or empty
        if [[ -n "$PREV_LINE" ]] && \
           ! echo "$PREV_LINE" | grep -qE '^[[:space:]]*$' && \
           ! echo "$PREV_LINE" | grep -qE '^[[:space:]]*[-*+][[:space:]]|^[[:space:]]*[0-9]+\.[[:space:]]' && \
           ! echo "$PREV_LINE" | grep -qE '^#+[[:space:]]'; then
            WARNINGS+=("⚠️  Line $LINE_NUM: First list item should have empty line before it")
            WARNINGS+=("   Previous line: '${PREV_LINE:0:60}'")
        fi
    fi

    # Check for content immediately after headers
    if echo "$PREV_LINE" | grep -qE '^#+[[:space:]]'; then
        if [[ -n "$line" ]] && ! echo "$line" | grep -qE '^[[:space:]]*$|^#+[[:space:]]|^<!--'; then
            WARNINGS+=("⚠️  Line $((LINE_NUM - 1)): Header should have empty line after it")
            WARNINGS+=("   Header: '${PREV_LINE:0:60}'")
            WARNINGS+=("   Next line: '${line:0:60}'")
        fi
    fi

    PREV_LINE="$line"
done

# Report errors and warnings
if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo "🚫 Markdown formatting validation failed:" >&2
    echo "" >&2
    printf '%s\n' "${ERRORS[@]}" >&2
    exit 2
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "⚠️  Markdown formatting warnings:" >&2
    echo "" >&2
    printf '%s\n' "${WARNINGS[@]}" >&2
    echo "" >&2
fi

exit 0
