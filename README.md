# zdotfiles

The configuration for zsh, Ghostty, SSH, Starship, tmux, git, Neovim, Homebrew, and the coding agents.

## Layout

| Path | Contents |
|------|----------|
| `scripts/` | `install.sh` and the steps that it runs, `check.sh`, and `test.sh` |
| `config/zsh/` | `.zshenv`, `.zprofile`, `.zshrc`, the `modules/`, the `paths/`, and the `companies/` |
| `config/ssh/`, `config/git/`, `config/tmux/`, `config/nvim/`, `config/starship/` | The config for each tool |
| `config/ghostty/`, `ascii-art/terminal-bg/` | The Ghostty config and the `tbg` backgrounds. These are only for macOS. |
| `brew/` | The Homebrew groups: `shell`, `tools`, `languages`, and `apps` |
| `agents/` | The skills, the company rules, and `install-agents.sh`. The root `AGENTS.md` has the rules. |

## Install

You use the same command on macOS and on Linux. The script finds the OS, and it does the steps for that OS.

1. Install [Homebrew](https://brew.sh). On Linux, read [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) first.
2. Clone this repo. Open a terminal in the repo root.
3. Run `./scripts/install.sh`.
4. Optional: install Claude Code with `curl -fsSL https://claude.ai/install.sh | bash`. Then run `./agents/install-agents.sh` again.
5. Open a new terminal.

`install.sh` runs these steps in this order. You can also run each step alone:

1. `./scripts/install-dotfiles.sh` links the config files into your home folder.
2. `./scripts/install-brew.sh` installs the Homebrew packages.
3. The script changes the login shell to zsh.
4. `./agents/install-agents.sh` links the rules and the skills into the coding agents.

You can run `install.sh` again. If a step prints `skip` for a path that exists, move that path. Then run the script again.

### macOS and Linux

Linux means a computer that you use over SSH, such as a dev VM. Ghostty runs on your Mac.

| Item | macOS | Linux |
|------|-------|-------|
| Homebrew folder | `/opt/homebrew` | `/home/linuxbrew/.linuxbrew` |
| Homebrew casks (the apps) | You select each cask (y/n). | The script skips all casks. |
| Login shell | `/bin/zsh`. The script runs `chsh` only if the login shell is a different shell. | The zsh from Homebrew. If `chsh` cannot change the shell, the script adds a block to `~/.bashrc`. |
| Secrets | In the Keychain, with `secret-set NAME` | In `~/.config/zsh/private/secrets.zsh`, with mode 600 |
| Ghostty config and `tbg` | Installed | Not installed. The default list of zsh modules has no `termbg`. |
| Copy in tmux and fzf | `pbcopy` | OSC 52. The text goes to the clipboard of your Mac through SSH. Ghostty asks first. |
| Locale | `en_US.UTF-8` | `en_US.UTF-8` if the computer has it. If not, `C.UTF-8`. |

On Linux, `chsh` accepts only a shell in `/etc/shells`, and Homebrew does not add its zsh to that file. An OS Login account on a Google Cloud VM cannot use `chsh`. For these cases, the `~/.bashrc` block starts zsh in each interactive terminal. It does not start zsh for `bash -c CMD`, because editors use that form to read the environment. To get bash, run `ZDOT_BASH=1 bash`.

On Linux, `secret-set` and `with-secret` stop with a message, because Linux has no Keychain. Put each token in `~/.config/zsh/private/secrets.zsh`, or in `~/.config/zsh/private/COMPANY.secrets.zsh`.

## Local changes

Git ignores the `.local` files and the `local` files in `config/`. Put the hosts, the keys, and the changes for one computer in these files. Put each token in the Keychain with `secret-set NAME`. Do not put tokens in a file.

Set these values in `~/.zshenv.local`:

| Setting | Default |
|---------|---------|
| `zdot_brew_kegs` | `(node@22 postgresql@15 rustup)` |
| `zdot_zsh_modules` | `(history keybinds completions aliases fzf termbg)`. Linux removes `termbg` from the default. |
| `zdot_history_days` | `120` |
| `zdot_ssh_tmux` | `1`. An SSH login attaches to the tmux session `main`. A `csh` workspace and a Cursor, VS Code, or North Code terminal do not. Set `0` to stop this. |
| `zdot_company` | Not set. Use a folder name from `config/zsh/companies/`. |

To add a company, copy `config/zsh/companies/_template` to `config/zsh/companies/COMPANY`. Replace `COMPANY` with the name.

## Commands

| Command | Effect |
|---------|--------|
| `reload` | Starts the shell again with the new config. |
| `secret-set NAME` | Puts a token in the Keychain. Each read asks for the login password. Click Allow, not Always Allow. |
| `with-secret NAME CMD` | Runs `CMD` with the token in the variable `NAME`. |
| `csh HOST` | Opens a cmux SSH workspace. Each split, such as Cmd+D, is a new shell on `HOST`. The shells continue after a disconnect. |
| `tsh HOST` | Shows the tmux sessions of `HOST` as cmux workspaces. Each split is a tmux pane. Turn on the "Remote tmux" beta setting first. |
| `sshkill HOST` | Ends the cmux SSH workspaces for `HOST`. Without `HOST`, it ends each one. |
| `tbg` | Shows the terminal background now and the other backgrounds. |
| `tbg next` | Shows the next background. |
| `tbg weather` | Shows the weather now. It updates each hour. |
| `tbg NAME` | Shows one background, such as `stars`. |
| `tbg off` | Shows no background. |
| `tbg overlay dog-leaf` | Turns the dog overlay on or off. |
| `tbg light` | Shows a bone background and black text. The stars use darker colors. |
| `tbg dark` | Shows the terminal colors from the Ghostty config again. |

To see the backgrounds in Ghostty:

1. Run `tbg stars`.
2. Remove the `#` from the `custom-shader` line in `config/ghostty/local`.
3. Press Cmd+Shift+, in Ghostty.

`tbg light` and `tbg dark` need the `config-file` line for `termbg.colors` in `config/ghostty/local`. `config/ghostty/local.example` has it. Ghostty also needs Cmd+Shift+, after each change. cmux reloads with no action.

## Check

Run `./scripts/check.sh` before you commit.
