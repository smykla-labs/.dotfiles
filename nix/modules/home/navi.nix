# Navi configuration for interactive cheatsheets
#
# Replaces gocheat with navi (https://github.com/denisidoro/navi).
# Provides:
#   - Broot shortcuts cheatsheet (37 items) - navi/cheats/broot.cheat
#   - Fish abbreviations reference (70+ items) - navi/cheats/fish-abbrs.cheat
#   - Fish shell widget (Ctrl+G)
#
# Structure:
#   - Module: nix/modules/home/navi.nix
#   - Cheatsheets: nix/modules/home/navi/cheats/*.cheat
#   - Each tool has its own .cheat file for easy maintenance
#
# Usage:
#   - Ctrl+G: Launch navi widget from shell prompt
#   - navi: Direct command to browse all cheatsheets
#   - navi --tag broot: Filter by tag
#   - navi --query "search": Search for specific items
#
# Installation:
#   1. This module is imported in flake.nix
#   2. Run: home-manager switch
#   3. Test: Press Ctrl+G in fish shell

{ config, lib, pkgs, ... }:

{
  # Install navi package
  home.packages = with pkgs; [
    navi  # Version 2.24.0 (interactive cheatsheet tool)
    # fzf already installed via packages.nix
  ];

  # Navi configuration - minimal config, inherits FZF_DEFAULT_OPTS for theming
  # xdg.configFile."navi/config.yaml".text = ''
  #   cheats:
  #     paths:
  #       - ~/.local/share/navi/cheats
  # '';

  # Cheatsheets - each tool has its own file in navi/cheats/
  home.file.".local/share/navi/cheats/broot.cheat".source = ./navi/cheats/broot.cheat;
  home.file.".local/share/navi/cheats/fish-abbrs.cheat".source = ./navi/cheats/fish-abbrs.cheat;

  # Fish shell widget integration
  # Enables Ctrl+G keybind to launch navi from any prompt
  programs.fish = {
    interactiveShellInit = lib.mkAfter ''
      # Navi shell widget (Ctrl+G by default)
      # Enables instant cheatsheet access from any prompt
      # Selected command is inserted at cursor (not executed)
      navi widget fish | source
    '';
  };
}
