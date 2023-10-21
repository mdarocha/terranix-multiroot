{
  description = "A wrapper around terranix, allowing easy definition of multiple terraform root modules and environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, terranix, ... }:
    {
      # creates a cli app that runs the defined roots
      lib.mkCli =
        { system ? ""
        , pkgs ? builtins.getAttr system nixpkgs.legacyPackages
        , modules ? [ ] # used to define your roots
        , extraArgs ? { }
        , tfPreHook ? "" # hook to run before terraform is called
        , tfExtraPkgs ? [ ] # additional binaries to make available in PATH to the terraform binary
        , binName ? "tf"
        , useOpenTofu ? false # set to true to use OpenTofu instead of Terraform
        }:
        let
          terranixMultiroot = import ./core/default.nix {
            inherit pkgs modules extraArgs tfPreHook tfExtraPkgs binName useOpenTofu;
            inherit terranix;
          };
        in
        terranixMultiroot.cli;

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      packages.x86_64-linux.docs =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          lib = pkgs.lib;
          inherit (lib.lists) map;
          inherit (lib.strings) removePrefix;

          revision = "main";
        in
        (pkgs.nixosOptionsDoc {
          options = (lib.modules.evalModules {
            modules = [ ./core/eval-modules/options.nix ];
          }).options // { "_module" = { }; };
          inherit revision;
          transformOptions = option: option // {
            declarations = map
              (path:
                let
                  path' = removePrefix "${self}/" path;
                in
                {
                  name = "./${path'}";
                  url = "https://github.com/mdarocha/terranix-multiroot/tree/${revision}/${path'}";
                })
              option.declarations;
          };
        }).optionsCommonMark;
    };
}
