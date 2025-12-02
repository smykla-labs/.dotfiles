#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
#
# Taskfile Tests
#
# PURPOSE:
#   Test Taskfile.yaml tasks and functionality
#
# WHAT'S TESTED:
#   - Taskfile.yaml exists and has valid syntax
#   - All expected tasks are defined
#   - Tasks can be listed without errors
#   - Task list shows all available commands
#
# HOW TO RUN:
#   shellspec spec/taskfile_spec.sh
#   OR
#   task test:shellspec
#
# REFERENCE:
#   https://taskfile.dev

Describe 'Taskfile'
    setup() {
        # shellcheck disable=SC2155  # Declare and assign separately - not critical for test setup
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        cd "${DOTFILES_PATH}" || return 1
    }
    Before 'setup'

    It 'exists in repository root'
        The file "${DOTFILES_PATH}/Taskfile.yaml" should be exist
    End

    It 'has valid YAML syntax'
        When call task --list
        The status should be success
        The output should be present
    End

    Describe 'Required tasks exist'
        It 'has default task (list)'
            When call task --list
            The output should include "default"
        End

        It 'has install task'
            When call task --list
            The output should include "install"
        End

        It 'has test task'
            When call task --list
            The output should include "test"
        End

        It 'has lint task'
            When call task --list
            The output should include "lint"
        End

        It 'has check task (lint alias)'
            When call task --list
            The output should include "check"
        End

        It 'has clean task'
            When call task --list
            The output should include "clean"
        End

        It 'has update task'
            When call task --list
            The output should include "update"
        End
    End

    Describe 'Install tasks exist'
        It 'has install:brew task'
            When call task --list
            The output should include "install:brew"
        End

        It 'has install:fish task'
            When call task --list
            The output should include "install:fish"
        End

        It 'has install:mise task'
            When call task --list
            The output should include "install:mise"
        End

        It 'has install:shells task'
            When call task --list
            The output should include "install:shells"
        End
    End

    Describe 'Test tasks exist'
        It 'has test:brewfile task'
            When call task --list
            The output should include "test:brewfile"
        End


        It 'has test:shellspec task'
            When call task --list
            The output should include "test:shellspec"
        End

        It 'has test:syntax task'
            When call task --list
            The output should include "test:syntax"
        End
    End

    Describe 'Lint tasks exist'

        It 'has lint:markdown task'
            When call task --list
            The output should include "lint:markdown"
        End

        It 'has lint:shell task'
            When call task --list
            The output should include "lint:shell"
        End

        It 'has lint:taskfile task'
            When call task --list
            The output should include "lint:taskfile"
        End
    End

    Describe 'Task list output'
        It 'shows available tasks with descriptions'
            When call task --list
            The status should be success
            The output should include "Run all tests"
        End

        It 'can show tasks in list format'
            When call task --list-all
            The status should be success
            The output should be present
        End
    End

    Describe 'Task execution validation'
        It 'test task can be summarized'
            When call task test --summary
            The status should be success
            The output should be present
        End

        It 'test task includes all test subtasks'
            When call task test --summary
            The status should be success
            The output should include "test:syntax"
            The output should include "test:brewfile"
            The output should include "test:shellspec"
        End

        It 'lint task can be summarized'
            When call task lint --summary
            The status should be success
            The output should be present
        End

        It 'lint task includes all lint subtasks'
            When call task lint --summary
            The status should be success
            The output should include "lint:shell"
            The output should include "lint:markdown"
            The output should include "lint:taskfile"
        End

        It 'test:brewfile task can be summarized'
            When call task test:brewfile --summary
            The status should be success
            The output should be present
        End


        It 'test:syntax task can be summarized'
            When call task test:syntax --summary
            The status should be success
            The output should be present
        End


        It 'lint:shell task can be summarized'
            When call task lint:shell --summary
            The status should be success
            The output should be present
        End

        It 'lint:markdown task can be summarized'
            When call task lint:markdown --summary
            The status should be success
            The output should be present
        End

        It 'lint:taskfile task can be summarized'
            When call task lint:taskfile --summary
            The status should be success
            The output should be present
        End
    End

    Describe 'Taskfile validation'
        It 'passes JSON schema validation'
            Skip if "check-jsonschema not installed" ! command -v check-jsonschema >/dev/null 2>&1
            When call check-jsonschema --schemafile https://taskfile.dev/schema.json "${DOTFILES_PATH}/Taskfile.yaml"
            The status should be success
            The output should include "ok"
        End
    End
End
