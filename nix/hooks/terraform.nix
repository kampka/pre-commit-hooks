{ pkgs, lib, mkHook, ... }:

let
  hookScript = { terraformPkg }: ''
    cd $GIT_DIR
    if ! ${terraformPkg}/bin/terraform fmt --check=True ; then
      exit 1
    fi
    exit 0
  '';
in
{
  mkTerraform = { terraformPkg }: mkHook {
    name = "terraform";
    hookScript = hookScript { inherit terraformPkg; };
  };
}
