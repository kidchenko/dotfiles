#!/usr/bin/env bash

# git-batch-commit.sh
#
# Batch commit script for multiple git repositories
# Goes through all subdirectories in a given folder and commits changes in git repositories
#
# Usage: ./git-batch-commit.sh [OPTIONS] <directory>
#
# Options:
#   -m, --message <msg>   Commit message (default: "chore: auto-push")
#   -p, --push            Push after committing
#   -r, --remove-after-push   Remove repository after successful push (DESTRUCTIVE!)
#   -f, --force           Skip confirmation prompts
#   -d, --dry-run         Show what would be done without making changes
#   -v, --verbose         Verbose output
#   -h, --help            Show this help message

set -e

# --- Configuration ---
COMMIT_MESSAGE="chore: auto-push"
PUSH_AFTER_COMMIT=false
REMOVE_AFTER_PUSH=false
FORCE=false
DRY_RUN=false
VERBOSE=false
TARGET_DIR=""

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Helper Functions ---
say() {
    echo -e "${BLUE}[batch-commit]${NC} $1"
}

say_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}[verbose]${NC} $1"
    fi
}

say_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

say_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

say_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS] <directory>

Batch commit script for multiple git repositories.
Goes through all subdirectories in a given folder and commits changes in git repositories.

OPTIONS:
    -m, --message <msg>       Commit message (default: "chore: auto-push")
    -p, --push                Push after committing
    -r, --remove-after-push   Remove repository after successful push (DESTRUCTIVE!)
    -f, --force               Skip confirmation prompts
    -d, --dry-run             Show what would be done without making changes
    -v, --verbose             Verbose output
    -h, --help                Show this help message

EXAMPLES:
    # Commit all changes in ~/projects subdirectories
    $0 ~/projects

    # Commit with custom message
    $0 -m "feat: update all repos" ~/projects

    # Commit and push
    $0 -p ~/projects

    # Commit, push, and remove repositories (DANGEROUS!)
    $0 -p -r ~/projects

    # Same as above but skip confirmations
    $0 -p -r -f ~/projects

    # Dry run to see what would happen
    $0 -d ~/projects

WARNING:
    --remove-after-push is a DESTRUCTIVE operation that will permanently delete
    the local repository directory after successfully pushing changes.
    Use with extreme caution!

EOF
}

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -m|--message)
            if [ -n "$2" ]; then
                COMMIT_MESSAGE="$2"
                shift 2
            else
                say_error "--message option requires an argument."
                exit 1
            fi
            ;;
        -p|--push)
            PUSH_AFTER_COMMIT=true
            shift
            ;;
        -r|--remove-after-push)
            REMOVE_AFTER_PUSH=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$1"
                shift
            else
                say_error "Unknown parameter: $1"
                exit 1
            fi
            ;;
    esac
done

# --- Validation ---
if [ -z "$TARGET_DIR" ]; then
    say_error "No directory specified."
    echo ""
    show_help
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    say_error "Directory does not exist: $TARGET_DIR"
    exit 1
fi

# Validate remove-after-push requires push
if [ "$REMOVE_AFTER_PUSH" = true ] && [ "$PUSH_AFTER_COMMIT" = false ]; then
    say_error "--remove-after-push requires --push to be enabled"
    exit 1
fi

