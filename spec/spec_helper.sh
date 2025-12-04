#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
#
# ShellSpec Helper - Common test utilities and setup
#
# PURPOSE:
#   Provides shared setup, teardown, and helper functions for all tests
#
# USAGE:
#   Include at the top of each spec file:
#   %include spec/spec_helper.sh
#
# REFERENCE:
#   https://shellspec.info/

# Set up test environment
# shellcheck disable=SC2155  # Declare and assign separately - not critical for test setup
# shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
export HOME="${HOME:-$HOME}"
export PROJECTS_PATH="${PROJECTS_PATH:-$HOME/Projects/github.com}"

# Test fixture directory (for temporary test files)
export SPEC_TMPDIR="${DOTFILES_PATH}/spec/tmp"

# Color output for better readability
export SHELLSPEC_COLOR=1

#
# HELPER: setup_test_environment
# Creates a clean test environment before each test
#
setup_test_environment() {
    mkdir -p "${SPEC_TMPDIR}"
}

#
# HELPER: cleanup_test_environment
# Cleans up test files after each test
#
cleanup_test_environment() {
    if [ -d "${SPEC_TMPDIR}" ]; then
        rm -rf "${SPEC_TMPDIR}"
    fi
}

#
# HELPER: fish_function_exists
# Checks if a Fish function is defined
# USAGE: fish_function_exists "function_name"
#
fish_function_exists() {
    fish -c "type -q $1"
}

#
# HELPER: fish_source_config
# Sources Fish config for testing
# USAGE: fish_source_config
#
fish_source_config() {
    fish -c "source ${HOME}/.config/fish/config.fish"
}
