{ pkgs, lib, ...}: 

let

  mkHook = {
    name,
    PATH ? [],
    changeScript ? null,
    hookScript
  } : let path = pkgs.writeShellScriptBin name ''

    set -u
    set -o pipefail
    
    ${lib.optionalString (PATH != []) ''export PATH=$PATH:${ lib.makeBinPath PATH } ''  }


    changedFiles=""
    ${lib.optionalString (changeScript != null) ''
      changedFile="$(
        ${changeScript}
      )"

      if [ -z "$changedFiles" ]; then
        exit 123
      fi
    ''}
  
    if ! ( ${hookScript} ); then
      exit 1
    fi
    exit 0
  '';
  in {
    name = name;
    path = "${path}/bin/${name}";
  }; 

  terraform_hook = import ./terraform.nix { inherit pkgs lib mkHook; };
  
in {

  mkHook = mkHook ;

  mkTerraform = terraform_hook.mkTerraform ;

  terraform = terraform_hook.mkTerraform { terraformPkg = pkgs.terraform ; };
}
