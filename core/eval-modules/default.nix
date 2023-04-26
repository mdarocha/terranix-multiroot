{ pkgs }:

{
  getConfig = { modules, extraArgs }:
    (pkgs.lib.evalModules {
      modules = [
        ./options.nix
        { _module.args = { inherit pkgs; }; }
      ] ++ modules;
      specialArgs = extraArgs;
    }).config;
}
