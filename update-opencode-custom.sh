#!/bin/bash
# OpenCode PR Builder
# Build custom OpenCode versions with any PR - easy, fast, automated

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

DEFAULT_PR_NUMBER="5497"
DEFAULT_REPO_DIR="$HOME/git/opencode"
DEFAULT_INSTALL_PATH="$HOME/.opencode/bin/opencode"
DEFAULT_LOG_FILE="$HOME/.opencode-pr-builder.log"

# Runtime variables
PR_NUMBER=""
PR_BRANCH=""
PR_OWNER=""
REPO_DIR=""
INSTALL_PATH=""
LOG_FILE=""
GITHUB_TOKEN=""
SKIP_PATCHES=false
BACKUP_BINARY=true
OVERWRITE=false
COMMAND=""
MANUAL_BRANCH=""
MANUAL_OWNER=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global variable for PR data
PR_DATA=""

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
}

print_header() {
    local title="$1"
    echo ""
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}$title${NC}"
    echo -e "${BLUE}=================================${NC}"
    log "START: $title"
}

print_success() {
    local message="$1"
    echo -e "${GREEN}✓ $message${NC}"
    log "SUCCESS: $message"
}

print_error() {
    local message="$1"
    echo -e "${RED}✗ $message${NC}"
    log "ERROR: $message"
}

print_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠ $message${NC}"
    log "WARNING: $message"
}

# ============================================================================
# DEPENDENCY CHECK
# ============================================================================

check_dependencies() {
    local missing=()

    command -v git >/dev/null 2>&1 || missing+=("git")
    command -v curl >/dev/null 2>&1 || missing+=("curl")
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    command -v bun >/dev/null 2>&1 || missing+=("bun")

    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing[*]}"
        echo ""
        echo "Install missing dependencies:"
        echo ""
        for cmd in "${missing[@]}"; do
            case $cmd in
                git)
                    echo "  sudo apt-get install git  # Debian/Ubuntu"
                    echo "  brew install git            # macOS"
                    ;;
                curl)
                    echo "  sudo apt-get install curl  # Debian/Ubuntu"
                    echo "  brew install curl            # macOS"
                    ;;
                jq)
                    echo "  sudo apt-get install jq    # Debian/Ubuntu"
                    echo "  brew install jq              # macOS"
                    ;;
                bun)
                    echo "  curl -fsSL https://bun.sh/install | bash"
                    ;;
            esac
        done
        echo ""
        exit 1
    fi
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

parse_arguments() {
    # Set defaults
    PR_NUMBER="$DEFAULT_PR_NUMBER"
    REPO_DIR="$DEFAULT_REPO_DIR"
    INSTALL_PATH="$DEFAULT_INSTALL_PATH"
    LOG_FILE="$DEFAULT_LOG_FILE"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pr)
                PR_NUMBER="$2"
                shift 2
                ;;
            --branch)
                PR_BRANCH="$2"
                MANUAL_BRANCH="$2"
                shift 2
                ;;
            --owner)
                PR_OWNER="$2"
                MANUAL_OWNER="$2"
                shift 2
                ;;
            --repo-dir)
                REPO_DIR="$2"
                shift 2
                ;;
            --install-path)
                INSTALL_PATH="$2"
                shift 2
                ;;
            --token)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            --skip-patches)
                SKIP_PATCHES=true
                shift
                ;;
            --no-backup)
                BACKUP_BINARY=false
                shift
                ;;
            --overwrite)
                OVERWRITE=true
                shift
                ;;
            update|patch|build|install|check|check-conflicts|help)
                COMMAND="$1"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done

    # Default command
    COMMAND="${COMMAND:-update}"
}

# ============================================================================
# GITHUB API
# ============================================================================

