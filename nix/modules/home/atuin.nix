# Atuin shell history configuration
#
# Migrated from chezmoi to home-manager programs.atuin.
# Atuin provides encrypted shell history sync across machines.
{ config, lib, pkgs, ... }:

{
  programs.atuin = {
    enable = true;

    # Enable fish shell integration
    enableFishIntegration = true;

    settings = {
      # Execute command on enter (instead of editing)
      enter_accept = true;

      # Enable sync v2 for new installs
      sync.records = true;

      # Other settings left at defaults
    };
  };
}
