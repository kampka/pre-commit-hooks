{ pkgs, lib, ...}: 

let

  mkHook = {
    name,
    PATH ? [],
    hookScript
  } : let 

    path = pkgs.writeShellScriptBin name ''

    set -eu
    set -o pipefail
    
    ${lib.optionalString (PATH != []) ''export PATH=$PATH:${ lib.makeBinPath PATH } ''  }

    exec "${pkgs.writeShellScriptBin "${name}-hook" hookScript}/bin/${name}-hook"
  '';
  in {
    name = name;
    path = "${path}/bin/${name}";
  }; 

  terraform_hook = import ./terraform.nix { inherit pkgs lib mkHook; };
  scalafmt_hook = import ./scalafmt.nix { inherit pkgs lib mkHook; };
  
in {

  mkHook = mkHook ;

  mkTerraform = terraform_hook.mkTerraform ;
  terraform = terraform_hook.mkTerraform { terraformPkg = pkgs.terraform ; };

  mkScalafmt = scalafmt_hook.mkScalafmt;
  scalafmt = scalafmt_hook.mkScalafmt { config = null; configStr = null; scalafmtPkg = pkgs.scalafmt; };

}
