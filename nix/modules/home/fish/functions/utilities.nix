# Fish shell utility functions
{ ... }:

{
  programs.fish.functions = {
    mkd = {
      description = "Create directory and cd into it";
      body = "mkdir -p $argv && cd $argv";
    };

    up-or-search = {
      description = "Move up in history or search";
      body = ''
        if commandline --search-mode
          commandline -f history-search-backward
          return
        end

        if commandline --paging-mode
          commandline -f up-line
          return
        end

        set -l lineno (commandline -L)
        if test $lineno -gt 1
          commandline -f up-line
        else
          commandline -f history-search-backward
        end
      '';
    };

    link-dotfile = {
      description = "Create symlink for dotfile";
      body = ''
        if test (count $argv) -ne 2
          echo "Usage: link-dotfile <source> <target>" >&2
          return 1
        end
        ln -sf $argv[1] $argv[2]
      '';
    };
  };
}
