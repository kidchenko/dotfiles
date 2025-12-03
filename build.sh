#!/bin/bash
#
# build.sh - Build and validate dotfiles locally
#
# Usage:
#   ./build.sh              # Run all checks
#   ./build.sh lint         # Only lint
#   ./build.sh test         # Only run tests
#   ./build.sh cli          # Test dotfiles CLI
#   ./build.sh brewfile     # Validate Brewfile
#   ./build.sh markdown     # Lint markdown files
#   ./build.sh validate     # Only validate templates
#   ./build.sh --help       # Show help
#

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$ROOT_DIR/tools"

# Colors
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# Counters
PASS=0
FAIL=0
WARN=0

say() { echo -e "${GREEN}[build]${NC} $1"; }
info() { echo -e "${BLUE}→${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; WARN=$((WARN + 1)); }
fail() { echo -e "${RED}✗${NC} $1"; FAIL=$((FAIL + 1)); }
pass() { echo -e "${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
header() { echo -e "\n${BOLD}$1${NC}"; }

show_help() {
    echo -e "${BOLD}build.sh${NC} - Build and validate dotfiles"
    echo ""
    echo -e "${BOLD}Usage:${NC}"
    echo "  ./build.sh [command]"
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo "  all        Run all checks (default)"
    echo "  lint       Lint shell scripts with ShellCheck"
    echo "  syntax     Check bash syntax"
    echo "  validate   Validate chezmoi templates"
    echo "  test       Run doctor in test mode"
    echo "  cli        Test dotfiles CLI commands"
    echo "  brewfile   Validate Brewfile"
    echo "  markdown   Lint markdown files"
    echo "  count      Count files and stats"
    echo "  help       Show this help"
    echo ""
}

# Check if a command exists
has_cmd() {
    command -v "$1" &>/dev/null
}

# Get all shell scripts in the repo
get_shell_scripts() {
    # Known directories containing shell scripts
    local dirs=(
        "$ROOT_DIR/tools"
        "$ROOT_DIR/tools/os_installers"
        "$ROOT_DIR/tools/os_setup"
        "$ROOT_DIR/scripts"
        "$ROOT_DIR/scripts/backup"
        "$ROOT_DIR/scripts/custom"
        "$ROOT_DIR/cron"
        "$ROOT_DIR/brave"
        "$ROOT_DIR"
    )

    for dir in "${dirs[@]}"; do
        [[ -d "$dir" ]] || continue
        for f in "$dir"/*.sh; do
            [[ -f "$f" ]] && echo "$f"
        done
    done
}

# Get all template files
get_template_files() {
    # Recursively find .tmpl files in home/
    for dir in "$ROOT_DIR"/home "$ROOT_DIR"/home/*/ "$ROOT_DIR"/home/*/*/ "$ROOT_DIR"/home/*/*/*/; do
        [[ -d "$dir" ]] || continue
        for f in "$dir"/*.tmpl; do
            [[ -f "$f" ]] && echo "$f"
        done
    done 2>/dev/null
}

# Get all markdown files
get_markdown_files() {
    for dir in "$ROOT_DIR" "$ROOT_DIR"/docs "$ROOT_DIR"/docs/commands; do
        [[ -d "$dir" ]] || continue
        for f in "$dir"/*.md; do
            [[ -f "$f" ]] && echo "$f"
        done
    done
}

# Lint shell scripts
do_lint() {
    header "Linting Shell Scripts"

    if ! has_cmd shellcheck; then
        warn "shellcheck not installed (brew install shellcheck)"
        return 0
    fi

    local failed=0
    local scripts
    scripts=$(get_shell_scripts)

    local OLD_IFS="$IFS"
    IFS=$'\n'
    for script in $scripts; do
        [[ -z "$script" ]] && continue
        local rel_path="${script#$ROOT_DIR/}"
        if shellcheck --severity=warning "$script" 2>/dev/null; then
            pass "$rel_path"
        else
            fail "$rel_path"
            failed=$((failed + 1))
        fi
    done
    IFS="$OLD_IFS"

    # Add dotfiles CLI
    if [[ -f "$ROOT_DIR/tools/dotfiles" ]]; then
        if shellcheck --severity=warning "$ROOT_DIR/tools/dotfiles" 2>/dev/null; then
            pass "tools/dotfiles"
        else
            fail "tools/dotfiles"
            failed=$((failed + 1))
        fi
    fi

    if [[ $failed -eq 0 ]]; then
        say "All scripts passed linting"
    else
        say "$failed script(s) have warnings"
    fi
}

# Check bash syntax
do_syntax() {
    header "Checking Bash Syntax"

    local failed=0
    local scripts
    scripts=$(get_shell_scripts)

    local OLD_IFS="$IFS"
    IFS=$'\n'
    for script in $scripts; do
        [[ -z "$script" ]] && continue
        local rel_path="${script#$ROOT_DIR/}"
        if bash -n "$script" 2>/dev/null; then
            pass "$rel_path"
        else
            fail "$rel_path"
            failed=$((failed + 1))
        fi
    done
    IFS="$OLD_IFS"

    # Add dotfiles CLI
    if [[ -f "$ROOT_DIR/tools/dotfiles" ]]; then
        if bash -n "$ROOT_DIR/tools/dotfiles" 2>/dev/null; then
            pass "tools/dotfiles"
        else
            fail "tools/dotfiles"
            failed=$((failed + 1))
        fi
    fi

    if [[ $failed -eq 0 ]]; then
        say "All scripts have valid syntax"
    else
        fail "$failed script(s) have syntax errors"
        return 1
    fi
}

# Validate chezmoi templates
do_validate() {
    header "Validating Chezmoi Templates"

    if ! has_cmd chezmoi; then
        warn "chezmoi not installed"
        return 0
    fi

    # Get template files
    local template_count=0
    local failed=0
    local templates
    templates=$(get_template_files)

    local OLD_IFS="$IFS"
    IFS=$'\n'
    for tmpl in $templates; do
        [[ -z "$tmpl" ]] && continue
        template_count=$((template_count + 1))
        local rel_path="${tmpl#$ROOT_DIR/}"
        # Basic check: look for unclosed {{ or }}
        if grep -qE '\{\{[^}]*$' "$tmpl" 2>/dev/null; then
            fail "$rel_path (unclosed template tag)"
            failed=$((failed + 1))
        elif grep -qE '^[^{]*\}\}' "$tmpl" 2>/dev/null; then
            fail "$rel_path (orphan closing tag)"
            failed=$((failed + 1))
        else
            pass "$rel_path"
        fi
    done
    IFS="$OLD_IFS"

    info "Found $template_count template files"

    if [[ $failed -eq 0 ]]; then
        say "All templates look valid"
    else
        fail "$failed template(s) have issues"
    fi
}

# Run doctor as a test
do_test() {
    header "Running Doctor (Test Mode)"

    if [[ -f "$TOOLS_DIR/doctor.sh" ]]; then
        if bash "$TOOLS_DIR/doctor.sh" --quick; then
            pass "Doctor passed"
        else
            warn "Doctor reported issues (may be expected)"
        fi
    else
        fail "doctor.sh not found"
    fi
}

# Test dotfiles CLI
do_test_cli() {
    header "Testing Dotfiles CLI"

    local cli="$TOOLS_DIR/dotfiles"

    if [[ ! -f "$cli" ]]; then
        fail "dotfiles CLI not found"
        return 1
    fi

    # Test help command
    if bash "$cli" help &>/dev/null; then
        pass "dotfiles help"
    else
        fail "dotfiles help"
    fi

    # Test cd command
    local cd_output
    cd_output=$(bash "$cli" cd 2>/dev/null)
    if [[ -n "$cd_output" ]]; then
        pass "dotfiles cd → $cd_output"
    else
        fail "dotfiles cd"
    fi

    # Test status command (if in git repo)
    if [[ -d "$ROOT_DIR/.git" ]]; then
        if bash "$cli" status &>/dev/null; then
            pass "dotfiles status"
        else
            warn "dotfiles status (may need git setup)"
        fi
    fi
}

# Validate Brewfile
do_brewfile() {
    header "Validating Brewfile"

    local brewfile="$ROOT_DIR/Brewfile"

    if [[ ! -f "$brewfile" ]]; then
        warn "Brewfile not found"
        return 0
    fi

    # Count entries
    local formulae casks taps
    formulae=$(grep -cE "^brew " "$brewfile" 2>/dev/null || echo 0)
    casks=$(grep -cE "^cask " "$brewfile" 2>/dev/null || echo 0)
    taps=$(grep -cE "^tap " "$brewfile" 2>/dev/null || echo 0)

    info "Formulae: $formulae, Casks: $casks, Taps: $taps"

    # Check for syntax issues (basic validation)
    local issues=0

    # Check for duplicate entries
    local dupes
    dupes=$(grep -E "^(brew|cask) " "$brewfile" | sort | uniq -d)
    if [[ -n "$dupes" ]]; then
        fail "Duplicate Brewfile entries found:"
        echo "$dupes" | while read -r line; do
            echo "    $line"
        done
        issues=$((issues + 1))
    fi

    # Check for empty quotes
    if grep -qE '(brew|cask) ""' "$brewfile"; then
        fail "Empty package name in Brewfile"
        issues=$((issues + 1))
    fi

    # Validate with brew bundle if available
    if has_cmd brew; then
        if brew bundle check --file="$brewfile" &>/dev/null; then
            pass "Brewfile syntax valid (brew bundle check)"
        else
            warn "Some Brewfile packages not installed (expected)"
        fi
    else
        info "Skipping brew bundle check (Homebrew not installed)"
    fi

    if [[ $issues -eq 0 ]]; then
        pass "Brewfile validation passed"
    fi
}

# Lint markdown files
do_markdown() {
    header "Linting Markdown"

    local md_count=0
    local md_files
    md_files=$(get_markdown_files)

    # Check if markdownlint is available
    if has_cmd markdownlint; then
        local OLD_IFS="$IFS"
        IFS=$'\n'
        for md_file in $md_files; do
            [[ -z "$md_file" ]] && continue
            md_count=$((md_count + 1))
            local rel_path="${md_file#$ROOT_DIR/}"
            if markdownlint "$md_file" &>/dev/null; then
                pass "$rel_path"
            else
                warn "$rel_path (has lint warnings)"
            fi
        done
        IFS="$OLD_IFS"
    elif has_cmd npx && [[ -f "$ROOT_DIR/node_modules/.bin/markdownlint" ]]; then
        info "Using npx markdownlint..."
        npx markdownlint "**/*.md" --ignore node_modules 2>/dev/null || warn "Markdown lint warnings found"
    else
        # Count markdown files
        local OLD_IFS="$IFS"
        IFS=$'\n'
        for _ in $md_files; do
            md_count=$((md_count + 1))
        done
        IFS="$OLD_IFS"
        info "markdownlint not installed (npm install -g markdownlint-cli)"
        info "Found $md_count markdown files (install markdownlint for detailed checks)"
    fi
}

# Count files and stats
do_count() {
    header "Repository Statistics"

    cd "$ROOT_DIR"

    # Count files using helper functions
    local shell_count=0
    local template_count=0
    local doc_count=0
    local total_lines=0

    local scripts templates docs
    scripts=$(get_shell_scripts)
    templates=$(get_template_files)
    docs=$(get_markdown_files)

    local OLD_IFS="$IFS"
    IFS=$'\n'
    for f in $scripts; do
        [[ -z "$f" ]] && continue
        shell_count=$((shell_count + 1))
        [[ -f "$f" ]] && total_lines=$((total_lines + $(wc -l < "$f")))
    done

    for _ in $templates; do
        template_count=$((template_count + 1))
    done

    for _ in $docs; do
        doc_count=$((doc_count + 1))
    done
    IFS="$OLD_IFS"

    # Count Brewfile entries
    local brew_formulae brew_casks
    brew_formulae=$(grep -cE "^brew " Brewfile 2>/dev/null || echo 0)
    brew_casks=$(grep -cE "^cask " Brewfile 2>/dev/null || echo 0)

    echo ""
    echo "  Shell scripts:    $shell_count"
    echo "  Templates:        $template_count"
    echo "  Documentation:    $doc_count"
    echo ""
    echo "  Brewfile formulae: $brew_formulae"
    echo "  Brewfile casks:    $brew_casks"
    echo ""
    echo "  Total shell lines: $total_lines"
}

# Run all checks
do_all() {
    say "Running all build checks..."
    echo ""

    do_syntax
    do_lint
    do_validate
    do_test
    do_test_cli
    do_brewfile
    do_markdown
    do_count

    # Summary
    header "Build Summary"
    echo -e "${GREEN}✓ $PASS passed${NC}"
    if [[ $WARN -gt 0 ]]; then
        echo -e "${YELLOW}! $WARN warnings${NC}"
    fi
    if [[ $FAIL -gt 0 ]]; then
        echo -e "${RED}✗ $FAIL failed${NC}"
        exit 1
    fi

    echo ""
    say "Build completed successfully!"
}

# Main
main() {
    cd "$ROOT_DIR"

    case "${1:-all}" in
        all)       do_all ;;
        lint)      do_lint ;;
        syntax)    do_syntax ;;
        validate)  do_validate ;;
        test)      do_test ;;
        cli)       do_test_cli ;;
        brewfile)  do_brewfile ;;
        markdown)  do_markdown ;;
        count)     do_count ;;
        help|--help|-h) show_help ;;
        *)
            fail "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
