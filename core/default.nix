{ pkgs, modules, extraArgs, tfPreHook, tfExtraPkgs, binName, terranix, useOpenTofu }:

let
  inherit (builtins) map getAttr attrNames;

  eval-modules = import ./eval-modules { inherit pkgs; };
  cfg = eval-modules.getConfig { inherit modules extraArgs; };

  defaultEnvironments = [ "dev" "prod" ];

  normalizedRoots = map (name: let
    root = getAttr name cfg.roots;
    environments = if root ? environments then root.environments else defaultEnvironments;
    depends = if root ? depends then root.depends else [];
  in root // {
    inherit name environments depends;
  }) (attrNames cfg.roots);

  providers = import ./providers.nix {
    inherit pkgs useOpenTofu;
    providers = cfg.providers;
  };

  roots-map = import ./roots-map.nix {
    inherit pkgs terranix normalizedRoots extraArgs;
    setupModule = providers.setupModule;
    baseModule = cfg.baseModule;
  };

  ordered-roots = import ./ordered-roots.nix {
    inherit pkgs normalizedRoots;
  };
in
{
  cli = import ./cli.nix {
    inherit pkgs tfPreHook tfExtraPkgs binName ;
    terraformBin = providers.terraformBin;
    cliData = {
      roots = (pkgs.writeText "tf-configs.json" (builtins.toJSON roots-map));
      all-roots-order = ordered-roots;
    };
  };
}
