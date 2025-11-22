#!/usr/bin/env bash
set -euo pipefail

# Validate PR creation (gh pr create) command
# 1. PR title must follow semantic commit format
# 2. PR body must follow template structure
# 3. Changelog rules (skip for ci/test/chore, otherwise use title or custom)
# 4. Simple language and personal tone
# 5. Add base branch label if not master/main
# 6. Add ci/skip-test or ci/skip-e2e-test labels during creation when appropriate

# Exit codes: 0 = pass, 2 = fail, 3 = needs review

# Get gh command from environment
GH_COMMAND="${CLAUDE_GIT_COMMAND:-}"

if [[ -z "$GH_COMMAND" ]]; then
    exit 0
fi

# Valid types from commitlint config-conventional
VALID_TYPES="build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test"
NON_USER_FACING_TYPES="ci|test|chore|build|docs|style|refactor"

ERRORS=()
WARNINGS=()

# Extract PR title and body from gh pr create command
PR_TITLE=""
PR_BODY=""
BASE_BRANCH=""
HAS_LABELS=false
LABELS=""

# Try to extract from command (handle both " and ' quotes)
if echo "$GH_COMMAND" | grep -q -E '\-\-title'; then
    PR_TITLE=$(echo "$GH_COMMAND" | sed -n 's/.*--title *"\([^"]*\)".*/\1/p')
    if [[ -z "$PR_TITLE" ]]; then
        PR_TITLE=$(echo "$GH_COMMAND" | sed -n "s/.*--title *'\([^']*\)'.*/\1/p")
    fi
fi

if echo "$GH_COMMAND" | grep -q -E '\-\-base'; then
    BASE_BRANCH=$(echo "$GH_COMMAND" | sed -n 's/.*--base *"\([^"]*\)".*/\1/p')
    if [[ -z "$BASE_BRANCH" ]]; then
        BASE_BRANCH=$(echo "$GH_COMMAND" | sed -n "s/.*--base *'\([^']*\)'.*/\1/p")
    fi
fi

if echo "$GH_COMMAND" | grep -q -E '\-\-label'; then
    HAS_LABELS=true
    LABELS=$(echo "$GH_COMMAND" | sed -n 's/.*--label *"\([^"]*\)".*/\1/p')
    if [[ -z "$LABELS" ]]; then
        LABELS=$(echo "$GH_COMMAND" | sed -n "s/.*--label *'\([^']*\)'.*/\1/p")
    fi
fi

# Body extraction is complex with newlines, check for presence
if echo "$GH_COMMAND" | grep -q -E '\-\-body'; then
    # Extract body content (simplified - may not handle all edge cases)
    PR_BODY=$(echo "$GH_COMMAND" | sed -n 's/.*--body *"\(.*\)".*/\1/p' | head -1)
    if [[ -z "$PR_BODY" ]]; then
        PR_BODY=$(echo "$GH_COMMAND" | sed -n "s/.*--body *'\(.*\)'.*/\1/p" | head -1)
    fi
    # If still empty, at least mark that --body flag was present
    if [[ -z "$PR_BODY" ]] && echo "$GH_COMMAND" | grep -q '\-\-body'; then
        PR_BODY="<body-present-but-extraction-failed>"
    fi
fi

# If PR title/body not found via flags, might be using stdin or file
if [[ -z "$PR_TITLE" ]]; then
    WARNINGS+=("⚠️  Could not extract PR title - ensure you're using --title flag")
fi

if [[ -z "$PR_BODY" ]]; then
    WARNINGS+=("⚠️  Could not extract PR body - ensure you're using --body flag")
fi

# Validate PR title follows semantic commit format
if [[ -n "$PR_TITLE" ]]; then
    if ! echo "$PR_TITLE" | grep -qE "^($VALID_TYPES)(\([a-zA-Z0-9_\/-]+\))?!?: .+"; then
        ERRORS+=("❌ PR title doesn't follow semantic commit format")
        ERRORS+=("   Current: '$PR_TITLE'")
        ERRORS+=("   Expected: type(scope): description")
        ERRORS+=("   Valid types: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test")
    fi
    
    # Check for feat/fix misuse with infrastructure scopes
    if echo "$PR_TITLE" | grep -qE "^(feat|fix)\((ci|test|docs|build)\):"; then
        TYPE_MATCH=$(echo "$PR_TITLE" | grep -oE "^(feat|fix)" | head -1)
        SCOPE_MATCH=$(echo "$PR_TITLE" | grep -oE "\((ci|test|docs|build)\)" | tr -d '()' | head -1)
        ERRORS+=("❌ Use '$SCOPE_MATCH(...)' not '$TYPE_MATCH($SCOPE_MATCH)' for infrastructure changes")
        ERRORS+=("   feat/fix should only be used for user-facing changes")
    fi
