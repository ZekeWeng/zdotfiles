# Set up tokens and secrets

This guide tells you how to put tokens and other secrets on a computer that uses zdotfiles. A company can have its own list in `config/zsh/companies/COMPANY/SECRETS.md`. Git does not track that folder.

## How secrets work

No shell exports a token. Each shell loads the files in `~/.config/zsh/private/`, also the shells of agents. Thus, an agent can read each token that a shell exports.

| Command | Effect |
|---------|--------|
| `secret-set NAME` | Asks for the token. It puts the token in the Keychain on macOS, or in `~/.config/zsh/private/age/NAME.age` on Linux. |
| `secret NAME` | Prints the token. Each read asks for your password or the `age` passphrase. |
| `secret-rm NAME` | Deletes the token. |
| `with-secret NAME CMD` | Runs `CMD` with the token in the variable `NAME`. Only that command gets the token. |

On macOS, click **Allow** when the Keychain asks. Do not click **Always Allow**, because then each process can read the token with no password.

For a tool that you use often, add a function to `config/zsh/companies/COMPANY/aliases.zsh`:

```sh
hf() { with-secret HF_TOKEN command hf "$@"; }
```

## Each computer needs its own setup

The secrets do not go to a new computer with the repo. The Keychain items, the `age` files, the SSH keys, and the CLI logins stay on the computer where you made them. Do the steps in this guide on each new Mac and on each dev VM.

## Set up a new computer

1. Run `./scripts/install.sh`. It installs the dotfiles, the packages, and the agent rules. It also makes `~/.config/zsh/private/secrets.zsh` with mode 600.
2. If you work for a company, set `zdot_company=COMPANY` in `~/.zshenv.local`.
3. If you work for a company, copy `config/zsh/local/company.secrets.example` to `~/.config/zsh/private/COMPANY.secrets.zsh`. Set the mode to 600 with `chmod 600`.
4. Make a new SSH key with `ssh-keygen -t ed25519`. Do not copy a key from a different computer.
5. Do the steps in [General secrets](#general-secrets).
6. Do the steps in the company list, if there is one.
7. Open a new terminal.
8. Do the checks in [Check the setup](#check-the-setup).

## General secrets

| Secret | How to get it | Where it is stored | Check |
|--------|---------------|--------------------|-------|
| SSH key | `ssh-keygen -t ed25519`. Add the public key to GitHub. | `~/.ssh/id_ed25519` | `ssh -T git@github.com` |
| GitHub CLI | `gh auth login`. Select the web browser. | The Keychain, through `gh` | `gh auth status` shows `(keyring)` |
| Git over HTTPS | `gh auth setup-git`. Git then gets the token from `gh`. | No extra file | `git ls-remote` on a private repo |
| `GITHUB_TOKEN` | Only for a tool that reads the variable. Make a token with a short expiry in the GitHub settings. Run `secret-set GITHUB_TOKEN`. | The Keychain or `age` | `with-secret GITHUB_TOKEN gh api user -q .login` |
| `HF_TOKEN` | Make a token in the Hugging Face settings. Run `secret-set HF_TOKEN`. | The Keychain or `age` | `with-secret HF_TOKEN hf auth whoami` |
| MCP servers in agents | Sign in with the browser when the agent asks. | The settings folder of the agent | The agent lists the tools of the server. |
| `LINEAR_API_KEY`, `NOTION_TOKEN`, `SLACK_BOT_TOKEN` | Only if the skills cannot use an MCP server. Run `secret-set NAME` for each one. | The Keychain or `age` | `secret NAME` asks for the password |

Prefer the login of a CLI or a browser sign-in to a long-lived token. A CLI login is easy to revoke, and an agent cannot see it in the environment.

## Refresh a token

1. Revoke the old token at the provider.
2. Make a new token.
3. Run `secret-set NAME`. The new token replaces the old one.
4. Open a new terminal.

## Check the setup

- `env | grep -iE 'token|secret|api_key|password'` prints nothing.
- `grep -l export ~/.config/zsh/private/*.zsh` prints nothing, or only files with no tokens.
- `stat -f '%Lp' ~/.config/zsh/private/*.zsh` prints `600` for each file. On Linux, use `stat -c '%a'`.
- `./agents/install-agents.sh` prints no `skip` line for `opencode.json` or `settings.json`.

## Agent protection

`agents/install-agents.sh` adds deny rules for the secret files and for commands such as `env` and `gh auth token`. For the list and the limits, see [Deny rules for secrets](agents/README.md#deny-rules-for-secrets). The rules stop an accident, not an attack. The real protection is that no shell exports a token.
