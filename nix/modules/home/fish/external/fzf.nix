# fzf.fish plugin configuration files
{ ... }:

{
  xdg.configFile = {
    # fzf.fish functions
    "fish/functions/_fzf_configure_bindings_help.fish".source = ../../../../dotfiles/fish/functions/_fzf_configure_bindings_help.fish;
    "fish/functions/_fzf_extract_var_info.fish".source = ../../../../dotfiles/fish/functions/_fzf_extract_var_info.fish;
    "fish/functions/_fzf_preview_changed_file.fish".source = ../../../../dotfiles/fish/functions/_fzf_preview_changed_file.fish;
    "fish/functions/_fzf_preview_file.fish".source = ../../../../dotfiles/fish/functions/_fzf_preview_file.fish;
    "fish/functions/_fzf_report_diff_type.fish".source = ../../../../dotfiles/fish/functions/_fzf_report_diff_type.fish;
    "fish/functions/_fzf_report_file_type.fish".source = ../../../../dotfiles/fish/functions/_fzf_report_file_type.fish;
    "fish/functions/_fzf_search_directory.fish".source = ../../../../dotfiles/fish/functions/_fzf_search_directory.fish;
    "fish/functions/_fzf_search_git_log.fish".source = ../../../../dotfiles/fish/functions/_fzf_search_git_log.fish;
    "fish/functions/_fzf_search_git_status.fish".source = ../../../../dotfiles/fish/functions/_fzf_search_git_status.fish;
    "fish/functions/_fzf_search_history.fish".source = ../../../../dotfiles/fish/functions/_fzf_search_history.fish;
    "fish/functions/_fzf_search_processes.fish".source = ../../../../dotfiles/fish/functions/_fzf_search_processes.fish;
    "fish/functions/_fzf_search_variables.fish".source = ../../../../dotfiles/fish/functions/_fzf_search_variables.fish;
    "fish/functions/_fzf_wrapper.fish".source = ../../../../dotfiles/fish/functions/_fzf_wrapper.fish;
    "fish/functions/fzf_configure_bindings.fish".source = ../../../../dotfiles/fish/functions/fzf_configure_bindings.fish;
    "fish/functions/fzf_key_bindings.fish".source = ../../../../dotfiles/fish/functions/fzf_key_bindings.fish;

    # fzf.fish completions
    "fish/completions/fzf_configure_bindings.fish".source = ../../../../dotfiles/fish/completions/fzf_configure_bindings.fish;

    # fzf.fish conf.d
    "fish/conf.d/fzf.fish".source = ../../../../dotfiles/fish/conf.d/fzf.fish;
  };
}
