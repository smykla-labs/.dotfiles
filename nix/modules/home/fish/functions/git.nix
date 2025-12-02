# Fish shell Git functions
# Uses Nix function generators to create repetitive git push functions (DRY principle)
{ lib, ... }:

let
  # Function generator for git push variants
  # Generates 6 variants (normal, force, force-with-lease, no-verify, no-verify-force, no-verify-force-with-lease)
  # for each remote/upstream combination
  mkGitPushFunctions = remote: { setUpstream ? false }:
    let
      upstreamFlag = if setUpstream then "--set-upstream " else "";
      suffix = if setUpstream then "-first" else "";
    in
    {
      "git-push-${remote}${suffix}" = {
        body = "git push ${upstreamFlag}${remote} (git rev-parse --abbrev-ref HEAD)";
      };

      "git-push-${remote}${suffix}-force" = {
        body = "git push ${upstreamFlag}${remote} (git rev-parse --abbrev-ref HEAD) --force";
      };

      "git-push-${remote}${suffix}-force-with-lease" = {
        body = "git push ${upstreamFlag}${remote} (git rev-parse --abbrev-ref HEAD) --force-with-lease";
      };

      "git-push-${remote}${suffix}-no-verify" = {
        body = "git push ${upstreamFlag}${remote} (git rev-parse --abbrev-ref HEAD) --no-verify";
      };

      "git-push-${remote}${suffix}-no-verify-force" = {
        body = "git push ${upstreamFlag}${remote} (git rev-parse --abbrev-ref HEAD) --no-verify --force";
      };

      "git-push-${remote}${suffix}-no-verify-force-with-lease" = {
        body = "git push ${upstreamFlag}${remote} (git rev-parse --abbrev-ref HEAD) --no-verify --force-with-lease";
      };
    };

  # Generate AF abbreviation wrapper functions for each abbreviation
  mkAfAbbrFunction = abbr: command: fallback:
    {
      "__abbr_af_${abbr}" = {
        description = "AF abbreviation expander for ${abbr}";
        body = "af shortcuts abbreviations ${command} 2>/dev/null || echo ${fallback}";
      };
    };

  # Merge all generated git push functions
  allGitPushFunctions = lib.mkMerge [
    (mkGitPushFunctions "origin" { setUpstream = true; })
    (mkGitPushFunctions "origin" { setUpstream = false; })
    (mkGitPushFunctions "upstream" { setUpstream = true; })
    (mkGitPushFunctions "upstream" { setUpstream = false; })
  ];

  # AF abbreviation functions for git operations
  afFunctions = lib.mkMerge [
    (mkAfAbbrFunction "gcm" "gcm" "git-checkout-default")
    (mkAfAbbrFunction "gcmf" "gcmf" "git-checkout-default-fetch")
    (mkAfAbbrFunction "gcmff" "gcmff" "git-checkout-default-fetch-fast-forward")
    (mkAfAbbrFunction "gp" "gp" "git-push-origin-first")
    (mkAfAbbrFunction "gd" "gd" "git-diff-head-pbcopy")
    (mkAfAbbrFunction "dfi" "dfi" "git-diff-head-files-pbcopy")
    # origin-first variants (set-upstream)
    (mkAfAbbrFunction "po_origin_first" "gp --remote origin-first" "git-push-origin-first")
    (mkAfAbbrFunction "pof_origin_first_force" "gp --remote origin-first --force" "git-push-origin-first-force")
    (mkAfAbbrFunction "pof_origin_first_force_lease" "gp --remote origin-first --force-with-lease" "git-push-origin-first-force-with-lease")
    (mkAfAbbrFunction "pon_origin_first_noverify" "gp --remote origin-first --no-verify" "git-push-origin-first-no-verify")
    (mkAfAbbrFunction "ponf_origin_first_noverify_force" "gp --remote origin-first --no-verify --force" "git-push-origin-first-no-verify-force")
    (mkAfAbbrFunction "ponf_origin_first_noverify_force_lease" "gp --remote origin-first --no-verify --force-with-lease" "git-push-origin-first-no-verify-force-with-lease")
    # origin variants (no set-upstream)
    (mkAfAbbrFunction "po_origin" "gp --remote origin" "git-push-origin")
    (mkAfAbbrFunction "pof_origin_force" "gp --remote origin --force" "git-push-origin-force")
    (mkAfAbbrFunction "pof_origin_force_lease" "gp --remote origin --force-with-lease" "git-push-origin-force-with-lease")
    (mkAfAbbrFunction "pon_origin_noverify" "gp --remote origin --no-verify" "git-push-origin-no-verify")
    (mkAfAbbrFunction "ponf_origin_noverify_force" "gp --remote origin --no-verify --force" "git-push-origin-no-verify-force")
    (mkAfAbbrFunction "ponf_origin_noverify_force_lease" "gp --remote origin --no-verify --force-with-lease" "git-push-origin-no-verify-force-with-lease")
    # upstream-first variants (set-upstream)
    (mkAfAbbrFunction "pu_upstream_first" "gp --remote upstream-first" "git-push-upstream-first")
    (mkAfAbbrFunction "puf_upstream_first_force" "gp --remote upstream-first --force" "git-push-upstream-first-force")
    (mkAfAbbrFunction "puf_upstream_first_force_lease" "gp --remote upstream-first --force-with-lease" "git-push-upstream-first-force-with-lease")
    (mkAfAbbrFunction "pun_upstream_first_noverify" "gp --remote upstream-first --no-verify" "git-push-upstream-first-no-verify")
    (mkAfAbbrFunction "punf_upstream_first_noverify_force" "gp --remote upstream-first --no-verify --force" "git-push-upstream-first-no-verify-force")
    (mkAfAbbrFunction "punf_upstream_first_noverify_force_lease" "gp --remote upstream-first --no-verify --force-with-lease" "git-push-upstream-first-no-verify-force-with-lease")
    # upstream variants (no set-upstream)
    (mkAfAbbrFunction "pu_upstream" "gp --remote upstream" "git-push-upstream")
    (mkAfAbbrFunction "puf_upstream_force" "gp --remote upstream --force" "git-push-upstream-force")
    (mkAfAbbrFunction "puf_upstream_force_lease" "gp --remote upstream --force-with-lease" "git-push-upstream-force-with-lease")
    (mkAfAbbrFunction "pun_upstream_noverify" "gp --remote upstream --no-verify" "git-push-upstream-no-verify")
    (mkAfAbbrFunction "punf_upstream_noverify_force" "gp --remote upstream --no-verify --force" "git-push-upstream-no-verify-force")
    (mkAfAbbrFunction "punf_upstream_noverify_force_lease" "gp --remote upstream --no-verify --force-with-lease" "git-push-upstream-no-verify-force-with-lease")
  ];

