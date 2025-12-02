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

    # Use nix-direnv for faster nix shell loading
    nix-direnv.enable = true;

    config = {
      global = {
        # Hide environment diff output
        hide_env_diff = true;
      };
    };
  };
}
