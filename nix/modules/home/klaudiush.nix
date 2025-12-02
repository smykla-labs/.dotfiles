# klaudiush configuration
#
# Validation dispatcher for Claude Code hooks.
# Manages klaudiush binary installation and configuration.
{ config, ... }:

{
  programs.klaudiush = {
    enable = true;
    configFile = ../../../configs/klaudiush/config.toml;
    createDynamicDirs = true;
  };
}
