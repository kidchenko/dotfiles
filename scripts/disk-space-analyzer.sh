#!/bin/bash

# Disk Space Analyzer for macOS
# Helps identify what's taking up space in System Data and other areas

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper function to format bytes to human readable
format_size() {
    local size=$1
    if [[ $size -ge 1073741824 ]]; then
        echo "$(echo "scale=2; $size/1073741824" | bc) GB"
    elif [[ $size -ge 1048576 ]]; then
        echo "$(echo "scale=2; $size/1048576" | bc) MB"
    elif [[ $size -ge 1024 ]]; then
        echo "$(echo "scale=2; $size/1024" | bc) KB"
    else
        echo "$size B"
    fi
}

# Get directory size in bytes (returns 0 if doesn't exist)
get_dir_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sk "$dir" 2>/dev/null | cut -f1 | awk '{print $1 * 1024}'
    else
        echo "0"
    fi
}

# Get directory size human readable
get_dir_size_human() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sh "$dir" 2>/dev/null | cut -f1
    else
        echo "N/A"
    fi
}

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

print_section() {
    echo ""
    echo -e "${BOLD}${YELLOW}▶ $1${NC}"
    echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
}

print_item() {
    local label="$1"
    local value="$2"
    local warning="$3"

    if [[ "$warning" == "true" ]]; then
        echo -e "  ${RED}●${NC} ${label}: ${RED}${BOLD}${value}${NC}"
    else
        echo -e "  ${GREEN}●${NC} ${label}: ${value}"
    fi
}

print_header "macOS Disk Space Analyzer"
echo -e "  Analyzing disk usage... This may take a moment."

# Overall disk usage
print_section "Overall Disk Usage"
df -h / | tail -1 | awk '{print "  Total: "$2"  Used: "$3"  Available: "$4"  Capacity: "$5}'

# Time Machine Local Snapshots
print_section "Time Machine Local Snapshots"
snapshots=$(tmutil listlocalsnapshots / 2>/dev/null | grep -c "com.apple" || echo "0")
if [[ $snapshots -gt 0 ]]; then
    print_item "Local snapshots found" "$snapshots snapshots" "true"
    echo -e "  ${YELLOW}Tip: Run 'sudo tmutil deletelocalsnapshots /' to remove${NC}"
    tmutil listlocalsnapshots / 2>/dev/null | head -5
    if [[ $snapshots -gt 5 ]]; then
        echo "  ... and $((snapshots - 5)) more"
    fi
else
    print_item "Local snapshots" "None found"
fi

# User Caches
print_section "Cache Directories"
user_cache=$(get_dir_size_human ~/Library/Caches)
print_item "User Caches (~/Library/Caches)" "$user_cache"

system_cache=$(get_dir_size_human /Library/Caches 2>/dev/null || echo "N/A")
print_item "System Caches (/Library/Caches)" "$system_cache"

# Show largest cache directories
echo ""
echo "  Largest cache directories:"
du -sh ~/Library/Caches/*/ 2>/dev/null | sort -hr | head -5 | while read size dir; do
    echo "    $size  $(basename "$dir")"
done

# Application Support
print_section "Application Support"
app_support=$(get_dir_size_human ~/Library/Application\ Support)
print_item "Application Support" "$app_support"

echo ""
echo "  Largest Application Support directories:"
du -sh ~/Library/Application\ Support/*/ 2>/dev/null | sort -hr | head -5 | while read size dir; do
    echo "    $size  $(basename "$dir")"
done

# iOS Device Backups
print_section "iOS Device Backups"
backup_dir=~/Library/Application\ Support/MobileSync/Backup
if [[ -d "$backup_dir" ]]; then
    backup_size=$(get_dir_size_human "$backup_dir")
    backup_count=$(ls -1 "$backup_dir" 2>/dev/null | wc -l | tr -d ' ')
    print_item "iOS Backups" "$backup_size ($backup_count backup(s))" "true"
    echo -e "  ${YELLOW}Tip: Manage in Finder > iPhone > Manage Backups${NC}"
else
    print_item "iOS Backups" "None found"
fi

# Homebrew
print_section "Homebrew"
if command -v brew &> /dev/null; then
    brew_cache=$(get_dir_size_human "$(brew --cache)" 2>/dev/null || echo "N/A")
    brew_cellar=$(get_dir_size_human "$(brew --cellar)" 2>/dev/null || echo "N/A")
    print_item "Homebrew Cache" "$brew_cache"
    print_item "Homebrew Cellar" "$brew_cellar"
    echo -e "  ${YELLOW}Tip: Run 'brew cleanup --prune=all' to clean cache${NC}"
else
    print_item "Homebrew" "Not installed"
fi

# Development Tools
print_section "Development Tools"

