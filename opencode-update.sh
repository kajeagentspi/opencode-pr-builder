#!/bin/bash
# Convenience wrapper for OpenCode PR Builder
# Place this in your path or create an alias: alias opencode-update='~/git/opencode-pr-builder/opencode-update.sh'

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SCRIPT="$SCRIPT_DIR/update-opencode-custom.sh"
REPO_DIR="$HOME/git/opencode"

if [ ! -f "$UPDATE_SCRIPT" ]; then
    echo "Error: Update script not found at $UPDATE_SCRIPT"
    exit 1
fi

# Check for in-progress git operations and abort them
if [ -d "$REPO_DIR/.git" ]; then
    cd "$REPO_DIR"

    if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
        echo "Warning: Rebase in progress. Aborting..."
        git rebase --abort 2>/dev/null || true
    fi

    if [ -f ".git/MERGE_HEAD" ]; then
        echo "Warning: Merge in progress. Aborting..."
        git merge --abort 2>/dev/null || true
    fi

    # Reset any conflicted state
    if git ls-files -u | grep -q .; then
        echo "Warning: Resetting conflicted files..."
        git reset --hard HEAD 2>/dev/null || true
    fi
fi

# Run the update script with all arguments
"$UPDATE_SCRIPT" "$@"