fi

# Validate PR body follows template
if [[ -n "$PR_BODY" ]]; then
    # Check for required sections
    if ! echo "$PR_BODY" | grep -q "## Motivation"; then
        ERRORS+=("❌ PR body missing '## Motivation' section")
    fi
    
    if ! echo "$PR_BODY" | grep -q "## Implementation information"; then
        ERRORS+=("❌ PR body missing '## Implementation information' section")
    fi
    
    if ! echo "$PR_BODY" | grep -q "## Supporting documentation"; then
        ERRORS+=("❌ PR body missing '## Supporting documentation' section")
    fi
    
    # Check changelog handling
    PR_TYPE=$(echo "$PR_TITLE" | grep -oE "^($VALID_TYPES)" | head -1 || echo "")
    HAS_CHANGELOG_SKIP=$(echo "$PR_BODY" | grep -E "^>\s*Changelog:\s*skip" || echo "")
    HAS_CHANGELOG_CUSTOM=$(echo "$PR_BODY" | grep -E "^>\s*Changelog:" | grep -v "skip" || echo "")
    
    if [[ -n "$PR_TYPE" ]]; then
        # Non-user-facing changes should have changelog: skip
        if echo "$PR_TYPE" | grep -qE "^($NON_USER_FACING_TYPES)$"; then
            if [[ -z "$HAS_CHANGELOG_SKIP" ]]; then
                WARNINGS+=("⚠️  PR type '$PR_TYPE' should typically have '> Changelog: skip'")
                WARNINGS+=("   Infrastructure changes don't need changelog entries")
            fi
        else
            # User-facing changes (feat/fix) should NOT skip changelog
            if [[ -n "$HAS_CHANGELOG_SKIP" ]]; then
                WARNINGS+=("⚠️  PR type '$PR_TYPE' is user-facing but has 'Changelog: skip'")
                WARNINGS+=("   Consider removing 'skip' or using custom changelog entry")
            fi
        fi
    fi
    
    # Validate custom changelog format if present
    if [[ -n "$HAS_CHANGELOG_CUSTOM" ]]; then
        CHANGELOG_ENTRY=$(echo "$PR_BODY" | grep -E "^>\s*Changelog:" | sed 's/^>\s*Changelog:\s*//')
        if [[ "$CHANGELOG_ENTRY" != "skip" ]]; then
            if ! echo "$CHANGELOG_ENTRY" | grep -qE "^($VALID_TYPES)(\([a-zA-Z0-9_\/-]+\))?!?: .+"; then
                ERRORS+=("❌ Custom changelog entry doesn't follow semantic commit format")
                ERRORS+=("   Found: '$CHANGELOG_ENTRY'")
                ERRORS+=("   Note: Changelog format is flexible on length but should be semantic")
            fi
        fi
    fi
    
    # Check for simple, personal language (heuristics)
    if echo "$PR_BODY" | grep -qE "(utilize|leverage|facilitate|implement)"; then
        WARNINGS+=("⚠️  PR description uses formal language - consider simpler, more personal tone")
        WARNINGS+=("   Examples: 'use' instead of 'utilize', 'add' instead of 'implement'")
    fi
    
    # Check for line breaks in paragraphs (not after headers or blank lines)
    # This is a heuristic check - warns if there are many short lines that look like broken paragraphs
    SHORT_LINES=$(echo "$PR_BODY" | grep -v "^##" | grep -v "^$" | grep -v "^>" | grep -v "^-" | awk 'length < 40' | grep -c '^' || true)
    TOTAL_LINES=$(echo "$PR_BODY" | grep -v "^##" | grep -v "^$" | grep -c '^' || true)
    if [[ "$TOTAL_LINES" -gt 5 ]] && [[ "$SHORT_LINES" -gt 3 ]]; then
        WARNINGS+=("⚠️  PR description may have unnecessary line breaks within paragraphs")
        WARNINGS+=("   Don't break long lines in body paragraphs - let them flow naturally")
    fi
    
    # Check if Supporting documentation section is empty or N/A
    if echo "$PR_BODY" | grep -A 5 "## Supporting documentation" | grep -qiE "(^N/A|^None|^$)"; then
        WARNINGS+=("⚠️  Supporting documentation section is empty or N/A")
        WARNINGS+=("   Consider removing the section entirely if there's no supporting documentation")
    fi
