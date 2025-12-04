#!/usr/bin/env bash
# Git smudge filter: decrypt file content from repository
~/.local/share/mise/installs/age/1.2.1/age/age --decrypt --identity ~/.config/age/key.txt 2>/dev/null || cat
