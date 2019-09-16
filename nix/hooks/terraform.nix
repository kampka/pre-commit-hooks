{ pkgs, lib, mkHook, ... }:

let
  hookScript = { terraformPkg }: ''
    cd $GIT_DIR
    ${terraformPkg}/bin/terraform fmt --check=True
  '';
in
{
  mkTerraform = { terraformPkg }: mkHook {
    name = "terraform";
    hookScript = hookScript { inherit terraformPkg; };
  };
}
