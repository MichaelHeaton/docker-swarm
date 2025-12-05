# Linter Warnings Explained

## Storage Role - apt-get Commands

The linter flags 4 instances of `apt-get` commands in `ansible/roles/storage/tasks/main.yml`. These are **intentional and necessary**:

### Why We Use `apt-get` Commands

1. **`apt-get clean`** (Lines 13, 85)

   - The `ansible.builtin.apt` module doesn't have a "clean" action
   - We need to clear corrupted apt cache files
   - **No alternative**: Must use `apt-get clean` command

2. **`apt-get update`** (Lines 27, 92)
   - We need to capture the return code to detect broken repositories
   - The `ansible.builtin.apt` module's `update_cache` doesn't provide the same level of error detection
   - We use the return code to conditionally fix repositories
   - **Alternative exists but less reliable**: Could use apt module but would lose error detection

### Why These Warnings Are Acceptable

- **Functionality requirement**: The apt module doesn't support all apt-get operations
- **Error detection**: We need return codes for conditional logic
- **Documented**: Each command has comments explaining why it's necessary

### If You Want to Suppress

These warnings can be suppressed by adding to `.ansible-lint` config:

```yaml
skip_list:
  - command-instead-of-module
```

However, it's better to keep the warnings visible so future developers understand why commands are used.