# Xcode
if [[ -d ~/Library/Developer ]]; then
    xcode_derived=$(get_dir_size_human ~/Library/Developer/Xcode/DerivedData 2>/dev/null || echo "N/A")
    xcode_archives=$(get_dir_size_human ~/Library/Developer/Xcode/Archives 2>/dev/null || echo "N/A")
    xcode_simulators=$(get_dir_size_human ~/Library/Developer/CoreSimulator 2>/dev/null || echo "N/A")
    developer_total=$(get_dir_size_human ~/Library/Developer)

    print_item "Developer folder total" "$developer_total"
    print_item "Xcode DerivedData" "$xcode_derived"
    print_item "Xcode Archives" "$xcode_archives"
    print_item "iOS Simulators" "$xcode_simulators"
    echo -e "  ${YELLOW}Tip: Run 'rm -rf ~/Library/Developer/Xcode/DerivedData/*' to clean${NC}"
else
    print_item "Xcode/Developer" "Not found"
fi

# npm
if [[ -d ~/.npm ]]; then
    npm_cache=$(get_dir_size_human ~/.npm)
    print_item "npm cache" "$npm_cache"
    echo -e "  ${YELLOW}Tip: Run 'npm cache clean --force' to clean${NC}"
fi

# yarn
if [[ -d ~/.yarn/cache ]] || [[ -d ~/Library/Caches/Yarn ]]; then
    yarn_cache=$(get_dir_size_human ~/Library/Caches/Yarn 2>/dev/null || get_dir_size_human ~/.yarn/cache 2>/dev/null || echo "N/A")
    print_item "Yarn cache" "$yarn_cache"
fi

# pip
if [[ -d ~/Library/Caches/pip ]]; then
    pip_cache=$(get_dir_size_human ~/Library/Caches/pip)
    print_item "pip cache" "$pip_cache"
fi

# Docker
print_section "Docker"
if [[ -d ~/Library/Containers/com.docker.docker ]]; then
    docker_size=$(get_dir_size_human ~/Library/Containers/com.docker.docker)
    print_item "Docker Desktop" "$docker_size" "true"
    echo -e "  ${YELLOW}Tip: Run 'docker system prune -a' to clean unused data${NC}"
else
    print_item "Docker" "Not found or not using Docker Desktop"
fi

# Logs
print_section "Log Files"
user_logs=$(get_dir_size_human ~/Library/Logs)
system_logs=$(get_dir_size_human /var/log 2>/dev/null || echo "N/A")
print_item "User Logs (~/Library/Logs)" "$user_logs"
print_item "System Logs (/var/log)" "$system_logs"

# Downloads folder
print_section "Downloads Folder"
downloads_size=$(get_dir_size_human ~/Downloads)
downloads_count=$(ls -1 ~/Downloads 2>/dev/null | wc -l | tr -d ' ')
print_item "Downloads" "$downloads_size ($downloads_count items)"

# Trash
print_section "Trash"
trash_size=$(get_dir_size_human ~/.Trash)
trash_count=$(ls -1 ~/.Trash 2>/dev/null | wc -l | tr -d ' ')
print_item "Trash" "$trash_size ($trash_count items)"
if [[ $trash_count -gt 0 ]]; then
    echo -e "  ${YELLOW}Tip: Empty Trash to reclaim space${NC}"
fi

# Mail Downloads
print_section "Mail"
if [[ -d ~/Library/Mail ]]; then
    mail_size=$(get_dir_size_human ~/Library/Mail)
    mail_downloads=$(get_dir_size_human ~/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads 2>/dev/null || echo "N/A")
    print_item "Mail data" "$mail_size"
    print_item "Mail downloads" "$mail_downloads"
fi

# Large files in home directory
print_section "Largest Items in Home Directory"
echo "  Top 10 largest directories in ~/"
du -sh ~/*/ ~/.*/ 2>/dev/null | sort -hr | head -10 | while read size dir; do
    dirname=$(basename "$dir")
    echo "    $size  $dirname"
done

# Summary and recommendations
print_header "Recommendations"
echo ""
echo -e "  ${BOLD}Quick cleanup commands:${NC}"
echo ""
echo "  # Remove Time Machine snapshots"
echo "  sudo tmutil deletelocalsnapshots /"
echo ""
echo "  # Clean Homebrew cache"
echo "  brew cleanup --prune=all"
echo ""
echo "  # Clean Xcode derived data"
echo "  rm -rf ~/Library/Developer/Xcode/DerivedData/*"
echo ""
echo "  # Clean npm cache"
echo "  npm cache clean --force"
echo ""
echo "  # Clean Docker (if installed)"
echo "  docker system prune -a"
echo ""
echo "  # Empty Trash"
echo "  rm -rf ~/.Trash/*"
echo ""
echo -e "  ${BOLD}For detailed analysis, consider using:${NC}"
echo "  - ncdu (install with: brew install ncdu)"
echo "  - OmniDiskSweeper (free app)"
echo "  - DaisyDisk (paid app)"
echo ""
