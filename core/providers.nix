{ pkgs, providers, useOpenTofu }:

# Read providers config, and setup terraformBin
# and a module with terraform configuration for providers;
let
  inherit (builtins) attrNames hasAttr map listToAttrs;

  # Provide logical and base providers by default
  defaultProviders = with pkgs.terraform-providers; {
    archive.pkg = archive;
    external.pkg = external;
    http.pkg = http;
    local.pkg = local;
    "null".pkg = pkgs.terraform-providers.null;
    random.pkg = random;
    time.pkg = time;
    tls.pkg = tls;
  };

  providers' = defaultProviders // providers;

  names = attrNames providers';

  # Definiting required_providers explictly makes sure
  # terraform can find every module.
  required-providers = listToAttrs (map
    (name:
      {
        inherit name;
        value.source = providers'.${name}.pkg.passthru.provider-source-address;
      })
    names);

  providers-configs = listToAttrs (map
    (name:
      let
        info = providers'.${name};
      in
      {
        inherit name;
        value = if hasAttr "config" info then info.config else { };
      })
    names);
in
{
  terraformBin = (if useOpenTofu then pkgs.opentofu else pkgs.terraform).withPlugins
    (_: (map (name: providers'.${name}.pkg) names));

  setupModule = {
    terraform.required_providers = required-providers;
    provider = providers-configs;
  };
}
