#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions Workflow Version Pinning Validator
# Ensures workflow actions use digest-pinned versions with version comments
# and checks if actions are using the latest released versions
#
# Usage: validate-github-workflow.sh
# Input: CLAUDE_FILE_PATH (file path), CLAUDE_TOOL_INPUT (JSON)
# Output: Exit 0 = pass, Exit 2 = block with error message

FILE_PATH="${CLAUDE_FILE_PATH:-}"

# Exit early if no file path provided
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Check if file is a GitHub Actions workflow
if [[ ! "$FILE_PATH" =~ ^.*\.github/workflows/.*\.(yml|yaml)$ ]]; then
    exit 0
fi

# Parse tool input to get the file content being written
JSON_INPUT="${CLAUDE_TOOL_INPUT:-}"
if [[ -z "$JSON_INPUT" ]]; then
    exit 0
fi

# Extract file content from JSON input
CONTENT=$(echo "$JSON_INPUT" | jq -r '.tool_input.content // .content // empty' 2>/dev/null || echo "")
if [[ -z "$CONTENT" ]]; then
    # For Edit operations, read the current file
    if [[ -f "$FILE_PATH" ]]; then
        CONTENT=$(<"$FILE_PATH")
    else
        exit 0
    fi
fi

# Function to check if a line is a comment or has explanation
is_comment_or_explanation() {
    local line="$1"
    [[ "$line" =~ ^[[:space:]]*# ]]
}

# Function to extract version from comment
extract_version_from_comment() {
    local line="$1"
    # Match patterns like "# v1.2.3" or "# version 1.2.3"
    if [[ "$line" =~ \#[[:space:]]*(v?[0-9]+\.[0-9]+(\.[0-9]+)?([.-][a-zA-Z0-9]+)?) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

# Function to check if line has explanation comment (not version)
has_explanation_comment() {
    local line="$1"
    # shellcheck disable=SC2310
    # Comment exists but is not a version
    if is_comment_or_explanation "$line"; then
        # shellcheck disable=SC2310
        if ! extract_version_from_comment "$line" >/dev/null; then
            return 0
        fi
    fi
    return 1
}

# Function to get latest version of a GitHub action
get_latest_version() {
    local action_name="$1"
    local latest_version

    # Query GitHub API for latest release
    latest_version=$(gh api "repos/$action_name/releases/latest" --jq '.tag_name' 2>/dev/null || echo "")

    if [[ -z "$latest_version" ]]; then
        # Try tags if no releases
        latest_version=$(gh api "repos/$action_name/tags" --jq '.[0].name' 2>/dev/null || echo "")
    fi

    echo "$latest_version"
}

# Function to normalize version (strip leading 'v')
normalize_version() {
    local version="$1"
    echo "${version#v}"
}

# Function to compare semantic versions
# Returns 0 if v1 >= v2, 1 if v1 < v2
version_gte() {
    local v1="$1"
    local v2="$2"

    # Normalize versions
    v1=$(normalize_version "$v1")
    v2=$(normalize_version "$v2")

    # Use sort -V for version comparison
    if [[ "$(printf '%s\n%s' "$v2" "$v1" | sort -V | head -n1)" = "$v2" ]]; then
        return 0
    fi
    return 1
}

# Parse YAML and validate actions
ERRORS=()
WARNINGS=()
LINE_NUM=0
PREV_LINE=""

while IFS= read -r line; do
    LINE_NUM=$((LINE_NUM + 1))

    # Check for 'uses:' lines (may be preceded by YAML list item dash)
    if [[ "$line" =~ ^[[:space:]]*-?[[:space:]]*uses:[[:space:]]*(.+)$ ]]; then
        ACTION="${BASH_REMATCH[1]}"
        # Remove trailing comment if present
        ACTION_REF=$(echo "$ACTION" | sed 's/#.*//' | xargs)

        # Skip local actions (start with ./)
        if [[ "$ACTION_REF" =~ ^\./.*$ ]]; then
            PREV_LINE="$line"
            continue
        fi

        # Skip Docker actions (contain docker://)
        if [[ "$ACTION_REF" =~ ^docker:// ]]; then
            PREV_LINE="$line"
            continue
        fi

        # Extract action name and ref
        if [[ "$ACTION_REF" =~ ^([^@]+)@(.+)$ ]]; then
            ACTION_NAME="${BASH_REMATCH[1]}"
            ACTION_VERSION="${BASH_REMATCH[2]}"

            # Check if version is a digest (40-char SHA-1 or 64-char SHA-256)
            IS_DIGEST=false
            if [[ "$ACTION_VERSION" =~ ^[a-f0-9]{40}$ ]] || [[ "$ACTION_VERSION" =~ ^[a-f0-9]{64}$ ]]; then
                IS_DIGEST=true
            fi

            if [[ "$IS_DIGEST" = false ]]; then
                # Not digest-pinned, check if there's an explanation comment
                HAS_EXPLANATION=false

                # Check previous line for explanation
                # shellcheck disable=SC2310
                if has_explanation_comment "$PREV_LINE"; then
                    HAS_EXPLANATION=true
                fi

                # Check current line for explanation
                if [[ "$ACTION" =~ \#.*[a-zA-Z] ]]; then
                    COMMENT="${ACTION#*#}"
                    if ! [[ "$COMMENT" =~ ^[[:space:]]*v?[0-9]+\.[0-9]+ ]]; then
                        HAS_EXPLANATION=true
                    fi
                fi

                if [[ "$HAS_EXPLANATION" = false ]]; then
                    ERRORS+=("Line $LINE_NUM: Action '$ACTION_NAME@$ACTION_VERSION' uses tag without digest")
                fi
            else
                # Digest-pinned, check for version comment
                HAS_VERSION_COMMENT=false
                CURRENT_VERSION=""

                # Check inline comment
                if [[ "$ACTION" =~ \#[[:space:]]*(v?[0-9]+\.[0-9]+(\.[0-9]+)?([.-][a-zA-Z0-9]+)?) ]]; then
                    HAS_VERSION_COMMENT=true
                    CURRENT_VERSION="${BASH_REMATCH[1]}"
                fi

                # Check previous line for version comment
                if [[ "$HAS_VERSION_COMMENT" = false ]]; then
                    # shellcheck disable=SC2310
                    EXTRACTED=$(extract_version_from_comment "$PREV_LINE" 2>/dev/null || echo "")
                    if [[ -n "$EXTRACTED" ]]; then
                        HAS_VERSION_COMMENT=true
                        CURRENT_VERSION="$EXTRACTED"
                    fi
                fi

                if [[ "$HAS_VERSION_COMMENT" = false ]]; then
                    ERRORS+=("Line $LINE_NUM: Digest-pinned action '$ACTION_NAME@${ACTION_VERSION:0:8}...' missing version comment")
                else
                    # Check if using latest version
                    LATEST_VERSION=$(get_latest_version "$ACTION_NAME")
                    if [[ -n "$LATEST_VERSION" && -n "$CURRENT_VERSION" ]]; then
                        # shellcheck disable=SC2310
                        if ! version_gte "$CURRENT_VERSION" "$LATEST_VERSION"; then
                            WARNINGS+=("Line $LINE_NUM: Action '$ACTION_NAME' using $CURRENT_VERSION, latest is $LATEST_VERSION")
                        fi
                    fi
                fi
            fi
        fi
    fi

    PREV_LINE="$line"
done <<< "$CONTENT"

# Report warnings if any
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "Warning: GitHub Actions using outdated versions" >&2
    echo "" >&2
    echo "Workflow file: $FILE_PATH" >&2
    echo "" >&2

    for warning in "${WARNINGS[@]}"; do
        echo "  $warning" >&2
    done

    echo "" >&2
    echo "Consider updating to the latest versions for security and features." >&2
    echo "" >&2
fi

# Report errors if any
if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo "Error: GitHub Actions workflow validation failed" >&2
    echo "" >&2
    echo "Workflow file: $FILE_PATH" >&2
    echo "" >&2

    for error in "${ERRORS[@]}"; do
        echo "  $error" >&2
    done

    echo "" >&2
    echo "Requirements:" >&2
    echo "  - Use digest-pinned actions with version comments:" >&2
    echo "    uses: actions/checkout@abc123... # v4.1.7" >&2
    echo "" >&2
    echo "  - Or provide explanation when digest pinning not possible:" >&2
    echo "    # Cannot pin by digest: marketplace action with frequent updates" >&2
    echo "    uses: vendor/custom-action@v1" >&2
    echo "" >&2

    exit 2
fi

exit 0