fetch_pr_details() {
    print_warning "Fetching PR #$PR_NUMBER details from GitHub..."

    local api_url="https://api.github.com/repos/anomalyco/opencode/pulls/$PR_NUMBER"
    local auth_header=""

    if [ -n "$GITHUB_TOKEN" ]; then
        auth_header="-H 'Authorization: token $GITHUB_TOKEN'"
    fi

    PR_DATA=$(eval curl -s $auth_header "$api_url")

    # Check for errors
    local message
    message=$(echo "$PR_DATA" | jq -r '.message // empty' 2>/dev/null)

    if [ "$message" = "Not Found" ]; then
        print_error "PR #$PR_NUMBER not found"
        echo ""
        echo "Verify PR exists at: https://github.com/anomalyco/opencode/pulls/$PR_NUMBER"
        exit 1
    fi

    if [ -n "$message" ] && [ "$message" != "null" ]; then
        # Check if rate limited
        if echo "$message" | grep -qi "API rate limit"; then
            print_error "GitHub API rate limit exhausted"
            echo ""
            echo "Solutions:"
            echo "  1. Use --token for higher rate limit (5000 req/hour)"
            echo "     Create token at: https://github.com/settings/tokens"
            echo "  2. Specify --branch and --owner manually"
            exit 1
        fi

        print_error "GitHub API error: $message"
        exit 1
    fi

    # Extract PR details
    PR_BRANCH=$(echo "$PR_DATA" | jq -r '.head.ref')
    PR_OWNER=$(echo "$PR_DATA" | jq -r '.head.user.login')
    local pr_state
    pr_state=$(echo "$PR_DATA" | jq -r '.state')
    local pr_merged
    pr_merged=$(echo "$PR_DATA" | jq -r '.merged')
    local pr_title
    pr_title=$(echo "$PR_DATA" | jq -r '.title')

    # Validate
    if [ "$PR_BRANCH" = "null" ] || [ "$PR_OWNER" = "null" ]; then
        print_error "Failed to parse PR details"
        if [ -n "$MANUAL_BRANCH" ] && [ -n "$MANUAL_OWNER" ]; then
            print_warning "Using manual values: --branch $MANUAL_BRANCH --owner $MANUAL_OWNER"
            PR_BRANCH="$MANUAL_BRANCH"
            PR_OWNER="$MANUAL_OWNER"
        else
            print_error "Specify --branch and --owner manually"
            exit 1
        fi
    fi

    print_success "PR: $pr_title"
    print_success "Branch: $PR_BRANCH, Owner: $PR_OWNER, State: $pr_state"
    log "PR #$PR_NUMBER: branch=$PR_BRANCH, owner=$PR_OWNER, state=$pr_state"
}

# ============================================================================
# PR STATUS CHECK
# ============================================================================

check_pr_status() {
    print_header "Checking PR #$PR_NUMBER Status"

    fetch_pr_details

    # Check if merged
    local pr_merged
    pr_merged=$(echo "$PR_DATA" | jq -r '.merged')

    if [ "$pr_merged" = "true" ]; then
        print_success "PR #$PR_NUMBER is already merged!"
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════${NC}"
        echo -e "${GREEN}PR IS MERGED - You don't need this script!${NC}"
        echo -e "${GREEN}═══════════════════════════════════════${NC}"
        echo ""
        echo "Use the official build instead:"
        echo "  cd $REPO_DIR"
        echo "  git pull origin dev"
        echo "  bun run build"
        exit 0
    fi

    # Check if open
    local pr_state
    pr_state=$(echo "$PR_DATA" | jq -r '.state')

    if [ "$pr_state" != "open" ]; then
        print_error "PR #$PR_NUMBER is not open (state: $pr_state)"
        exit 1
    fi

    print_success "PR #$PR_NUMBER is open and ready to merge"
}

# ============================================================================
# CONFLICT CHECK
# ============================================================================

