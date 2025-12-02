# Fish shell Kubernetes utility functions
{ ... }:

{
  programs.fish.functions = {
    klg = {
      description = "Kubernetes logs with fuzzy search";
      body = ''
        set -l pod (kubectl get pods --no-headers | fzf | awk '{print $1}')
        if test -n "$pod"
          kubectl logs -f $pod $argv
        end
      '';
    };

    kls = {
      description = "Kubernetes list resources with fuzzy search";
      body = ''
        set -l resource (kubectl api-resources --verbs=list --namespaced -o name | fzf)
        if test -n "$resource"
          kubectl get $resource $argv
        end
      '';
    };
  };
}