fi

# Validate base branch labels
if [[ -n "$BASE_BRANCH" ]]; then
    if ! echo "$BASE_BRANCH" | grep -qE "^(master|main)$"; then
        # Release branch - should have label
        if [[ "$HAS_LABELS" = false ]] || ! echo "$LABELS" | grep -q "$BASE_BRANCH"; then
            ERRORS+=("❌ PR targets '$BASE_BRANCH' but missing label with base branch name")
            ERRORS+=("   Add: --label \"$BASE_BRANCH\"")
            ERRORS+=("   Note: ci/* labels MUST be added during PR creation (not after)")
        fi
    fi
fi

# Validate ci/ labels are added during creation if needed
if [[ -n "$PR_BODY" ]] && [[ -n "$PR_TITLE" ]]; then
    # Heuristics to detect if ci/skip-test should be added
    SHOULD_SKIP_TESTS=false
    SHOULD_SKIP_E2E=false
    
    # Check PR type for non-logic changes
    if echo "$PR_TITLE" | grep -qE "^(ci|docs|chore|style)\("; then
        SHOULD_SKIP_TESTS=true
        SHOULD_SKIP_E2E=true
    fi
    
    # Check for specific keywords
    if echo "$PR_BODY" | grep -qiE "(only documentation|just comments|only ci|workflow changes)"; then
        SHOULD_SKIP_TESTS=true
        SHOULD_SKIP_E2E=true
    fi
    
    if echo "$PR_BODY" | grep -qiE "(only unit tests|unit test changes)"; then
        SHOULD_SKIP_E2E=true
    fi
    
    # Warn if labels might be needed
    if [[ "$SHOULD_SKIP_TESTS" = true ]] && [[ "$HAS_LABELS" = false ]]; then
        WARNINGS+=("⚠️  This appears to be a non-logic change - consider adding --label \"ci/skip-test\"")
        WARNINGS+=("   Important: ci/* labels MUST be added during creation (--label flag)")
    elif [[ "$SHOULD_SKIP_E2E" = true ]] && ! echo "$LABELS" | grep -q "ci/skip"; then
        WARNINGS+=("⚠️  This appears to be a unit-test-only change - consider adding --label \"ci/skip-e2e-test\"")
        WARNINGS+=("   Important: ci/* labels MUST be added during creation (--label flag)")
    fi
    
    # Check if ci/ labels are present
    if echo "$LABELS" | grep -qE "ci/skip-(test|e2e-test)"; then
        echo "✓ CI skip labels detected (will be applied during creation)" >&2
    fi
fi

# Report errors and warnings
if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo "🚫 PR validation failed:" >&2
    echo "" >&2
    printf '%s\n' "${ERRORS[@]}" >&2
    
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo "" >&2
        echo "Warnings:" >&2
        printf '%s\n' "${WARNINGS[@]}" >&2
    fi
    
    echo "" >&2
    echo "📝 PR title: $PR_TITLE" >&2
    exit 2
fi

# Validate markdown formatting if body is available
if [[ -n "$PR_BODY" ]] && [[ "$PR_BODY" != "<body-present-but-extraction-failed>" ]]; then
    MD_CHECK=$(/Users/bart.smykla@konghq.com/.claude/hooks/validate-markdown.sh <<< "$PR_BODY" 2>&1) || true
    if [[ -n "$MD_CHECK" ]]; then
        # Add markdown warnings to existing warnings
        if [[ ${#WARNINGS[@]} -eq 0 ]]; then
            echo "$MD_CHECK" >&2
        else
            # Markdown check output already printed via stderr
            :
        fi
    fi
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "⚠️  PR validation passed with warnings:" >&2
    echo "" >&2
    printf '%s\n' "${WARNINGS[@]}" >&2
    echo "" >&2
fi

echo "✅ PR validation passed" >&2
exit 0