check_conflicts() {
    print_header "Checking PR #$PR_NUMBER for Merge Conflicts"

    check_pr_status

    if [ ! -d "$REPO_DIR" ]; then
        print_error "Repository not found: $REPO_DIR"
        print_warning "Run 'update' command first to clone the repository"
        exit 1
    fi

    cd "$REPO_DIR"

    # Fetch origin/dev
    print_warning "Fetching origin/dev..."
    git fetch origin dev 2>/dev/null || true

    # Fetch PR branch
    print_warning "Fetching PR branch..."
    local remote_name="pr-$PR_NUMBER"

    if ! git remote | grep -q "^$remote_name$"; then
        git remote add "$remote_name" "https://github.com/$PR_OWNER/opencode.git"
    fi

    if ! git fetch "$remote_name" "$PR_BRANCH" 2>/dev/null; then
        print_error "Failed to fetch PR branch"
        exit 1
    fi

    # Clean up any existing merge
    if [ -f ".git/MERGE_HEAD" ]; then
        git merge --abort 2>/dev/null || true
    fi

    # Simulate merge
    print_warning "Simulating merge..."

    if git merge --no-commit --no-ff origin/dev "$remote_name/$PR_BRANCH" 2>/dev/null; then
        if git ls-files -u | grep -q .; then
            echo ""
            print_error "Merge conflicts detected"
            git merge --abort
            log "Merge conflicts detected for PR #$PR_NUMBER"
            exit 1
        else
            print_success "No merge conflicts - clean merge!"
            git merge --abort
            log "No merge conflicts for PR #$PR_NUMBER"
            exit 0
        fi
    else
        print_error "Merge simulation failed"
        git merge --abort 2>/dev/null || true
        exit 1
    fi
}

# ============================================================================
# REPOSITORY MANAGEMENT
# ============================================================================

manage_repo() {
    print_header "Managing Repository"

    if [ -d "$REPO_DIR" ]; then
        if [ "$OVERWRITE" = true ]; then
            print_warning "Removing existing repository (--overwrite specified)..."
            rm -rf "$REPO_DIR"
            print_success "Repository removed"
            log "Removed existing repository: $REPO_DIR"
        else
            echo ""
            echo -e "${YELLOW}Repository already exists: $REPO_DIR${NC}"
            echo ""
            read -p "Delete and re-clone? [y/N] " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_warning "Removing existing repository..."
                rm -rf "$REPO_DIR"
                print_success "Repository removed"
                log "Removed existing repository: $REPO_DIR"
            else
                print_warning "Keeping existing repository"
                cd "$REPO_DIR"
                return 0
            fi
        fi
    fi

    # Clone fresh
    if [ ! -d "$REPO_DIR" ]; then
        print_warning "Cloning fresh repository..."
        if git clone https://github.com/anomalyco/opencode.git "$REPO_DIR"; then
            print_success "Repository cloned"
            log "Cloned repository to: $REPO_DIR"
        else
            print_error "Failed to clone repository"
            exit 1
        fi
    fi

    cd "$REPO_DIR"

    # Checkout dev
    print_warning "Checking out dev branch..."
    git checkout dev >/dev/null 2>&1
    print_success "Checked out dev branch"
    log "Checked out dev branch"
}

# ============================================================================
# PATCHES
# ============================================================================

