# Fish shell external configurations index
# Imports all external config modules (fzf, abbr_tips, completions, etc.)
{ ... }:

{
  imports = [
    ./fzf.nix
    ./abbr-tips.nix
    ./completions.nix
  ];
}
