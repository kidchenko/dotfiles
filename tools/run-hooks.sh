#!/bin/bash
#
# run-hooks.sh - Run declarative package-install hooks from config.yaml
#
# Usage:
#   bash tools/run-hooks.sh pre_package_install
#   bash tools/run-hooks.sh post_package_install
#
# Hooks are declared in ~/.config/dotfiles/config.yaml as a plain list of
# script NAMES - no paths, no inline commands:
#
#   hooks:
#     enabled: true
#     pre_package_install:
#       - check-disk-space
#     post_package_install:
#       - notify-done
#
# Resolution
#   A name resolves inside tools/hooks/ only. The file extension encodes the
#   OS, so one config works on every platform:
#
#     foo.sh   -> runs on macOS/Linux
#     foo.ps1  -> runs on Windows
#     both     -> runs on both, each platform picking its own
#
#   A listed name that resolves on THIS OS runs. A listed name that resolves
#   only for another OS is skipped. A listed name that resolves nowhere is a
#   typo, and is a hard error.
#
# Convention
#   tools/hooks/packages.custom.{sh,ps1} runs at post_package_install even if
#   it is not listed. It is optional - absence is not an error.
#
# Failure semantics
#   pre  hook fails -> abort (it is a precondition)
#   post hook fails -> warn and continue (it is a follow-up)
#
# Hooks are re-run on every `dotfiles packages` (including the weekly cron
# job), so they MUST be idempotent.
#

set -uo pipefail

PHASE="${1:-}"

DOTFILES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"
HOOKS_DIR="$DOTFILES_DIR/tools/hooks"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/config.yaml"

# Fall back to the local repo when run from a clone rather than chezmoi source
if [[ ! -d "$HOOKS_DIR" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    HOOKS_DIR="$SCRIPT_DIR/hooks"
fi

if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; DIM='\033[2m'; NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' DIM='' NC=''
fi

say()  { echo -e "${GREEN}[hooks]${NC} $1"; }
warn() { echo -e "${YELLOW}[hooks] WARN:${NC} $1" >&2; }
fail() { echo -e "${RED}[hooks] ERROR:${NC} $1" >&2; exit 1; }

case "$PHASE" in
    pre_package_install|post_package_install) ;;
    *) fail "Unknown phase '${PHASE}'. Use pre_package_install or post_package_install." ;;
esac

# Names are keys, not paths. Reject anything that could escape HOOKS_DIR.
validate_name() {
    local name="$1"
    if [[ "$name" =~ [/\\] ]] || [[ "$name" == *".."* ]]; then
        fail "Invalid hook name '$name' - names must not contain path separators or '..'"
    fi
}

# Execute one hook file. This runner only ever executes .sh hooks - the
# PowerShell twin (tools/run-hooks.ps1) executes .ps1 hooks on Windows, so
# neither side invokes the other's interpreter.
execute_hook() {
    local path="$1"
    case "$path" in
        *.sh) bash "$path" ;;
        *)    fail "Unsupported hook type: $path" ;;
    esac
}

# Resolve a name to a runnable path for THIS runner.
# Echoes the path, or nothing when the hook exists only as a .ps1 (i.e. it
# targets Windows, where run-hooks.ps1 will pick it up).
# Returns 1 when the name resolves nowhere at all (a typo).
resolve_hook() {
    local name="$1"
    local sh_path="$HOOKS_DIR/$name.sh"

    if [[ -f "$sh_path" ]]; then
        echo "$sh_path"; return 0
    fi
    # Declared, but only implemented for the other platform
    if [[ -f "$HOOKS_DIR/$name.ps1" ]]; then
        return 0
    fi
    return 1
}

# --- Gather the hook list -------------------------------------------------

hooks=()

if [[ -f "$CONFIG_FILE" ]] && command -v yq &>/dev/null; then
    # NOTE: do not write `.hooks.enabled // true` here. yq's alternative
    # operator treats `false` as empty, so `false // true` yields true and
    # the kill switch silently stops working. Read the raw value instead and
    # let anything that is not literally "false" mean enabled.
    enabled="$(yq -r '.hooks.enabled' "$CONFIG_FILE" 2>/dev/null)"
    if [[ "$enabled" == "false" ]]; then
        say "Hooks disabled in config - skipping $PHASE"
        exit 0
    fi
    while IFS= read -r name; do
        [[ -z "$name" || "$name" == "null" ]] && continue
        hooks+=("$name")
    done < <(yq -r ".hooks.${PHASE}[]?" "$CONFIG_FILE" 2>/dev/null)
elif [[ ! -f "$CONFIG_FILE" ]]; then
    # No config yet (fresh machine) - the convention hook may still apply
    :
elif ! command -v yq &>/dev/null; then
    warn "yq not installed - cannot read hooks from config"
fi

# Convention: packages.custom runs post-install whether listed or not.
# Dedupe so listing it explicitly does not run it twice.
if [[ "$PHASE" == "post_package_install" ]]; then
    already=false
    for h in ${hooks[@]+"${hooks[@]}"}; do
        [[ "$h" == "packages.custom" ]] && already=true
    done
    if [[ "$already" == false ]]; then
        if [[ -f "$HOOKS_DIR/packages.custom.sh" ]] || [[ -f "$HOOKS_DIR/packages.custom.ps1" ]]; then
            hooks+=("packages.custom")
        fi
    fi
fi

if [[ ${#hooks[@]} -eq 0 ]]; then
    exit 0
fi

# --- Run them in declared order -------------------------------------------

say "Running ${PHASE} hooks (${#hooks[@]})..."

for name in "${hooks[@]}"; do
    validate_name "$name"

    if ! path="$(resolve_hook "$name")"; then
        fail "Hook '$name' not found in $HOOKS_DIR (expected $name.sh or $name.ps1)"
    fi

    if [[ -z "$path" ]]; then
        echo -e "  ${DIM}skip${NC} $name (targets another OS)"
        continue
    fi

    say "-> $name"
    if execute_hook "$path"; then
        continue
    fi

    # pre hooks are preconditions; post hooks are follow-ups
    if [[ "$PHASE" == "pre_package_install" ]]; then
        fail "Pre-install hook '$name' failed - aborting package install"
    else
        warn "Post-install hook '$name' failed - continuing"
    fi
done

say "${PHASE} hooks complete"
