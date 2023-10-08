{ pkgs, providers, useOpenTofu }:

# Read providers config, and setup terraformBin
# and a module with terraform configuration for providers;
let
  inherit (builtins) attrNames getAttr map listToAttrs;

  names = attrNames providers;

  # Definiting required_providers explictly makes sure
  # terraform can find every module.
  required-providers = listToAttrs (map (name: let
    pkg = (getAttr name providers).pkg;
  in {
    inherit name;
    value.source = pkg.passthru.provider-source-address;
  }) names);

  providers-configs = listToAttrs (map (name: let
    provider = getAttr name providers;
  in {
    inherit name;
    value = provider.config;
  }) names);
in
{
  terraformBin = (if useOpenTofu then pkgs.opentofu else pkgs.terraform).withPlugins
    (_: (map (name: (getAttr name providers).pkg) names)
    # Provide logical and base providers by default
    ++ (with pkgs.terraform-providers; [
      archive
      external
      http
      local
      pkgs.terraform-providers.null
      random
      time
      tls
    ]));

  setupModule = {
    terraform.required_providers = required-providers;
    provider = providers-configs;
  };
}
