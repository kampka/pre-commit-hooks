{ pkgs, lib, ...}: 

let

  mkHook = {
    name,
    PATH ? [],
    hookScript
  } : let 

    binPath = [ pkgs.git pkgs.coreutils pkgs.bash ] ++ PATH;
    path = pkgs.writeShellScriptBin name ''

    set -eu
    set -o pipefail
    
    export PATH=$PATH:${ lib.makeBinPath binPath }

    exec "${pkgs.writeShellScriptBin "${name}-hook" hookScript}/bin/${name}-hook"
  '';
  in {
    name = name;
    path = "${path}/bin/${name}";
  }; 

  terraform_hook = import ./terraform.nix { inherit pkgs lib mkHook; };
  scalafmt_hook = import ./scalafmt.nix { inherit pkgs lib mkHook; };
  shellcheck_hook = import ./shellcheck.nix { inherit pkgs lib mkHook; };
  nixpkgsFmt_hook = import ./nixpkgs-fmt.nix { inherit pkgs lib mkHook; };
  
in {

  mkHook = mkHook ;

  mkTerraform = terraform_hook.mkTerraform ;
  terraform = terraform_hook.mkTerraform { terraformPkg = pkgs.terraform ; };

  mkScalafmt = scalafmt_hook.mkScalafmt;
  scalafmt = scalafmt_hook.mkScalafmt { config = null; configStr = null; scalafmtPkg = pkgs.scalafmt; };

  mkShellcheck = shellcheck_hook.mkShellcheck;
  shellcheck = shellcheck_hook.mkShellcheck { shellcheckPkg = pkgs.shellcheck; };

  mkNixpkgsFmt = nixpkgsFmt_hook.mkNixpkgsFmt;
  nixpkgsFmt = nixpkgsFmt_hook.mkNixpkgsFmt {  };
}
