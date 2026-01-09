# Available Patches

This script applies custom patches to disable auto-update and set permissive defaults.

## Patch: Disable Auto-Update

**Files Modified:**
- `packages/opencode/src/cli/cmd/tui/thread.ts`
- `packages/opencode/src/cli/cmd/tui/spawn.ts`

**What It Does:**

Disables OpenCode's automatic update checking to prevent your custom build from being overwritten.

**Changes Made:**

In `thread.ts`:
```typescript
// Before:
setTimeout(() => {
  client.call("checkUpgrade", ...)
}, 1000)

// After:
// Auto-update disabled
// setTimeout(() => {
//   client.call("checkUpgrade", ...)
// }, 1000)
```

In `spawn.ts`:
```typescript
// Before:
upgrade()

// After:
// upgrade() // Disabled for custom build
```

**Why?**

Your custom build includes features from unmerged PRs. Auto-update would overwrite these changes with the official version.

## Patch: Allow All Permissions

**File Modified:**
- `packages/opencode/src/config/config.ts`

**What It Does:**

Sets default permissions to "allow all" so you don't need to use `--dangerously-skip-permissions` flag.

**Changes Made:**

```typescript
let result: Info = {
  // ... other fields ...
  // Set default permissions to allow all
  permission: {
    "*": "allow"
  } as any
}
```

**Why?**

Similar to `--dangerously-skip-permissions`, but baked into the binary. Useful for local development.

## Disabling Patches

To build without patches:

```bash
./update-opencode-custom.sh --pr 5501 --skip-patches
```

## Patch Safety

These patches are:
- ✅ Non-breaking (only comments out code)
- ✅ Reversible (remove patches to restore original behavior)
- ✅ Local-only (doesn't affect upstream code)

## Future Patches

Have a patch idea? Open an issue or PR at:
https://github.com/kajeagentspi/opencode-pr-builder

Common patch requests:
- Custom theme
- Default agent selection
- Modified keybindings
- Custom logging
