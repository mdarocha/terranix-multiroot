{
  description = "A wrapper around terranix, allowing easy definition of multiple terraform root modules and environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, terranix, ... }:
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
    };
}
