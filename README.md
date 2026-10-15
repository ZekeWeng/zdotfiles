# zdotfiles

The configuration for zsh, Ghostty, SSH, Starship, tmux, git, Neovim, Homebrew, and the coding agents.

## Install

From the repo root, run these commands:

1. `./scripts/install-dotfiles.sh`
2. `./scripts/install-brew.sh`
3. `curl -fsSL https://claude.ai/install.sh | bash`
4. `./agents/install-agents.sh`

If a script prints `skip`, move that path. Then run the script again.

## Local changes

Git ignores the `.local` files and the `local` files in `config/`. Put the hosts, the keys, and the changes for one computer in these files. Put the secrets in `~/.config/zsh/private/secrets.zsh`.

Set these values in `~/.zshenv.local`:

| Setting | Default |
|---------|---------|
| `zdot_brew_kegs` | `(node@22 postgresql@15 rustup)` |
| `zdot_zsh_modules` | `(history keybinds completions aliases fzf termbg)` |
| `zdot_history_days` | `120` |
| `zdot_company` | Not set. Use a folder name from `config/zsh/companies/`. |

To add a company, copy `config/zsh/companies/_template` to `config/zsh/companies/COMPANY`. Replace `COMPANY` with the name.

## Commands

| Command | Effect |
|---------|--------|
| `reload` | Starts the shell again with the new config. |
| `ssh HOST` | In cmux, opens a persistent SSH workspace. |
| `sshkill HOST` | Ends the cmux SSH workspaces for `HOST`. Without `HOST`, it ends each one. |
| `tbg` | Shows the terminal background now and the other backgrounds. |
| `tbg next` | Shows the next background. |
| `tbg weather` | Shows the weather now. It updates each hour. |
| `tbg NAME` | Shows one background, such as `stars`. |
| `tbg off` | Shows no background. |
| `tbg overlay dog-leaf` | Turns the dog overlay on or off. |

To see the backgrounds in Ghostty:

1. Run `tbg stars`.
2. Remove the `#` from the `custom-shader` line in `config/ghostty/local`.
3. Press Cmd+Shift+, in Ghostty.

## Check

Run `./scripts/check.sh` before you commit.
