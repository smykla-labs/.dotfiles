# Direnv configuration
#
# Migrated from chezmoi to home-manager programs.direnv.
# Direnv provides per-directory environment variable management.
#
# Fish integration is automatic when programs.fish.enable = true.
{ config, lib, pkgs, ... }:

{
  programs.direnv = {
    enable = true;

    # Override to use git master with log_format fix (PR #1476)
    # https://github.com/direnv/direnv/pull/1476
    # TODO: Remove once direnv 2.38.0+ is released
    package = pkgs.direnv.overrideAttrs (oldAttrs: rec {
      version = "2.37.1-unstable-2025-07-30";
      src = pkgs.fetchFromGitHub {
        owner = "direnv";
        repo = "direnv";
        rev = "92436eed264bc286862c5cce6fff2781cd195778";  # PR #1476 merge commit
        hash = "sha256-H75lGBk1wqWV/OrcgRvkUIDycaz6wAFVqdvIucDLyuw=";
      };
    });

    # Use nix-direnv for faster nix shell loading
    nix-direnv.enable = true;

    config = {
      global = {
        # Disable loading/unloading messages
        log_format = "-";

        # Hide environment diff output
        hide_env_diff = true;
      };
    };
  };
}