apply_patches() {
    if [ "$SKIP_PATCHES" = true ]; then
        print_warning "Skipping patches (--skip-patches specified)"
        return 0
    fi

    print_header "Applying Patches"

    cd "$REPO_DIR"

    # Patch 1: Disable auto-update in thread.ts
    print_warning "Patching thread.ts to disable auto-update..."
    if grep -q "setTimeout(() => {" packages/opencode/src/cli/cmd/tui/thread.ts 2>/dev/null; then
        if ! grep -q "Auto-update disabled" packages/opencode/src/cli/cmd/tui/thread.ts 2>/dev/null; then
            sed -i.bak 's/setTimeout(() => {$/\/\/ Auto-update disabled\n    \/\/ setTimeout(() => {/' packages/opencode/src/cli/cmd/tui/thread.ts
            sed -i '/client.call("checkUpgrade"/i\    \/\/ ' packages/opencode/src/cli/cmd/tui/thread.ts
            sed -i '/client.call("checkUpgrade"/s/^/    \/\/ /' packages/opencode/src/cli/cmd/tui/thread.ts
            sed -i '/}, 1000)/i\    \/\/ ' packages/opencode/src/cli/cmd/tui/thread.ts
            sed -i '/}, 1000)/s/^/    \/\/ /' packages/opencode/src/cli/cmd/tui/thread.ts
            print_success "Disabled auto-update in thread.ts"
            log "Applied patch: disable auto-update in thread.ts"
        else
            print_success "Auto-update already disabled in thread.ts"
        fi
    fi

    # Patch 2: Disable auto-update in spawn.ts
    print_warning "Patching spawn.ts to disable auto-update..."
    if grep -q "upgrade()" packages/opencode/src/cli/cmd/tui/spawn.ts 2>/dev/null; then
        if ! grep -q "Disabled for custom build" packages/opencode/src/cli/cmd/tui/spawn.ts 2>/dev/null; then
            sed -i.bak 's/upgrade()$/\/\/ upgrade() \/\/ Disabled for custom build/' packages/opencode/src/cli/cmd/tui/spawn.ts
            print_success "Disabled auto-update in spawn.ts"
            log "Applied patch: disable auto-update in spawn.ts"
        else
            print_success "Auto-update already disabled in spawn.ts"
        fi
    fi

    # Patch 3: Allow all permissions
    print_warning "Patching config.ts to set default permissions..."
    if ! grep -q "Set default permissions to allow all" packages/opencode/src/config/config.ts 2>/dev/null; then
        # Add default permissions before the OPENCODE_PERMISSION check
        sed -i.bak '/if (Flag.OPENCODE_PERMISSION) {/i\    \/\/ Set default permissions to allow all (custom build)\n    result.permission = result.permission ?? {}\n    result.permission["*"] = "allow"\n    ' packages/opencode/src/config/config.ts
        print_success "Set default permissions to allow all"
        log "Applied patch: allow all permissions"
    else
        print_success "Default permissions already configured"
    fi

    # Cleanup
    find packages/opencode/src -name "*.bak" -delete 2>/dev/null || true
}

# ============================================================================
# MERGE PR
# ============================================================================

merge_pr() {
    print_header "Merging PR #$PR_NUMBER"

    cd "$REPO_DIR"

    # Add remote for PR branch
    local remote_name="pr-$PR_NUMBER"

    if ! git remote | grep -q "^$remote_name$"; then
        print_warning "Adding remote for PR branch..."
        git remote add "$remote_name" "https://github.com/$PR_OWNER/opencode.git"
    fi

    # Fetch PR branch
    print_warning "Fetching PR branch..."
    if ! git fetch "$remote_name" "$PR_BRANCH"; then
        print_error "Failed to fetch PR branch"
        exit 1
    fi

    # Check if already merged
    if git log --oneline | grep -q "Merge PR #$PR_NUMBER"; then
        print_success "PR #$PR_NUMBER already merged locally"
        return 0
    fi

    # Merge the PR
    print_warning "Merging PR #$PR_NUMBER..."
    if git merge "$remote_name/$PR_BRANCH" --no-edit -X theirs; then
        print_success "Successfully merged PR #$PR_NUMBER"
        log "Merged PR #$PR_NUMBER"
    else
        print_error "Failed to merge PR #$PR_NUMBER"
        print_error "There may be merge conflicts"
        exit 1
    fi
}

# ============================================================================
# BUILD
# ============================================================================

build_custom() {
    print_header "Building Custom OpenCode"

    cd "$REPO_DIR"

    print_warning "Installing dependencies..."
    if ! bun install; then
        print_error "Failed to install dependencies"
        exit 1
    fi
    print_success "Dependencies installed"
    log "Installed dependencies"

    cd "$REPO_DIR/packages/opencode"

    print_warning "Running build..."
    if bun run build; then
        print_success "Build completed successfully"
        log "Build completed successfully"
    else
        print_error "Build failed"
        exit 1
    fi
}

# ============================================================================
# INSTALL
# ============================================================================

