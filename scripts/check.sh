#!/bin/sh
# Check the repo before a commit. Each check prints "ok" or "FAIL".
# Usage: ./scripts/check.sh
# The install checks use a temporary home folder and a copy of the repo with no manual files.
# Only the Neovim check uses your real Neovim data, because it needs the installed plugins.
set -u

src="$(CDPATH='' cd -P -- "$(dirname -- "$(realpath -- "$0")")/.." && pwd -P)"
cd "$src" || exit 1
failed=0
tmp_dir="${TMPDIR:-/tmp}/zdot-check.$$"
(umask 077 && mkdir "$tmp_dir") || exit 1
home="$tmp_dir/home"
mkdir -p "$home"
trap 'run_home tmux -L zdot-check kill-server 2>/dev/null; rm -rf "$tmp_dir"' EXIT

pass() { echo "ok    $1"; }
fail() {
    echo "FAIL  $1"
    failed=1
}
skip() { echo "skip  $1"; }
has() { command -v "$1" >/dev/null 2>&1; }

# Run the command in $2 and the next arguments. Print the result with the name in $1.
# The output of the command shows only when the check fails.
check() {
    check_name="$1"
    shift
    if "$@" >"$tmp_dir/check-out" 2>&1; then
        pass "$check_name"
    else
        fail "$check_name"
        sed 's/^/      /' "$tmp_dir/check-out"
    fi
}

# Run a command with the temporary home folder and a clean environment.
run_home() { env -i HOME="$home" PATH="$PATH" TERM="${TERM:-dumb}" "$@"; }

# Return 0 if git ignores the path in $2 in the repo in $1.
is_ignored() { run_home git -C "$1" check-ignore -q "$2"; }

shell_scripts="scripts/install-dotfiles.sh scripts/install-brew.sh agents/install-agents.sh scripts/check.sh
    scripts/test.sh ascii-art/terminal-bg/termbg.sh ascii-art/terminal-bg/weather/weather.sh"
manual_files="config/zsh/zshenv.local config/zsh/zshrc.local config/zsh/paths/local.zsh
    config/ssh/config.local config/git/gitconfig.local brew/Brewfile.local config/ghostty/local config/tmux/local.conf"

# Syntax and lint
if ! has shellcheck; then
    fail "shellcheck is not installed. brew/tools.Brewfile installs it."
else
    # shellcheck disable=SC2086
    check "shellcheck" shellcheck --shell=sh $shell_scripts
fi
for f in $shell_scripts; do
    check "sh -n $f" sh -n "$f"
    if has dash; then
        check "dash -n $f" dash -n "$f"
    fi
done
for f in config/zsh/.zshenv config/zsh/.zprofile config/zsh/.zshrc config/zsh/modules/*.zsh \
    config/zsh/paths/*.zsh config/zsh/paths/*.example config/zsh/companies/_template/*.zsh \
    config/zsh/local/*.example; do
    check "zsh -n $f" zsh -n "$f"
done
if has nvim; then
    for f in config/nvim/init.lua config/nvim/lua/*/*.lua; do
        lua="local ok, e = loadfile('$f'); if not ok then io.stderr:write(e) end"
        err="$(nvim --headless -u NONE -c "lua $lua" -c q 2>&1)"
        check "lua syntax $f $err" test -z "$err"
    done
else
    skip "lua syntax (nvim is not installed)"
fi

# Format
# The files that git can see: tracked files, and new files that git does not ignore.
repo_files="$tmp_dir/files"
{
    git ls-files
    git ls-files --others --exclude-standard
} | sort -u >"$repo_files"
format_errors="$tmp_dir/format"
: >"$format_errors"
tab="$(printf '\t')"
while IFS= read -r f; do
    [ -f "$f" ] || continue
    case "$f" in
        LICENSE | *.json) continue ;;
    esac
    # The rules of .editorconfig: no trailing spaces, a final newline, LF line ends.
    if grep -nE '[[:space:]]+$' "$f" >/dev/null; then echo "$f: trailing spaces" >>"$format_errors"; fi
    if [ -s "$f" ] && [ -n "$(tail -c 1 "$f")" ]; then echo "$f: no final newline" >>"$format_errors"; fi
    if [ -s "$f" ] && [ -z "$(tail -n 1 "$f")" ]; then echo "$f: blank line at the end" >>"$format_errors"; fi
    if awk 'prev == "" && $0 == "" && NR > 1 { found = 1 } { prev = $0 } END { exit !found }' "$f"; then
        echo "$f: 2 blank lines in a row" >>"$format_errors"
    fi
    if grep -q "$(printf '\r')" "$f"; then echo "$f: CRLF line ends" >>"$format_errors"; fi
    case "$f" in
        config/git/config | config/git/gitconfig.example) ;;
        *) if grep -q "$tab" "$f"; then echo "$f: tabs" >>"$format_errors"; fi ;;
    esac
    # Code lines have 120 characters or fewer. Git aliases and HISTORY_IGNORE are long strings.
    case "$f" in
        *.md | config/git/config) ;;
        *)
            if awk 'length > 120 && !/^HISTORY_IGNORE=/ { found = 1 } END { exit !found }' "$f"; then
                echo "$f: a line is longer than 120 characters" >>"$format_errors"
            fi
            ;;
    esac
    # Each config and code file starts with a one-line comment, after the shebang.
    case "$f" in
        *.md | *.yaml) ;;
        *)
            first="$(sed -n '1{/^#!/d;p;};2p' "$f" | head -n 1)"
            case "$first" in
                "# "* | "-- "* | "// "*) ;;
                *) echo "$f: no header comment" >>"$format_errors" ;;
            esac
            ;;
    esac
