# Fish shell plugins and plugin-specific configurations
{ pkgs, ... }:

{
  programs.fish.plugins = [
    {
      name = "fish-history-merge";
      src = pkgs.fetchFromGitHub {
        owner = "2m";
        repo = "fish-history-merge";
        rev = "7e415b8ab843a64313708273cf659efbf471ad39";
        sha256 = "1hlc2ghnc8xidwzj2v1rjrw7gbpkkkld9y2mg4dh2qmcvlizcbd3";
      };
    }
    {
      name = "fzf-fish";
      src = pkgs.fishPlugins.fzf-fish.src;
    }
    {
      name = "fish-abbreviation-tips";
      src = pkgs.fetchFromGitHub {
        owner = "gazorby";
        repo = "fish-abbreviation-tips";
        rev = "v0.7.0";
        sha256 = "05b5qp7yly7mwsqykjlb79gl24bs6mbqzaj5b3xfn3v2b7apqnqp";
      };
    }
  ];

  # Plugin-specific configurations
  programs.fish.interactiveShellInit = ''
    # abbr-tips configuration
    # Must be set before the plugin loads via fish_postexec event
    set -Ux ABBR_TIPS_REGEXES
    set -a ABBR_TIPS_REGEXES '(^(\w+\s+)+(-{1,2})\w+)(\s\S+)'
    set -a ABBR_TIPS_REGEXES '(^(\s?(\w-?)+){3}).*'
    set -a ABBR_TIPS_REGEXES '(^(\s?(\w-?)+){2}).*'
    set -a ABBR_TIPS_REGEXES '(^(\s?(\w-?)+){1}).*'

    set -Ux ABBR_TIPS_PROMPT "\n💡 \e[1m{{ .abbr }}\e[0m => {{ .cmd }}"
    set -gx ABBR_TIPS_AUTO_UPDATE background
  '';
}
