# Usage Examples

Collection of real-world usage examples for OpenCode PR Builder.

## Basic Examples

### Example 1: Default PR (#5497)

```bash
./update-opencode-custom.sh
```

Builds custom OpenCode with PR #5497 (tokens-per-second display).

### Example 2: Specific PR

```bash
./update-opencode-custom.sh --pr 5501
```

Builds custom OpenCode with PR #5501. Auto-detects branch and owner from GitHub API.

### Example 3: Check PR Status

```bash
./update-opencode-custom.sh check --pr 5501
```

Checks if PR #5501 is merged. Exits with status 0 if merged, 1 if not.

### Example 4: Check for Conflicts

```bash
./update-opencode-custom.sh check-conflicts --pr 5501
```

Simulates merge to check for conflicts. Returns exit code 1 if conflicts detected.

## Advanced Examples

### Example 5: Build with Manual Branch/Owner

```bash
./update-opencode-custom.sh --pr 5501 --branch feat-tokens --owner user123 --overwrite
```

Useful when GitHub API is rate-limited or unavailable.

### Example 6: Custom Install Location

```bash
./update-opencode-custom.sh --pr 5501 --install-path ~/bin/opencode
```

Installs binary to custom location instead of `~/.opencode/bin/opencode`.

### Example 7: Build Without Patches

```bash
./update-opencode-custom.sh --pr 5501 --skip-patches
```

Skips auto-update and permission patches.

### Example 8: Use GitHub Token

```bash
./update-opencode-custom.sh --pr 5501 --token ghp_xxxxxxxxxxxxxxxxxxxx
```

Uses GitHub token for higher API rate limit (5000 req/hour vs 60).

### Example 9: Automate Without Prompts

```bash
./update-opencode-custom.sh --pr 5501 --overwrite
```

Automatically deletes existing repo without prompting.

### Example 10: Custom Repo Location

```bash
./update-opencode-custom.sh --pr 5501 --repo-dir ~/projects/opencode
```

Uses custom repository location instead of `~/git/opencode`.

## Workflow Examples

### Workflow 1: Test Multiple PRs

```bash
#!/bin/bash
# test-prs.sh

PRs=(5497 5501 5510 5520)

for pr in "${PRs[@]}"; do
    echo "Testing PR #$pr..."

    # Check conflicts
    if ./update-opencode-custom.sh check-conflicts --pr "$pr"; then
        echo "✓ PR #$pr: No conflicts"

        # Build
        ./update-opencode-custom.sh --pr "$pr" --overwrite
    else
        echo "✗ PR #$pr: Conflicts detected"
    fi
done
```

### Workflow 2: Nightly Updates

```bash
#!/bin/bash
# nightly-update.sh

# Check if PR is merged
if ./update-opencode-custom.sh check --pr 5497; then
    echo "PR is merged! Switching to official build..."
    cd ~/git/opencode
    git pull origin dev
    bun run build
else
    echo "Building custom version..."
    ./update-opencode-custom.sh --pr 5497 --overwrite
fi
```

### Workflow 3: A/B Testing Builds

```bash
#!/bin/bash
# test-builds.sh

# Build with PR
./update-opencode-custom.sh --pr 5501 --install-path ~/.opencode/bin/opencode-pr

# Test the PR build
~/.opencode/bin/opencode-pr --version

# If issues, restore original
cp ~/.opencode/bin/opencode.backup.* ~/.opencode/bin/opencode
```

## Troubleshooting Examples

### Example 11: Debug Mode

```bash
# Check log file
cat ~/.opencode-pr-builder.log | tail -50
```

### Example 12: Restore Backup

```bash
# List backups
ls -lh ~/.opencode/bin/opencode.backup.*

# Restore specific backup
cp ~/.opencode/bin/opencode.backup.20260109_120000 ~/.opencode/bin/opencode
```

### Example 13: Manual Build (If Script Fails)

```bash
cd ~/git/opencode

# Checkout dev
git checkout dev

# Add PR remote
git remote add pr-5501 https://github.com/user123/opencode.git
git fetch pr-5501 feat-branch

# Merge PR
git merge pr-5501/feat-branch --no-edit -X theirs

# Apply patches manually
# (edit files as needed)

# Build
bun install
cd packages/opencode
bun run build

# Install
cp dist/opencode-linux-x64/bin/opencode ~/.opencode/bin/opencode
chmod +x ~/.opencode/bin/opencode
```

## Tips and Tricks

### Tip 1: Batch Operations

```bash
# Check multiple PRs at once
for pr in 5497 5501 5510; do
    ./update-opencode-custom.sh check --pr "$pr" && echo "PR $pr: merged" || echo "PR $pr: not merged"
done
```

### Tip 2: Parallel Builds

```bash
# Build different PRs in parallel (different install paths)
./update-opencode-custom.sh --pr 5501 --install-path ~/bin/opencode-5501 &
./update-opencode-custom.sh --pr 5510 --install-path ~/bin/opencode-5510 &
wait
```

### Tip 3: Cleanup Old Builds

```bash
# Keep only latest 3 backups
ls -t ~/.opencode/bin/opencode.backup.* | tail -n +4 | xargs rm -f
```

## Real-World Scenarios

### Scenario 1: Testing a Feature PR

You want to test PR #5501 which adds a new feature:

```bash
# 1. Check if it conflicts
./update-opencode-custom.sh check-conflicts --pr 5501

# 2. Build with it
./update-opencode-custom.sh --pr 5501 --overwrite

# 3. Test the build
~/.opencode/bin/opencode

# 4. If you like it, keep it
# If not, restore backup:
cp ~/.opencode/bin/opencode.backup.* ~/.opencode/bin/opencode
```

### Scenario 2: Waiting for PR to Merge

You're tracking PR #5497 and want to know when it's merged:

```bash
# Add to crontab: check every hour
0 * * * * ~/git/opencode-pr-builder/update-opencode-custom.sh check --pr 5497 || ~/git/opencode-pr-builder/update-opencode-custom.sh --pr 5497
```

### Scenario 3: Custom Patches for Development

You want to modify OpenCode for your workflow:

```bash
# Build without auto-update disable
./update-opencode-custom.sh --pr 5501 --skip-patches

# Apply your own patches
vim ~/.opencode/bin/opencode-source/packages/opencode/src/your-file.ts

# Rebuild
cd ~/.opencode/bin/opencode-source
bun run build
```

## Need More Examples?

Open an issue at: https://github.com/kajeagentspi/opencode-pr-builder/issues