done <"$repo_files"
if [ -s "$format_errors" ]; then
    fail "format: $(cat "$format_errors")"
else
    pass "format: whitespace, line ends, tabs, line length, and headers"
fi
for tool in shfmt stylua taplo; do
    has "$tool" || fail "$tool is not installed. brew/tools.Brewfile installs it."
done
if has shfmt; then
    # shellcheck disable=SC2086
    check "shfmt" shfmt -d $shell_scripts
fi
if has stylua; then
    check "stylua" stylua --check config/nvim
fi
if has taplo; then
    check "taplo" taplo fmt --check config/starship/starship.toml .stylua.toml
fi

# Validation
check "config/nvim/lazy-lock.json is valid JSON" jq empty config/nvim/lazy-lock.json
check "config/git/config is valid" git config --file config/git/config --list
check "config/git/gitconfig.example is valid" git config --file config/git/gitconfig.example --list
if has brew; then
    for f in brew/*.Brewfile; do
        check "$f is valid" env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --all --file "$f"
    done
    if [ -f brew/Brewfile.local ]; then
        check "brew/Brewfile.local is valid" \
            env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --all --file brew/Brewfile.local
    fi
fi
if has starship; then
    warnings="$(cd "$tmp_dir" &&
        STARSHIP_CONFIG="$src/config/starship/starship.toml" STARSHIP_LOG=warn starship prompt 2>&1 >/dev/null)"
    check "starship.toml has no warnings $warnings" test -z "$warnings"
fi

duplicates="$(cat brew/*.Brewfile | grep -E '^(brew|cask|tap) ' | sort | uniq -d)"
check "each package is in only 1 brew/*.Brewfile $duplicates" test -z "$duplicates"

# Safety
for f in $manual_files; do
    check "git ignores $f" git check-ignore -q "$f"
done
check "git ignores config/zsh/companies/COMPANY/" git check-ignore -q config/zsh/companies/acme/env.zsh
# No file that git can see may hold a private key or a token.
secret_re='BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}'
secret_re="$secret_re|sk-ant-[A-Za-z0-9_-]{20,}|sk-proj-[A-Za-z0-9_-]{20,}"
secret_re="$secret_re|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}"
secrets="$(xargs grep -lE "$secret_re" <"$repo_files" 2>/dev/null)"
check "no keys or tokens in the files that git can see $secrets" test -z "$secrets"

# The installers run on a copy of the repo, like a new clone.
# The copy has only the files that git can see, so your manual files and secrets are not copied.
copy="$tmp_dir/copy"
while IFS= read -r f; do
    [ -f "$f" ] || continue
    mkdir -p "$copy/$(dirname "$f")"
    cp -p "$f" "$copy/$f"
done <"$repo_files"
for f in $manual_files; do
    if [ -e "$copy/$f" ]; then fail "the copy of the repo has the manual file $f"; fi
done

# The second run must change nothing.
for script in "$copy/scripts/install-dotfiles.sh" "$copy/agents/install-agents.sh"; do
    if ! run_home "$script" >/dev/null 2>"$tmp_dir/err"; then
        fail "$script: $(cat "$tmp_dir/err")"
        continue
    fi
    changes="$(run_home "$script" 2>&1 | grep -E '^(link|move|copy|skip|write|prune) ')"
    if [ -n "$changes" ]; then
        fail "$script: the second run changed files: $changes"
    else
        pass "$script"
    fi
done

# ssh reads the installed config, with the Include of the manual file.
check "ssh config is valid" run_home ssh -G github.com

# A login shell with the installed files. zsh with no terminal prints a zle warning. Ignore it.
if run_home zsh -lic 'exit' </dev/null >/dev/null 2>"$tmp_dir/err" &&
    ! grep -v "can't change option: zle" "$tmp_dir/err" | grep -q .; then
    pass "zsh login shell"
else
    fail "zsh login shell: $(cat "$tmp_dir/err")"
fi

# git config --global must write to the manual file, not to config/git/config in the repo.
before="$(cksum <"$copy/config/git/config")"
run_home git config --global zdot.check yes
if [ "$(cksum <"$copy/config/git/config")" = "$before" ] &&
    grep -q 'check = yes' "$copy/config/git/gitconfig.local"; then
    pass "git config --global writes to ~/.gitconfig"
else
    fail "git config --global did not write to the manual file config/git/gitconfig.local."
fi

# The global ignore file must ignore OS files and secrets, and must not ignore project files.
repo="$tmp_dir/repo"
run_home git init -q "$repo"
for path in .DS_Store .env .env.staging server.pem .vscode/settings.json; do
    check "config/git/ignore ignores $path" is_ignored "$repo" "$path"
done
for path in .env.example Cargo.lock db/init.sql certs/ca.crt env/prod.ts data.gz node_modules/x.js; do
    if is_ignored "$repo" "$path"; then
        fail "config/git/ignore ignores the project file $path"
    else
        pass "config/git/ignore keeps $path"
    fi
done

# The pane runs sleep, not a shell, so that no shell hook runs.
if has tmux; then
    if run_home tmux -L zdot-check -f "$src/config/tmux/tmux.conf" new-session -d 'sleep 60' 2>"$tmp_dir/err"; then
        check "tmux.conf" run_home tmux -L zdot-check list-keys -T copy-mode-vi y
    else
        fail "tmux.conf: $(cat "$tmp_dir/err")"
    fi
else
    skip "tmux.conf (tmux is not installed)"
fi

# ghostty +validate-config truncates its stdout file, so send the output to a different file.
if has ghostty; then
    if run_home ghostty +validate-config --config-file="$src/config/ghostty/config" >"$tmp_dir/ghostty" 2>&1; then
        pass "ghostty config"
    else
        fail "ghostty config: $(cat "$tmp_dir/ghostty")"
    fi
else
    skip "ghostty config (ghostty is not installed)"
fi

# Neovim starts with no errors. This uses your installed plugins, so it needs no network.
# The config comes from this checkout, not from ~/.config/nvim, so that a worktree tests its own files.
if has nvim && [ -d "$HOME/.local/share/nvim/lazy/lazy.nvim" ]; then
    mkdir -p "$tmp_dir/xdg-config"
    ln -s "$src/config/nvim" "$tmp_dir/xdg-config/nvim"
    err="$(XDG_CONFIG_HOME="$tmp_dir/xdg-config" nvim --headless \
        "+lua vim.defer_fn(function() io.stderr:write(vim.v.errmsg) vim.cmd('qa!') end, 2000)" 2>&1)"
    check "nvim starts with no errors $err" test -z "$err"
else
    skip "nvim start (the plugins are not installed)"
fi

# The Agent Skills validator. The forge skill has disable-model-invocation, so only that error is permitted.
if has uvx; then
    validator_url="git+https://github.com/agentskills/agentskills#subdirectory=skills-ref"
    for skill in agents/skills/*/ agents/companies/_template/skills/*/; do
        [ -d "$skill" ] || continue
        skill="${skill%/}"
        out="$(uvx --from "$validator_url" skills-ref validate "$skill" 2>&1)"
        case "$out" in
            "Valid skill"*)
                pass "skill $skill"
                continue
                ;;
        esac
        errors="$(printf '%s\n' "$out" | grep '^  - ' |
            grep -v 'Unexpected fields in frontmatter: disable-model-invocation\.')"
        if [ -z "$errors" ] && grep -q '^disable-model-invocation: true$' "$skill/SKILL.md"; then
            pass "skill $skill (only the permitted disable-model-invocation error)"
        else
            fail "skill $skill: $out"
        fi
    done
else
    skip "skills (uvx is not installed)"
fi

check "scripts/test.sh" "$src/scripts/test.sh"

if [ "$failed" -ne 0 ]; then
    echo "One or more checks failed."
    exit 1
fi
echo "All checks passed."
