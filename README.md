# zdotfiles

The configuration for zsh, Ghostty, SSH, Starship, tmux, git, Neovim, Homebrew, and the coding agents.

## Install

From the repo root, run these commands:

1. `./scripts/install-dotfiles.sh`
2. `./scripts/install-brew.sh`
3. `curl -fsSL https://claude.ai/install.sh | bash`
4. `./agents/install-agents.sh`

If a script prints `skip`, move that path. Then run the script again.

### Linux

The dotfiles also work on Linux, such as a dev VM. These items are different from macOS:

- **Homebrew:** install [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) first. `install-brew.sh` skips each cask, because casks are macOS apps. Install zsh with `brew install zsh` before `install-dotfiles.sh`.
- **Login shell:** change the login shell to zsh with `chsh -s "$(command -v zsh)"`. An OS Login account on a Google Cloud VM cannot use `chsh`. For that account, put this block at the top of `~/.bashrc`, after the check for an interactive shell:

  ```sh
  # Start zsh in a terminal. Do not start it for "bash -c CMD", because editors use that form to read the environment.
  # Run "ZDOT_BASH=1 bash" to get bash.
  if [ -z "${ZDOT_BASH:-}" ] && [ -z "${BASH_EXECUTION_STRING:-}" ] && [ -t 0 ] && [ -t 1 ] &&
      [ -x /home/linuxbrew/.linuxbrew/bin/zsh ]; then
      export SHELL=/home/linuxbrew/.linuxbrew/bin/zsh
      exec "$SHELL" -l
  fi
  ```

- **Secrets:** Linux has no Keychain, so `secret-set` and `with-secret` stop with a message. Put each token in `~/.config/zsh/private/secrets.zsh`, or in `~/.config/zsh/private/COMPANY.secrets.zsh`. Give each file mode 600.
- **Locale:** `.zshenv` sets `LANG` to `en_US.UTF-8` if the computer has that locale. If not, it sets `C.UTF-8`.
- **Ghostty:** the Ghostty config and the `termbg` module are only for the computer that runs Ghostty. Remove `termbg` from `zdot_zsh_modules` on a remote computer.

## Local changes

Git ignores the `.local` files and the `local` files in `config/`. Put the hosts, the keys, and the changes for one computer in these files. Put each token in the Keychain with `secret-set NAME`. Do not put tokens in a file.

Set these values in `~/.zshenv.local`:

| Setting | Default |
|---------|---------|
| `zdot_brew_kegs` | `(node@22 postgresql@15 rustup)` |
| `zdot_zsh_modules` | `(history keybinds completions aliases fzf termbg)` |
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
