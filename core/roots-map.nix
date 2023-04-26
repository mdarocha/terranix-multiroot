{ pkgs, terranix, normalizedRoots, setupModule, baseModule }:

let
  inherit (builtins) listToAttrs map;

  # Generates a config.tf.json that can be executed by terraform
  config = root: env: terranix.lib.terranixConfiguration {
    inherit pkgs;
    extraArgs = { inherit env; };
    modules = [
      setupModule
      # TODO support baseModule that isn't a function
      (baseModule {
        inherit root;
        currentEnvironment = env;
      })
    ] ++ root.modules;
  };

  # Generate a map of roots to their generated configs that can be executed
  # by terraform
  configs = listToAttrs (map (root: {
    name = root.name;
    value = {
      depends = root.depends;
      configs = listToAttrs (map (env: {
        name = env;
        value = config root env;
      }) root.environments);
    };
  }) normalizedRoots);
in
configs
