{ lib, ... }:

with lib;
with lib.types;

# TODO better types
# TODO support description for roots (and display them in the cli
let
  providerOpts = { ... }: {
    options = {
      pkg = mkOption {
        type = package;
        example = literalExample "pkgs.terraform-plugins.azurerm";
        description = ''
          The package of the provider. Should be a terraform provider plugin from
          the nixpkgs' terraform-providers namespace.
        '';
      };
      config = mkOption {
        default = {};
        type = anything;
        example = {
          features = {};
          subscription_id = "<subscription_id>";
          tenant_id       = "<tentant_id>";
        };
        description = ''
          The terraform configuration of the given provider.
          Will be injected into the "provider.<name>" terraform block.
        '';
      };
    };
  };
in
{
  options = {
    providers = mkOption {
      default = {};
      type = attrsOf (submodule providerOpts);
      example = {
        azurerm = {
          pkg = pkgs.terraform-plugins.azurerm;
          config = {
            features = {};
            subscription_id = "<subscription_id>";
            tenant_id       = "<tentant_id>";
          };
        };
      };
      description = ''
        Define terraform providers along with their configuration.
        These providers will be available to every root module.

        Can optionally include provider-specific configuration.
      '';
    };

    baseModule = mkOption {
      default = { ... }: {};
      type = functionTo anything;
      description = ''
        Configure a base module that will be included in every root module.
        Can be used to ie. setup common variables, options or terraform state
        configuration.

        Can optionally be a function, taking as arguments the root information
        and the current environment, allowing you to setup separate states for
        every environment.
      '';
    };

    roots = mkOption {
      description = ''
        Configure terraform root modules.
        Each root module has a separate state, allowing you to split
        up configuration into separate, not related units for faster and safer
        terraform execution.
      '';
    };
  };
}
