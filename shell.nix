let
  pkgs = import <nixpkgs> {};

  pre-commit = (import ./. {});

  shellHook = pre-commit.shellHook {};
in

pkgs.mkShell {
  name = "pre-commit-hooks";
  inherit shellHook;
}
