# pre-commit-hooks

A nixified approach for managing git pre-commit hooks in a nix shell.

## Usage
The general idea is to integrate git pre-commit hooks into your development nix-shell
and have it install the required hooks:
```nix
let
  pkgs = import <nixpkgs> {};
  pre-commit = (import ./. {});
  shellHook = pre-commit.shellHook { hooks = with pre-commit.hooks; [ terraform ]; };
in
pkgs.mkShell {
  inherit shellHook;
}
```
## Hooks
This project ships with a small variety of hooks included (more to come)
 * [Terraform](https://www.terraform.io/docs/commands/fmt.html)
 * [scalafmt](https://scalameta.org/scalafmt/)  
   (requires scalafmt >= 2.0.1 included in nixpkgs 19.09 and above)
 * [shellcheck](https://www.shellcheck.net/)
 * [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt)  
   (currently built from source upon first use until v1.0 is available in [nixpkgs](https://github.com/nixos/nixpkgs))

### Customizing existing hooks
Almost all builtin hooks also expose a hook builder function that can be used to customize the hook.
If you want to use the existing Terraform hook for example but require explicit Terraform 0.12 support,
you can simply pass that package into the terraform hook builder function:
```nix
let
  pkgs = import <nixpkgs> {};
  pre-commit = (import ./. {});

  terraformHook = pre-commit.hooks.mkTerraform { terraformPkg = pkgs.terraform_0_12; };

  shellHook = pre-commit.shellHook { hooks = [ terraformHook ]; };
in
pkgs.mkShell {
  inherit shellHook;
}
```
By convention, the builder for a `hook` is always called `mkHook`.
For ways on how to customize a specific hook, please refer to the code in the [hooks directory](nix/hooks/).

### Custom hooks
To ease the development of custom hooks, we expose the `mkHook` build helper:
```nix
let
  pkgs = import <nixpkgs> {};
  pre-commit = (import ./. {});

  customHook = pre-commit.hooks.mkHook {
    name = "some-custom-hook";
    PATH = [ pkgs.git ];
    hookScript = ''
      if [ -z "$(git diff --cached)" ]; then
        # do not allow empty commit
        exit 1
      fi
    '';
  };

  shellHook = pre-commit.shellHook { hooks = [ customHook ]; };
in
pkgs.mkShell {
  inherit shellHook;
}
```

### Local hooks
If you want to keep some hooks local, eg. you do not want to force them on your team,
you can place them into the `$GIT_DIR/hooks/pre-commit.local.d/` directory.
Every executable in that directory will be considered a valid hook script.


## Acknowledgement
This project is highly in inspired by the [`nix-pre-commit-hooks`](https://github.com/hercules-ci/nix-pre-commit-hooks/) project.