# --- Main Logic ---
main() {
    say "Starting batch commit process..."
    say "Target directory: $TARGET_DIR"
    say "Commit message: '$COMMIT_MESSAGE'"

    if [ "$PUSH_AFTER_COMMIT" = true ]; then
        say "Push after commit: ${GREEN}enabled${NC}"
    fi

    if [ "$REMOVE_AFTER_PUSH" = true ]; then
        say_warning "Remove after push: ${RED}enabled (DESTRUCTIVE!)${NC}"

        if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
            echo ""
            say_error "WARNING: This will PERMANENTLY DELETE repositories after pushing!"
            read -p "Are you sure you want to continue? Type 'yes' to confirm: " confirm
            if [ "$confirm" != "yes" ]; then
                say "Operation cancelled."
                exit 0
            fi
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        say_warning "DRY RUN MODE - No changes will be made"
    fi

    echo ""

    # Counters
    local total_repos=0
    local committed_repos=0
    local skipped_repos=0
    local failed_repos=0
    local removed_repos=0

    # Find all directories (one level deep)
    # If you want to search recursively, change -maxdepth 1 to -maxdepth <n>
    while IFS= read -r -d '' dir; do
        local repo_name=$(basename "$dir")

        # Check if it's a git repository
        if [ ! -d "$dir/.git" ]; then
            say_verbose "Skipping '$repo_name' (not a git repository)"
            continue
        fi

        total_repos=$((total_repos + 1))

        say_verbose "Processing '$repo_name'..."

        # Change to repository directory
        pushd "$dir" > /dev/null 2>&1

        # Check if there are changes to commit
        if git diff-index --quiet HEAD -- 2>/dev/null && [ -z "$(git ls-files --others --exclude-standard)" ]; then
            say_verbose "  No changes in '$repo_name'"
            skipped_repos=$((skipped_repos + 1))
            popd > /dev/null 2>&1
            continue
        fi

        say "Processing ${YELLOW}$repo_name${NC}..."

        # Show status
        if [ "$VERBOSE" = true ]; then
            git status --short
        fi

        # Add all changes
        if [ "$DRY_RUN" = true ]; then
            say_verbose "  Would run: git add :/"
        else
            if git add :/ 2>/dev/null; then
                say_verbose "  ✓ Staged all changes"
            else
                say_error "  Failed to stage changes in '$repo_name'"
                failed_repos=$((failed_repos + 1))
                popd > /dev/null 2>&1
                continue
            fi
        fi

        # Commit changes
        if [ "$DRY_RUN" = true ]; then
            say_verbose "  Would run: git commit -m \"$COMMIT_MESSAGE\""
        else
            if git commit -m "$COMMIT_MESSAGE" > /dev/null 2>&1; then
                say_success "  Committed changes in '$repo_name'"
                committed_repos=$((committed_repos + 1))
            else
                say_error "  Failed to commit changes in '$repo_name'"
                failed_repos=$((failed_repos + 1))
                popd > /dev/null 2>&1
                continue
            fi
        fi

        # Push if requested
        local push_successful=false
        if [ "$PUSH_AFTER_COMMIT" = true ]; then
            if [ "$DRY_RUN" = true ]; then
                say_verbose "  Would run: git push"
                push_successful=true
            else
                say_verbose "  Pushing..."
                local push_output=$(git push 2>&1)
                if echo "$push_output" | grep -q "error\|fatal"; then
                    say_warning "  Failed to push '$repo_name' (might need to set upstream)"
                    push_successful=false
                else
                    say_verbose "  ✓ Pushed successfully"
                    push_successful=true
                fi
            fi
        fi

        popd > /dev/null 2>&1

        # Remove repository after successful push if requested
        if [ "$REMOVE_AFTER_PUSH" = true ] && [ "$push_successful" = true ]; then
            if [ "$DRY_RUN" = true ]; then
                say_warning "  Would remove: $dir"
            else
                say_warning "  Removing repository: $repo_name"
                if rm -rf "$dir"; then
                    say_success "  ✓ Removed '$repo_name'"
                    removed_repos=$((removed_repos + 1))
                else
                    say_error "  Failed to remove '$repo_name'"
                fi
            fi
        fi

    done < <(find "$TARGET_DIR" -maxdepth 1 -mindepth 1 -type d -print0)

    # Summary
    echo ""
    say "=========================================="
    say "Batch commit complete!"
    say "=========================================="
    echo ""
    say "Total repositories found:  $total_repos"
    say_success "Committed:                 $committed_repos"
    say_warning "Skipped (no changes):      $skipped_repos"

    if [ "$failed_repos" -gt 0 ]; then
        say_error "Failed:                    $failed_repos"
    fi

    if [ "$REMOVE_AFTER_PUSH" = true ] && [ "$removed_repos" -gt 0 ]; then
        say_warning "Removed:                   $removed_repos"
    fi

    echo ""

    if [ "$DRY_RUN" = true ]; then
        say_warning "This was a DRY RUN - no actual changes were made"
    fi
}

# --- Execute Main ---
main

exit 0
