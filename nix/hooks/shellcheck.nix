{ pkgs, lib, mkHook, ... }:

let
  hookScript =
    { shellcheckPkg
    ,
    }: ''
      set -e
      unset GIT_DIR
      changedFiles="$(git diff --cached --name-only --diff-filter=ACM | xargs grep -lE '^#!/.*(sh|bash|ksh)' )"
      [ -z "$changedFiles" ] && exit 123
      ${shellcheckPkg}/bin/shellcheck -a -x $changedFiles
    '';
in
{
  mkShellcheck = { shellcheckPkg }: mkHook {
    name = "shellcheck";
    hookScript = hookScript { inherit shellcheckPkg; };
  };
}
