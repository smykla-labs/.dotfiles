# K9s Kubernetes TUI configuration
#
# Migrated from chezmoi to home-manager.
# Main config.yaml is handled via sops-nix (contains sensitive data).
# Non-sensitive configs (aliases, plugins, views) are managed declaratively here.
{ config, lib, pkgs, ... }:

{
  # K9s configuration files
  xdg.configFile = {
    # Aliases for quick resource access
    "k9s/aliases.yaml".text = ''
      aliases:
        dp: deployments
        sec: v1/secrets
        jo: jobs
        cr: clusterroles
        crb: clusterrolebindings
        ro: roles
        rb: rolebindings
        np: networkpolicies
    '';

    # Plugins for extended functionality
    "k9s/plugins.yaml".text = ''
      plugins:
        # Leverage stern for log output
        stern:
          shortCut: Ctrl-L
          confirm: false
          description: "Logs <Stern>"
          scopes:
            - pods
          command: stern
          background: false
          args:
            - --tail
            - "50"
            - $FILTER
            - -n
            - $NAMESPACE
            - --context
            - $CONTEXT
    '';

    # Symlink main config from sops secret
    # Note: K9s expects config.yaml but we have it in sops as k9s-config.yaml
    # The sops secret path is $DARWIN_USER_TEMP_DIR/secrets/k9s-config.yaml
    # K9s reads from ~/.config/k9s/config.yaml
  };

  # Activation script to symlink sops secret to k9s config location
  home.activation.k9sConfig = lib.hm.dag.entryAfter [ "writeBoundary" "sops-nix" ] ''
    if [ -x /usr/bin/getconf ]; then
      darwin_temp_dir=$(/usr/bin/getconf DARWIN_USER_TEMP_DIR 2>/dev/null)
    else
      darwin_temp_dir=""
    fi

    if [ -n "$darwin_temp_dir" ] && [ -f "$darwin_temp_dir/secrets/k9s-config.yaml" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/k9s"
      $DRY_RUN_CMD ln -sf "$darwin_temp_dir/secrets/k9s-config.yaml" "$HOME/.config/k9s/config.yaml"
    fi
  '';
}
