{ pkgs, lib, ... }:

with lib;

let

  pre-commit = { hooks ? [] }: pkgs.writeScriptBin "pre-commit" ''
    set -u
    set -o pipefail

    git_hook_args="$@"

    [ "''${GIT_PRE_COMMIT_DEBUG:-false}" = "true" ] && set -x

    export GIT_DIR=''${GIT_DIR:-"$(realpath $(dirname $0)/../..)"}

    NORMAL="''${GIT_PRE_COMMIT_COLOR_RED:-$(tput sgr0)}"
    RED="''${GIT_PRE_COMMIT_COLOR_RED:-$(tput setaf 1)}"
    GREEN="''${GIT_PRE_COMMIT_COLOR_GREEN:-$(tput setaf 2)}"
    BLUE="''${GIT_PRE_COMMIT_COLOR_BLUE:-$(tput setaf 6)}"

    print_hook_error() {
      align="$(echo $1 | wc -c)"
      column=$((100 - $align))
      printf '%s%*s%s\n' "$RED" $column "[FAIL]" "$NORMAL"
    }
    print_hook_skip() {
      align="$(echo $1 | wc -c)"
      column=$((100 - $align))
      printf '%s%*s%s\n' "$BLUE" $column "[SKIP]" "$NORMAL"
    }
    print_hook_ok() {
      align="$(echo $1 | wc -c)"
      column=$((100 - $align))
      printf '%s%*s%s\n' "$GREEN" $column "[ OK ]" "$NORMAL"
    }

    exitcodes=""
    tempdir="$(mktemp -d)"
    trap "rm -rf $tempdir" EXIT

    run_hook() {
      local hookFile="$1"
      local hookName="$2"
      local logfile="$(TMPDIR=$tempdir mktemp)"

      printf "  $hookName"
      "$hookFile" $git_hook_args &> "$logfile"
      exitcode="$?"

      case $exitcode in
        0)
          print_hook_ok "$hookName"
          ;;
        123)
          print_hook_skip "$hookName"
          ;;
        *)
          print_hook_error "$hookName"
          exitcodes="$exitcodes $exitcode"
          cat "$logfile" | sed 's/\(.*\)/    \1/'
          ;;
      esac

    }
    printf "Running pre-commit hooks ...\n"

    ${concatStringsSep "\n" (
    map (
      hook: ''
        run_hook "${hook.path}" "${hook.name}"
      ''
    ) hooks
  )}

    # Run local and legacy hooks
    if [ -d "$GIT_DIR/pre-commit.local.d" ]; then
      for hook in "$GIT_DIR/pre-commit.local.d"/* ; do
        if [ -x "$hook" ]; then
          run_hook "$hook" "$(basename $hook) (local)"
        fi
      done
    fi

    for i in $exitcodes; do
      [ $i -eq 0 ] || exit $i
    done

  '';

  install = { hooks ? [] }: ''
    set -eu
    set -o pipefail

    if git config core.hooksPath; then
        echo "Refusing to install pre-commit hooks when core.hooksPath is set." 1>&2
        exit 1
    fi

    GIT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    if ! ([ -n "$GIT_DIR" ] && [ -d "$GIT_DIR" ]); then
        echo "Failed to detect git root directory. Aborting" 1>&2
        exit 1
    fi

    GIT_HOOKS_DIR="$GIT_DIR/.git/hooks"
    if ! [ -d "$GIT_HOOKS_DIR" ]; then
        echo "Git hooks directory does not exist at $GIT_HOOKS_DIR" 1>&2
        exit 1
    fi


    if [ -f "$GIT_HOOKS_DIR/pre-commit" ] && ! [ -L "$GIT_HOOKS_DIR/pre-commit" ]; then
        echo "There is already a pre-commit hook installed in your git repository." 1>&2
        echo "If you want to keep it, please move it to \$GIT_DIR/hooks/pre-commit.local.d before continuing." 1>&2
        exit 1
    fi

    [ -L "$GIT_HOOKS_DIR/pre-commit" ] && unlink "$GIT_HOOKS_DIR/pre-commit"

    ln -s ${(pre-commit { inherit hooks; })}/bin/pre-commit "$GIT_HOOKS_DIR/pre-commit"
  '';
in
{
  install = install;

  hooks = import ./hooks { inherit pkgs lib; };
}
