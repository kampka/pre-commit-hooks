let
  pkgs = import <nixpkgs> {};

  pre-commit = (import ./. {});

  shellHook = pre-commit.shellHook { hooks = [ pre-commit.hooks.nixpkgsFmt ]; };
in

pkgs.mkShell {
  name = "pre-commit-hooks";
  inherit shellHook;
}
