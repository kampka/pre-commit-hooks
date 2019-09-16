{ pkgs, lib, mkHook, ... }:

let

  defaultPkg = (import (builtins.fetchTarball "https://github.com/nix-community/nixpkgs-fmt/archive/v0.6.0.tar.gz")) {} ;

  hookScript = {
    nixpkgsFmtPkg
  }: ''
    set -e
    unset GIT_DIR
    changedFiles="$(git diff --cached --name-only --diff-filter=ACM '*.nix')"
    [ -z "$changedFiles" ] && exit 123
    exec ${nixpkgsFmtPkg}/bin/nixpkgs-fmt --check $changedFiles
    '';
in {
  mkNixpkgsFmt = { nixpkgsFmtPkg ? defaultPkg } : mkHook {
    name = "nixpkgs-fmt";
    hookScript = hookScript { inherit nixpkgsFmtPkg; };
  };
}
