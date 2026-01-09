# Quick Start Guide

## Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/kajeagentspi/opencode-pr-builder.git
cd opencode-pr-builder
chmod +x *.sh
```

### Step 2: Install Dependencies

**Debian/Ubuntu:**
```bash
sudo apt-get update
sudo apt-get install -y git curl jq
curl -fsSL https://bun.sh/install | bash
```

**macOS:**
```bash
brew install git curl jq
curl -fsSL https://bun.sh/install | bash
```

### Step 3: Verify Installation

```bash
./update-opencode-custom.sh help
```

You should see the help message.

## First-Time Usage

### Check Before Building

Before building, check if the PR has merge conflicts:

```bash
./update-opencode-custom.sh check-conflicts --pr 5497
```

Expected output:
```
=================================
Checking PR #5497 for Merge Conflicts
=================================
⚠ Fetching PR #5497 details from GitHub...
✓ PR: Add tokens per second display
✓ No merge conflicts - clean merge!
```

### Build Your First Custom OpenCode

```bash
./update-opencode-custom.sh --pr 5497
```

This will:
1. Check if PR is merged (exit if true)
2. Clone fresh OpenCode repository
3. Apply custom patches
4. Merge PR #5497
5. Build the binary
6. Install to `~/.opencode/bin/opencode`

### Test Your Custom Build

```bash
~/.opencode/bin/opencode --version
```

## Common Workflows

### Workflow 1: Test a New PR

```bash
# 1. Check if PR exists and is open
./update-opencode-custom.sh check --pr 5501

# 2. Check for merge conflicts
./update-opencode-custom.sh check-conflicts --pr 5501

# 3. Build custom version
./update-opencode-custom.sh --pr 5501
```

### Workflow 2: Build Without Patches

```bash
./update-opencode-custom.sh --pr 5501 --skip-patches
```

### Workflow 3: Custom Install Location

```bash
./update-opencode-custom.sh --pr 5501 --install-path ~/bin/opencode
```

### Workflow 4: Use GitHub Token

```bash
# Create token at: https://github.com/settings/tokens
./update-opencode-custom.sh --pr 5501 --token ghp_xxxxxxxxxxxx
```

### Workflow 5: API Fallback (Manual Branch/Owner)

If GitHub API fails, specify branch and owner manually:

```bash
./update-opencode-custom.sh --pr 5501 --branch feat-tokens --owner user123 --overwrite
```

## Tips

### Tip 1: Create an Alias

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
alias opencode-update='~/git/opencode-pr-builder/update-opencode-custom.sh'
alias opencode-check='~/git/opencode-pr-builder/update-opencode-custom.sh check-conflicts'
```

Then use:
```bash
opencode-check --pr 5501
opencode-update --pr 5501
```

### Tip 2: Check PR Status First

Always run `check` or `check-conflicts` before building:

```bash
# This saves time if PR is already merged
./update-opencode-custom.sh check --pr 5501
```

### Tip 3: Use --overwrite for Automation

In scripts or CI/CD, use `--overwrite` to avoid prompts:

```bash
./update-opencode-custom.sh --pr 5501 --overwrite
```

### Tip 4: Keep Binary Backups

The script automatically backs up your old binary. To restore:

```bash
cp ~/.opencode/bin/opencode.backup.20260109_120000 ~/.opencode/bin/opencode
```

## Next Steps

- Read [PATCHES.md](PATCHES.md) to learn about available patches
- See [EXAMPLES.md](EXAMPLES.md) for more usage examples
- Visit the GitHub repo for updates: https://github.com/kajeagentspi/opencode-pr-builder