in
{
  programs.fish.functions = lib.mkMerge [
    # Git utility functions (non-generated)
    {
      git-get-default-branch = {
        description = "Return the default branch name for the given remote";
        body = ''
          set --function remote $argv[1]
          if test -z "$remote"
            return 1
          end
          string replace "$remote/" "" (git rev-parse --abbrev-ref "$remote/HEAD")
        '';
      };

      git-get-first-remote = {
        description = "Return the first remote (upstream or origin)";
        body = ''
          set --function remotes (git remote)
          if contains upstream $remotes
            echo upstream
          else if contains origin $remotes
            echo origin
          else
            echo $remotes[1]
          end
        '';
      };

      git-checkout-default = {
        description = "Checkout the default branch of the first remote";
        body = ''
          set --function remote (git-get-first-remote)
          set --function default_branch (git-get-default-branch $remote)
          git checkout $default_branch
        '';
      };

      git-checkout-default-fetch = {
        description = "Checkout and fetch the default branch";
        body = ''
          git-checkout-default
          and git fetch --all --prune
        '';
      };

      git-checkout-default-fetch-fast-forward = {
        description = "Checkout, fetch, and fast-forward the default branch";
        body = ''
          git-checkout-default-fetch
          and git pull --ff-only
        '';
      };

      git-diff-head = {
        description = "Show diff against HEAD";
        body = "git diff HEAD";
      };

      git-diff-head-pbcopy = {
        description = "Copy diff against HEAD to clipboard";
        body = "git diff HEAD | pbcopy";
      };

      git-diff-head-files-pbcopy = {
        description = "Copy list of changed files to clipboard";
        body = "git diff HEAD --name-only | pbcopy";
      };

      git_clone_to_projects = {
        description = "Clone repository to $PROJECTS_PATH and create parent directory if needed";
        argumentNames = [ "repo_url" ];
        body = ''
          if ! set -q PROJECTS_PATH
            echo "Variable \$PROJECTS_PATH is not defined" >&2
            return 1
          end

          set regex 's/^git@github\\.com:(.+)?\\/(.+)?.git$/\1 \2/'
          set names (echo $repo_url | sed -E $regex | string split " ")

          if test (count $names) -ne 2
            echo "Invalid or unsupported repository path ($repo_url)" >&2
            return 121
          end

          set org_name $names[1]
          set repo_name $names[2]
          set org_path $PROJECTS_PATH/$org_name
          set full_path $org_path/$repo_name

          if test -e $full_path
            echo "Directory \"$full_path\" already exists" >&2
            return 121
          end

          mkdir -p $full_path && \
          git clone $repo_url $full_path && \
          set -xg __LAST_CLONED_REPO_PATH $full_path
        '';
      };

      git_clean_branches = {
        description = "Clean up merged branches";
        body = ''
          git branch --merged | grep -v '\*\|main\|master' | xargs -n 1 git branch -d
        '';
      };
    }

    # Generated git push functions (24 functions from 2 generators)
    allGitPushFunctions

    # AF abbreviation wrapper functions
    afFunctions
  ];
}
