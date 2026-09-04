#!/usr/bin/env bash
#
# check-language-boundary.sh - Enforce the bash/PowerShell separation
#
# Rule: bash scripts must never invoke PowerShell, and PowerShell scripts must
# never invoke bash. Each platform has one entry point that calls only its own
# language:
#
#   macOS/Linux   tools/dotfiles      -> *.sh
#   Windows       tools/dotfiles.ps1  -> *.ps1
#
# Shared declarations live in config.yaml, which both sides read. Only the
# executors are per-platform; the data never is.
#
# Exit 0 when the boundary holds, 1 when it is violated.
#
# Usage:
#   bash tools/check-language-boundary.sh
#   bash tools/check-language-boundary.sh --verbose
#

set -uo pipefail

VERBOSE=false
[[ "${1:-}" == "--verbose" || "${1:-}" == "-v" ]] && VERBOSE=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; DIM='\033[2m'; NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' DIM='' NC=''
fi

violations=0

# Files that are allowed to mention the other language, and why.
#   check-language-boundary.sh - this file, which must name both to detect them
is_exempt() {
    case "$1" in
        */check-language-boundary.sh) return 0 ;;
        *) return 1 ;;
    esac
}

# Strip comments and doc blocks so prose mentioning the other language does not
# register as a call. Only executable lines are inspected.
strip_bash_comments() { sed -E 's/[[:space:]]*#.*$//' "$1"; }
strip_ps_comments()   { sed -E '/^[[:space:]]*<#/,/#>/d' "$1" | sed -E 's/[[:space:]]*#.*$//'; }

# Detection is deliberately narrow: it matches INVOCATION, not mention.
# `Test-Path "$name.sh"` and `Join-Path $dir 'x.sh'` are legitimate - a runner
# has to detect that a hook is implemented for the other platform in order to
# skip it. Only actually running the other interpreter is a violation.
SQ=$'\047'
Q="[\"${SQ}]"
INTERP='(bash|sh|zsh|dash|wsl|busybox)'

# A file crosses the boundary only when it RUNS the other interpreter:
#   A) command position - start of a statement, or after & | ; ( { or a quote.
#      A bare `bash x.sh` is the normal PowerShell spelling and must be caught;
#      requiring the & call operator (as this check once did) missed it entirely.
#   B) an explicit .exe anywhere, which covers quoted paths containing spaces
#      such as & "C:\Program Files\Git\bin\bash.exe".
#   C) Start-Process / Get-Command naming the interpreter.
# Boundaries matter: "powershell.exe", "pwsh.exe" and "sha256" all contain the
# literal "sh" and must not be mistaken for the shell.
BOUND_L='(^|[^[:alnum:]_.-])'
BOUND_R='([^[:alnum:]_-]|$)'
PS_CALLS_BASH="(^|[&|;({\"${SQ}])[[:space:]]*${Q}?([^[:space:]\"${SQ}]*[/\\])?${INTERP}(\.exe)?${Q}?([[:space:]]|\$)|${BOUND_L}${INTERP}\.exe|Start-Process[^|]*${BOUND_L}${INTERP}${BOUND_R}|Get-Command[[:space:]]+${INTERP}${BOUND_R}|Invoke-BashScript"
BASH_CALLS_PS='(^|[^[:alnum:]_-])(pwsh|powershell(\.exe)?)([^[:alnum:]_-]|$)|-File[[:space:]]+[^[:space:]]*\.ps1|-ExecutionPolicy'

echo ""
echo "Language boundary check"
echo ""

# --- bash must not invoke PowerShell --------------------------------------

echo "  bash -> PowerShell"
while IFS= read -r f; do
    is_exempt "$f" && continue
    hits=$(strip_bash_comments "$f" | grep -nE "$BASH_CALLS_PS" || true)
    if [[ -n "$hits" ]]; then
        echo -e "    ${RED}VIOLATION${NC} ${f#$REPO_DIR/}"
        echo "$hits" | sed 's/^/        /'
        violations=$((violations + 1))
    elif [[ "$VERBOSE" == true ]]; then
        echo -e "    ${DIM}ok${NC} ${f#$REPO_DIR/}"
    fi
done < <(find "$REPO_DIR" -type f \( -name '*.sh' -o -name '*.sh.tmpl' -o -name '*.bash' \
    -o -name 'dotfiles' -o -name 'dot_z*' -o -name 'dot_profile*' \) \
    -not -path '*/.git/*' 2>/dev/null | sort)

# --- PowerShell must not invoke bash --------------------------------------

echo "  PowerShell -> bash"
while IFS= read -r f; do
    is_exempt "$f" && continue
    hits=$(strip_ps_comments "$f" | grep -nE "$PS_CALLS_BASH" || true)
    if [[ -n "$hits" ]]; then
        echo -e "    ${RED}VIOLATION${NC} ${f#$REPO_DIR/}"
        echo "$hits" | sed 's/^/        /'
        violations=$((violations + 1))
    elif [[ "$VERBOSE" == true ]]; then
        echo -e "    ${DIM}ok${NC} ${f#$REPO_DIR/}"
    fi
done < <(find "$REPO_DIR" -type f \( -name '*.ps1' -o -name '*.ps1.tmpl' \) \
    -not -path '*/.git/*' 2>/dev/null | sort)

echo ""
if [[ $violations -eq 0 ]]; then
    echo -e "  ${GREEN}Boundary holds - no cross-language calls${NC}"
    echo ""
    exit 0
fi

echo -e "  ${RED}$violations file(s) cross the language boundary${NC}"
echo -e "  ${YELLOW}Port the missing implementation instead of shelling out.${NC}"
echo ""
exit 1
