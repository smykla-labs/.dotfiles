# abbr_tips plugin configuration files
{ ... }:

{
  xdg.configFile = {
    # abbr_tips conf.d and functions
    "fish/conf.d/abbr_tips.fish".source = ../../../../dotfiles/fish/conf.d/abbr_tips.fish;
    "fish/functions/__abbr_tips_bind_newline.fish".source = ../../../../dotfiles/fish/functions/__abbr_tips_bind_newline.fish;
    "fish/functions/__abbr_tips_bind_space.fish".source = ../../../../dotfiles/fish/functions/__abbr_tips_bind_space.fish;
    "fish/functions/__abbr_tips_clean.fish".source = ../../../../dotfiles/fish/functions/__abbr_tips_clean.fish;
    "fish/functions/__abbr_tips_init.fish".source = ../../../../dotfiles/fish/functions/__abbr_tips_init.fish;
  };
}
