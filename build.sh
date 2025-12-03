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
warn() { echo -e "${YELLOW}!${NC} $1"; ((WARN++)); }
fail() { echo -e "${RED}✗${NC} $1"; ((FAIL++)); }
pass() { echo -e "${GREEN}✓${NC} $1"; ((PASS++)); }
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

# Lint shell scripts
do_lint() {
    header "Linting Shell Scripts"

    if ! has_cmd shellcheck; then
        warn "shellcheck not installed (brew install shellcheck)"
        return 0
    fi

    local scripts=()
    while IFS= read -r -d '' file; do
        scripts+=("$file")
    done < <(find "$ROOT_DIR" -name "*.sh" -type f -print0 2>/dev/null)

    # Add dotfiles CLI
    if [[ -f "$ROOT_DIR/tools/dotfiles" ]]; then
        scripts+=("$ROOT_DIR/tools/dotfiles")
    fi

    local failed=0
    for script in "${scripts[@]}"; do
        local rel_path="${script#$ROOT_DIR/}"
        if shellcheck --severity=warning "$script" 2>/dev/null; then
            pass "$rel_path"
        else
            fail "$rel_path"
            ((failed++))
        fi
    done

    if [[ $failed -eq 0 ]]; then
        say "All scripts passed linting"
    else
        say "$failed script(s) have warnings"
    fi
}

# Check bash syntax
do_syntax() {
    header "Checking Bash Syntax"

    local scripts=()
    while IFS= read -r -d '' file; do
        scripts+=("$file")
    done < <(find "$ROOT_DIR" -name "*.sh" -type f -print0 2>/dev/null)

    # Add dotfiles CLI
    if [[ -f "$ROOT_DIR/tools/dotfiles" ]]; then
        scripts+=("$ROOT_DIR/tools/dotfiles")
    fi

    local failed=0
    for script in "${scripts[@]}"; do
        local rel_path="${script#$ROOT_DIR/}"
        if bash -n "$script" 2>/dev/null; then
            pass "$rel_path"
        else
            fail "$rel_path"
            ((failed++))
        fi
    done

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

    # Count templates
    local template_count
    template_count=$(find "$ROOT_DIR/home" -name "*.tmpl" 2>/dev/null | wc -l | tr -d ' ')
    info "Found $template_count template files"

    # Check each template for basic Go template syntax
    local failed=0
    while IFS= read -r -d '' tmpl; do
        local rel_path="${tmpl#$ROOT_DIR/}"
        # Basic check: look for unclosed {{ or }}
        if grep -qE '\{\{[^}]*$' "$tmpl" 2>/dev/null; then
            fail "$rel_path (unclosed template tag)"
            ((failed++))
        elif grep -qE '^[^{]*\}\}' "$tmpl" 2>/dev/null; then
            fail "$rel_path (orphan closing tag)"
            ((failed++))
        else
            pass "$rel_path"
        fi
    done < <(find "$ROOT_DIR/home" -name "*.tmpl" -type f -print0 2>/dev/null)

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
        ((issues++))
    fi

    # Check for empty quotes
    if grep -qE '(brew|cask) ""' "$brewfile"; then
        fail "Empty package name in Brewfile"
        ((issues++))
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

    # Check if markdownlint is available
    if has_cmd markdownlint; then
        local md_files
        md_files=$(find "$ROOT_DIR" -name "*.md" -type f ! -path "*/node_modules/*" 2>/dev/null)

        if [[ -z "$md_files" ]]; then
            info "No markdown files found"
            return 0
        fi

        local failed=0
        while IFS= read -r md_file; do
            local rel_path="${md_file#$ROOT_DIR/}"
            if markdownlint "$md_file" &>/dev/null; then
                pass "$rel_path"
            else
                warn "$rel_path (has lint warnings)"
            fi
        done <<< "$md_files"
    elif has_cmd npx && [[ -f "$ROOT_DIR/node_modules/.bin/markdownlint" ]]; then
        info "Using npx markdownlint..."
        npx markdownlint "**/*.md" --ignore node_modules 2>/dev/null || warn "Markdown lint warnings found"
    else
        info "markdownlint not installed (npm install -g markdownlint-cli)"
        # Basic checks without markdownlint
        local md_count
        md_count=$(find "$ROOT_DIR" -name "*.md" -type f ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
        info "Found $md_count markdown files (install markdownlint for detailed checks)"
    fi
}

# Count files and stats
do_count() {
    header "Repository Statistics"

    cd "$ROOT_DIR"

    local shell_count template_count doc_count total_lines

    shell_count=$(find . -name "*.sh" -type f 2>/dev/null | wc -l | tr -d ' ')
    template_count=$(find . -name "*.tmpl" -type f 2>/dev/null | wc -l | tr -d ' ')
    doc_count=$(find . -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

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

    # Total lines of shell code
    total_lines=$(find . -name "*.sh" -type f -exec cat {} \; 2>/dev/null | wc -l | tr -d ' ')
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
