# zdotfiles

This repo holds the configuration for zsh, Ghostty, SSH, Starship, tmux, git, Neovim, Homebrew, and the coding agents.

Each tool has two types of files:

- A **fixed file** is the same on each computer. Git tracks it. The installer links it into your home folder.
- A **manual file** is for one computer. It is in the repo folder, but git ignores it. The installer copies its example one time, and links the home path to it. Put hosts, secrets, and local changes in a manual file.

## Install

From the repo root, run these scripts:

1. `./scripts/install-dotfiles.sh` links the dotfiles, and makes and links the manual files.
2. `./scripts/install-brew.sh` installs the Homebrew packages. It asks y/n for each cask that is not installed. It does not upgrade installed packages. To install only some groups, name them, such as `./scripts/install-brew.sh shell tools`.
3. Install the Claude Code CLI with `curl -fsSL https://claude.ai/install.sh | bash`. The `claude` cask installs only the desktop app.
4. `./agents/install-agents.sh` links the agent rules and skills. See [the agents README](agents/README.md).

The scripts do not replace a path that exists. If a script prints `skip`, move that path, and then run the script again.

To make an SSH key, run `ssh-keygen -t ed25519 -C "EMAIL"`. Replace `EMAIL` with your email address.

## Layout

| Tool | Fixed file | Manual file in the repo | Home path |
|------|------------|-------------------------|-----------|
| zsh | `config/zsh/.zshenv`, `.zprofile`, `.zshrc`, `config/zsh/modules/`, `config/zsh/paths/paths.zsh` | `config/zsh/zshenv.local` (settings), `config/zsh/zshrc.local` (aliases), `config/zsh/paths/local.zsh` (PATH) | `~/.zshenv.local`, `~/.zshrc.local`, — |
| Ghostty | `config/ghostty/config` | `config/ghostty/local` | `~/.config/ghostty/local` |
| SSH | `config/ssh/config` | `config/ssh/config.local` (hosts) | `~/.ssh/config.local` |
| zsh companies | `config/zsh/companies/_template/` | `config/zsh/companies/COMPANY/` (exports and aliases) | — |
| Starship | `config/starship/starship.toml` | — | — |
| tmux | `config/tmux/tmux.conf` | `config/tmux/local.conf` | `~/.config/tmux/local.conf` |
| git | `config/git/config`, `config/git/ignore` | `config/git/gitconfig.local` (name, email, signing key) | `~/.gitconfig` |
| Neovim | `config/nvim/` | — | — |
| Homebrew | `brew/shell.Brewfile`, `tools.Brewfile`, `languages.Brewfile`, `apps.Brewfile` | `brew/Brewfile.local` | `~/.config/brew/Brewfile.local` |

SSH keys and the login files of apps, such as `gh`, Docker, Codex, and Pi, stay in their usual folders. Do not put them in the repo, because each tool that reads the repo folder can then read them. For the same reason, the zsh secrets are in `~/.config/zsh/private/`.

Each tool reads its manual file after its fixed file, so the manual file can override it. SSH is different: it uses the first value that it finds, so `config/ssh/config` reads `config/ssh/config.local` first.

`git config --global` writes to `config/git/gitconfig.local` through the `~/.gitconfig` link. Git ignores that file. `config/git/ignore` holds only the patterns for the OS, the editors, and secrets. Put the patterns for a language in the `.gitignore` of each repo.

## Terminal backgrounds

`ascii-art/terminal-bg/` holds animated backgrounds for Ghostty and cmux. Each background is a GLSL shader that draws only on background pixels, so the terminal text stays clear. The `termbg` command, or its short name `tbg`, switches the background:

| Command | Effect |
|---------|--------|
| `tbg` | Shows the mode now, the backgrounds, and the overlays. |
| `tbg next` | Moves to the next mode, in alphabetical order. |
| `tbg weather` | Shows the weather now: clear, rain, or snow. The zsh module updates it each hour. |
| `tbg NAME` | Shows one background, such as `stars` or `sovereign`. |
| `tbg off` | Shows no background. |
| `tbg overlay dog-leaf` | Turns the overlay of a dog under a leaf on or off. |

To turn on the backgrounds on a new computer:

1. Run `tbg stars` one time. It writes the shader to `~/.local/state/ghostty/termbg.glsl`.
2. Remove the `#` from the `custom-shader` line in `config/ghostty/local`.
3. Press Cmd+Shift+, in Ghostty to reload. `termbg` reloads cmux by itself.

Weather mode uses the free [Open-Meteo API](https://open-meteo.com/), which needs no key. To set the place, export `WEATHER_LAT`, `WEATHER_LON`, and `WEATHER_NAME` in `config/zsh/zshenv.local`, for example `export WEATHER_NAME="Oakland"`. The default place is San Francisco.

| Path | Content |
|------|---------|
| `termbg.sh` | The switch. It builds the shader for a mode and reloads cmux. |
| `common.glsl` | The helpers that each shader uses. `termbg.sh` adds this file to the start of each shader. |
| `text.glsl` | The text in the top-right corner. A design names its text in a `// @TEXT:` line. |
| `backgrounds/` | The fixed backgrounds. A new `.glsl` file here becomes a mode. |
| `weather/` | `weather.sh` and the rain, snow, and stars shaders of weather mode. |
| `overlays/` | Art that shows over each mode. |

## Settings for one computer

Set these values in `~/.zshenv.local`:

| Setting | Default |
|---------|---------|
| `zdot_brew_kegs` | `(node@22 postgresql@15 rustup)`, the keg-only formulas to add to PATH |
| `zdot_zsh_modules` | `(history keybinds completions aliases fzf termbg)` |
| `zdot_history_days` | `120`, the age in days at which zsh deletes a history entry |
| `zdot_company` | Not set. The company of this laptop. See [Company files](#company-files). |

## Company files

Each company has its own exports, aliases, and secrets. Set `zdot_company` in `config/zsh/zshenv.local` to select the company of this laptop.

1. Run `cp -R config/zsh/companies/_template config/zsh/companies/COMPANY`. Replace `COMPANY` with the folder name.
2. Put the exports in `config/zsh/companies/COMPANY/env.zsh`, and the aliases for repos and jobs in `aliases.zsh`.
3. To add secrets, copy `config/zsh/local/company.secrets.example` to `~/.config/zsh/private/COMPANY.secrets.zsh` with mode 600.
4. Add `zdot_company=COMPANY` to `config/zsh/zshenv.local`.

`.zshenv` loads the company secrets and `env.zsh` in each shell, also scripts. `.zshrc` loads `aliases.zsh` in each interactive shell. Git ignores each company folder, except `_template`.

## Rules for changes

- Put a change for each computer in a fixed file. Put a change for one computer in a manual file.
- Do not put a secret, a private host, or a company package in a fixed file.
- Put private repo patterns in `.git/info/exclude`. Git reads that file, but it is not part of a clone.
- Run `./scripts/check.sh` before you commit. It runs the linters, the installers with a temporary home folder, and the skill validator.
- Write comments and docs in ASD-STE100 Simplified Technical English. See `AGENTS.md`.
