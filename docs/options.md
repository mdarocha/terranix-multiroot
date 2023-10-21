## baseModule

Configure a base module that will be included in every root module\.
Can be used to ie\. setup common variables, options or terraform state
configuration\.

Can optionally be a function, taking as arguments the root information
and the current environment, allowing you to setup separate states for
every environment\.



*Type:*
function that evaluates to a(n) anything



*Default:*
` <function> `

*Declared by:*
 - [\./core/eval-modules/options\.nix](https://github.com/mdarocha/terranix-multiroot/tree/main/core/eval-modules/options.nix)



## providers



Define terraform providers along with their configuration\.
These providers will be available to every root module\.

Can optionally include provider-specific configuration\.



*Type:*
attribute set of (submodule)



*Default:*
` { } `



*Example:*

```
{
  azurerm = {
    pkg = pkgs.terraform-plugins.azurerm;
    config = {
      features = { };
      subscription_id = "<subscription_id>";
      tenant_id = "<tentant_id>";
    };
  };
}
```

*Declared by:*
 - [\./core/eval-modules/options\.nix](https://github.com/mdarocha/terranix-multiroot/tree/main/core/eval-modules/options.nix)



## providers\.\<name>\.config



The terraform configuration of the given provider\.
Will be injected into the “provider\.\<name>” terraform block\.



*Type:*
anything



*Default:*
` { } `



*Example:*

```
{
  features = { };
  subscription_id = "<subscription_id>";
  tenant_id = "<tentant_id>";
}
```

*Declared by:*
 - [\./core/eval-modules/options\.nix](https://github.com/mdarocha/terranix-multiroot/tree/main/core/eval-modules/options.nix)



## providers\.\<name>\.pkg



The package of the provider\. Should be a terraform provider plugin from
the nixpkgs’ terraform-providers namespace\.



*Type:*
package



*Example:*
` pkgs.terraform-plugins.azurerm `

*Declared by:*
 - [\./core/eval-modules/options\.nix](https://github.com/mdarocha/terranix-multiroot/tree/main/core/eval-modules/options.nix)



## roots



Configure terraform root modules\.
Each root module has a separate state, allowing you to split
up configuration into separate, not related units for faster and safer
terraform execution\.



*Type:*
anything

*Declared by:*
 - [\./core/eval-modules/options\.nix](https://github.com/mdarocha/terranix-multiroot/tree/main/core/eval-modules/options.nix)


