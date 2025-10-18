# sec

> **Disclaimer:** This is LLM generated trash, and users should send bug reports to Anthropic's complaints department.

A command-line tool for managing gopass credentials with copying, generation, and practice workflows.

## Getting Started

1. Ensure you have `gopass`, `fzf`, `pwgen`, `xclip`, and `xkcdpass` installed on your system
2. Build the binary: `make build`
3. Place the `sec` binary in your PATH
4. (Optional) Install shell aliases: `sec install zsh`
5. (Optional) Install Neovim integration: `sec install nvim`
6. Start using: `sec copy` or `sc` (if using aliases)

## Commands

| Command   | Alias | Description                                                                      |
| --------- | ----- | -------------------------------------------------------------------------------- |
| add       | sa    | Create a new credentials entry and open it in your editor                       |
| copy      | sc    | Copy credentials to clipboard (default: user_id, password, totp in sequence)    |
| edit      | se    | Edit an existing credentials entry                                               |
| gen       | sg    | Generate username, password, or complete entry with random credentials          |
| install   | si    | Install configurations (nvim for Neovim, zsh for shell aliases)                 |
| practice  | sp    | Practice memorizing a password through repeated entry                           |
| show      | ss    | Display credentials entry details                                                |

### Command Details

- **copy**: Use `-f` or `--fields` to specify custom fields (e.g., `sec copy -f email,password`)
- **gen**: Supports `username`, `password`, or `entry` types. Use `--words` for passphrase generation
- **All commands**: Use `fzf` for interactive selection if path is not provided

## Neovim Integration

The Neovim integration provides secure credential generation within your editor when editing gopass entries.

### Privacy Modifications

When editing gopass temporary files (located in `/dev/shm/gopass*`), the following security measures are automatically applied:

- Swap files disabled
- Backup files disabled
- Undo files disabled
- Shada (shared data) disabled

This ensures sensitive password data is never written to disk.

### Keymaps

| Keymap          | Mode          | Action                              |
| --------------- | ------------- | ----------------------------------- |
| `<leader>su`    | Normal        | Generate and insert username        |
| `<leader>sp`    | Normal        | Generate and insert password        |
| `<leader>sw`    | Normal        | Generate and insert passphrase      |
| `<M-u>`         | Normal/Insert | Generate and insert username        |
| `<M-p>`         | Normal/Insert | Generate and insert password        |
| `<M-w>`         | Normal/Insert | Generate and insert passphrase      |

All keymaps delete from cursor to end of line before inserting the generated credential.
