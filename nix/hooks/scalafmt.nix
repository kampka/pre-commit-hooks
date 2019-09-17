{ pkgs, lib, mkHook, ... }:

let
  hookScript =
    { config
    , configStr
    , scalafmtPkg
    ,
    }: ''
      set -e
      unset GIT_DIR
      changedFiles="$(git diff --cached --name-only --diff-filter=ACM '*.scala' '*.sbt')"
      [ -z "$changedFiles" ] && exit 123
      if ! ${scalafmtPkg}/bin/scalafmt --list --non-interactive ${lib.optionalString (config != null) ''--config ${config}''} ${lib.optionalString (configStr != null) ''--config-str "${configStr}"''} $changedFiles ; then
          exit 1
      fi
      exit 0
    '';
in
{
  mkScalafmt = { config ? null, configStr ? null, scalafmtPkg }: mkHook {
    name = "scalafmt";
    hookScript = hookScript { inherit config configStr scalafmtPkg; };
  };
}
