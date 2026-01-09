# OpenCode PR Builder

> Build custom OpenCode versions with any PR - easy, fast, automated

## Why Use This?

**You're lazy to manually patch OpenCode.** This script automates:

- ✅ Testing any PR before it's merged
- ✅ Merging PRs into your custom build
- ✅ Applying custom patches (disable auto-update, allow all permissions)
- ✅ Building and installing the custom binary

No more manual patching, no more complex build commands.

## Quick Start

### Prerequisites

```bash
# Install dependencies
sudo apt-get install git curl jq  # Debian/Ubuntu
brew install git curl jq           # macOS

# Install bun (if not already installed)
curl -fsSL https://bun.sh/install | bash
```

### Installation & Usage

```bash
# Clone
git clone https://github.com/kajeagentspi/opencode-pr-builder.git
cd opencode-pr-builder
chmod +x *.sh

# Check if PR conflicts before building
./update-opencode-custom.sh check-conflicts --pr 5501

# Build custom OpenCode with PR #5501
./update-opencode-custom.sh --pr 5501

# Default PR #5497 (tokens-per-second display)
./update-opencode-custom.sh
```

## Commands

| Command | Description |
|---------|-------------|
| `update` | Full build process (default) |
| `check-conflicts` | Check if PR merges cleanly |
| `check` | Check if PR is merged |
| `patch` | Apply patches only |
| `build` | Build only |
| `install` | Install binary only |

## Options

| Option | Description |
|--------|-------------|
| `--pr <number>` | PR number to build (default: 5497) |
| `--branch <name>` | PR branch name (fallback if API fails) |
| `--owner <username>` | PR owner (fallback if API fails) |
| `--repo-dir <path>` | OpenCode repo path (default: ~/git/opencode) |
| `--install-path <path>` | Binary install path (default: ~/.opencode/bin/opencode) |
| `--token <token>` | GitHub token for API rate limiting |
| `--skip-patches` | Skip applying patches |
| `--no-backup` | Don't backup existing binary |
| `--overwrite` | Delete repo without prompting |

## Examples

```bash
# Check conflicts before building
./update-opencode-custom.sh check-conflicts --pr 5501

# Build with specific PR (auto-detects branch/owner)
./update-opencode-custom.sh --pr 5501

# Build with manual branch/owner (if API fails)
./update-opencode-custom.sh --pr 5501 --branch feat-x --owner user123 --overwrite

# Custom install location
./update-opencode-custom.sh --pr 5501 --install-path ~/bin/opencode

# Build without patches
./update-opencode-custom.sh --pr 5501 --skip-patches

# Use GitHub token (for higher API rate limit)
./update-opencode-custom.sh --pr 5501 --token ghp_xxxxxxxxxxxx
```

## Troubleshooting

### "Text file busy" error when installing

**Problem:** If OpenCode is currently running, the binary cannot be overwritten.

**Solution:** The script now uses `mv` instead of `cp` to atomically replace the binary. If you still see this error:
```bash
# Quit OpenCode first, then install
./update-opencode-custom.sh --pr 5501
```

### "GitHub API rate limit exhausted"

**Problem:** GitHub API allows 60 requests/hour without authentication.

**Solution:** Create a GitHub token for higher rate limit (5000 req/hour):
1. Go to: https://github.com/settings/tokens
2. Create a new token (no special permissions needed)
3. Use: `./update-opencode-custom.sh --pr 5501 --token ghp_xxxxxxxxxxxx`

### "PR not found"

**Problem:** PR number doesn't exist or is private.

**Solution:**
- Verify PR exists at: https://github.com/anomalyco/opencode/pulls
- Check that PR is open (not closed)

### "Merge conflicts detected"

**Problem:** The PR conflicts with current dev branch.

**Solution:**
- Wait for PR author to resolve conflicts
- Or manually resolve conflicts and build

### "Missing dependencies"

**Problem:** Required tools not installed.

**Solution:**
```bash
sudo apt-get install git curl jq  # Debian/Ubuntu
brew install git curl jq           # macOS
curl -fsSL https://bun.sh/install | bash  # bun
```

## How It Works

1. **Fetch PR details** from GitHub API (branch, owner, status)
2. **Check if PR is merged** - exit if true (you don't need this script!)
3. **Manage repository** - clone fresh or use existing
4. **Apply patches** - disable auto-update, allow all permissions
5. **Merge PR** - combine PR branch with dev branch
6. **Build** - compile custom binary with bun
7. **Install** - backup old binary, install new one

## Available Patches

- **disable-auto-update** - Disables automatic update checks
- **allow-all-permissions** - Sets default permissions to "allow all"

Skip patches with: `--skip-patches`

## Documentation

- [Quick Start Guide](docs/QUICK_START.md) - Detailed setup instructions
- [Patches Documentation](docs/PATCHES.md) - Learn about available patches
- [Usage Examples](docs/EXAMPLES.md) - Real-world usage examples

## License

MIT License - see [LICENSE](LICENSE) file.

## Contributing

Contributions welcome! Feel free to open issues or pull requests.

---

**Made with ❤️ by lazy developers who hate manual patching**
