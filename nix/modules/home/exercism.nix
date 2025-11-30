# Exercism CLI configuration
#
# User config contains API token - managed via sops-nix.
# The exercism CLI reads from ~/.config/exercism/user.json
{ config, lib, pkgs, ... }:

{
  # Install exercism CLI (already in packages.nix, but explicit here for clarity)
  home.packages = [ pkgs.exercism ];

  # Activation script to symlink sops secret to exercism config location
  home.activation.exercismConfig = lib.hm.dag.entryAfter [ "writeBoundary" "sops-nix" ] ''
    darwin_temp_dir=$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null)
    if [ -n "$darwin_temp_dir" ] && [ -f "$darwin_temp_dir/secrets/exercism-user.json" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config/exercism"
      $DRY_RUN_CMD ln -sf "$darwin_temp_dir/secrets/exercism-user.json" "$HOME/.config/exercism/user.json"
    fi
  '';
}
