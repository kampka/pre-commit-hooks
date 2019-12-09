{ pkgs, lib, mkHook, ... }:

let

  defaultPkg = (
    import (
      builtins.fetchTarball {
        url = "https://github.com/nix-community/nixpkgs-fmt/archive/v0.6.1.tar.gz";
        sha256 = "1iylldgyvrcarfigpbhicg6j6qyipfiqn7gybza7qajfzyprjqfa";
      }
    )
  ) {};

  hookScript =
    { nixpkgsFmtPkg
    }: ''
      set -e
      unset GIT_DIR
      changedFiles="$(git diff --cached --name-only --diff-filter=ACM '*.nix')"
      [ -z "$changedFiles" ] && exit 123
      if ! ${nixpkgsFmtPkg}/bin/nixpkgs-fmt --check $changedFiles; then
        exit 1
      fi
      exit 0
    '';
in
{
  mkNixpkgsFmt = { nixpkgsFmtPkg ? defaultPkg }: mkHook {
    name = "nixpkgs-fmt";
    hookScript = hookScript { inherit nixpkgsFmtPkg; };
  };
}
