{ pkgs ? import <nixpkgs> {}, ... }:
let
  lib = pkgs.lib;
  nix = import ./nix { inherit pkgs lib; };
in
{
  shellHook = nix.install;

  hooks = nix.hooks;
}