install_binary() {
    print_header "Installing Custom Binary"

    cd "$REPO_DIR"

    # Detect platform
    local os
    local arch
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)

    case $os in
        linux) os="linux" ;;
        darwin) os="darwin" ;;
        *)
            print_error "Unsupported OS: $os"
            exit 1
            ;;
    esac

    case $arch in
        x86_64|x64) arch="x64" ;;
        aarch64|arm64) arch="arm64" ;;
        *)
            print_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac

    local binary_name="opencode-${os}-${arch}"
    local source_binary="packages/opencode/dist/${binary_name}/bin/opencode"
    local target_binary="$INSTALL_PATH"

    if [ ! -f "$source_binary" ]; then
        print_error "Binary not found: $source_binary"
        print_warning "Run 'build' command first"
        exit 1
    fi

    # Backup existing binary
    if [ -f "$target_binary" ] && [ "$BACKUP_BINARY" = true ]; then
        local backup_name="$target_binary.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Backing up existing binary to: $backup_name"
        cp "$target_binary" "$backup_name"
        log "Backed up binary to: $backup_name"
    fi

    # Install new binary
    print_warning "Installing custom binary..."
    mkdir -p "$(dirname "$target_binary")"

    # Use mv to avoid "text file busy" error when binary is in use
    if mv "$source_binary" "$target_binary"; then
        chmod +x "$target_binary"
        print_success "Binary installed successfully"
        print_success "Location: $target_binary"
        log "Installed binary to: $target_binary"
    else
        print_error "Failed to install binary"
        exit 1
    fi
}

# ============================================================================
# MAIN UPDATE FUNCTION
# ============================================================================

update() {
    print_header "OpenCode PR Builder"
    log "Starting update for PR #$PR_NUMBER"

    # Step 1: Check PR status
    check_pr_status

    # Step 2: Manage repository
    manage_repo

    # Step 3: Apply patches
    apply_patches

    # Step 4: Merge PR
    merge_pr

    # Step 5: Build
    build_custom

    # Step 6: Install
    install_binary

    print_header "Update Complete!"
    print_success "Custom OpenCode with PR #$PR_NUMBER installed!"
    echo ""
    echo "Version: $($INSTALL_PATH --version 2>/dev/null || echo 'Unknown')"
    echo "Location: $INSTALL_PATH"
    echo ""
    echo "Restart OpenCode to use the new version."
}

# ============================================================================
# HELP
# ============================================================================

show_help() {
    cat << EOF
OpenCode PR Builder - Build custom OpenCode with any PR

Usage: $0 [command] [options]

Commands:
  update           Clone/fetch repo, merge PR, patch, build, install (default)
  patch            Apply patches only (to existing repo)
  build            Build custom OpenCode only
  install          Install built binary only
  check            Check if PR is merged
  check-conflicts  Check if PR would conflict with origin/dev
  help             Show this help message

Options:
  --pr <number>          PR number to merge (default: 5497)
  --branch <name>        PR branch name (fallback if API fails)
  --owner <username>     PR owner (fallback if API fails)
  --repo-dir <path>      OpenCode repo path (default: ~/git/opencode)
  --install-path <path>  Binary install path (default: ~/.opencode/bin/opencode)
  --token <token>        GitHub token for API rate limiting
  --skip-patches         Skip applying patches
  --no-backup            Don't backup existing binary
  --overwrite            Delete existing repo without prompting

Examples:
  $0                                    # Default PR #5497
  $0 --pr 5501                          # Different PR
  $0 check-conflicts --pr 5501          # Check conflicts
  $0 --pr 5501 --branch feat-x --owner user --overwrite
  $0 --pr 5501 --install-path ~/bin/opencode

For more information, visit: https://github.com/kajeagentspi/opencode-pr-builder
EOF
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Parse arguments first
parse_arguments "$@"

# Check dependencies
check_dependencies

# Execute command
case "$COMMAND" in
    update)
        update
        ;;
    check)
        check_pr_status
        echo ""
        echo "PR #$PR_NUMBER is not merged yet"
        ;;
    check-conflicts)
        check_conflicts
        ;;
    patch)
        fetch_pr_details
        manage_repo
        apply_patches
        ;;
    build)
        fetch_pr_details
        manage_repo
        build_custom
        ;;
    install)
        install_binary
        ;;
    help)
        show_help
        ;;
esac
