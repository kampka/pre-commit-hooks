{ pkgs, lib, ...}: 

let

  mkHook = {
    name,
    PATH ? [],
    skipScript ? null,
    hookScript
  } : let 

    path = pkgs.writeShellScriptBin name ''

    set -u
    set -o pipefail
    
    ${lib.optionalString (PATH != []) ''export PATH=$PATH:${ lib.makeBinPath PATH } ''  }

    ${lib.optionalString (skipScript != null) ''
      if ! "${pkgs.writeShellScriptBin "${name}-skip" skipScript}/bin/${name}-skip"; then
        exit 123
      fi
    ''}
  
    if ! "${pkgs.writeShellScriptBin "${name}-hook" hookScript}/bin/${name}-hook"; then
      exit 1
    fi
    exit 0
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
