#!/bin/sh
# Test the behavior of the scripts and the zsh modules with stub commands. Each test prints "ok" or "FAIL".
# Usage: ./scripts/test.sh
# The tests use a temporary folder. They make no network requests, no SSH connections, and no cmux reloads.
set -u

src="$(CDPATH='' cd -P -- "$(dirname -- "$(realpath -- "$0")")/.." && pwd -P)"
cd "$src" || exit 1
failed=0
tmp_dir="${TMPDIR:-/tmp}/zdot-test.$$"
(umask 077 && mkdir "$tmp_dir") || exit 1
trap 'rm -rf "$tmp_dir"' EXIT

pass() { echo "ok    $1"; }
fail() {
    echo "FAIL  $1"
    failed=1
}
# Print the number of entries in the folder in $1.
count_entries() { find "$1" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' '; }
# Print the number of lines in the file in $1.
count_lines() { wc -l <"$1" | tr -d ' '; }
# Pass the test named $1 if the values in $2 and $3 are equal.
expect() {
    if [ "$2" = "$3" ]; then
        pass "$1"
    else
        fail "$1: expected [$3], got [$2]"
    fi
}

stubs="$tmp_dir/bin"
mkdir -p "$stubs"
weather_json='{"current":{"weather_code":63,"precipitation":1,"wind_speed_10m":10,
"wind_direction_10m":270,"is_day":1,"temperature_2m":60,"relative_humidity_2m":80}}'
cat >"$stubs/curl" <<EOF
#!/bin/sh
echo request >>"$tmp_dir/requests"
[ -z "\${STUB_CURL_FAIL:-}" ] || exit 22
sleep 0.2
echo '$(printf '%s' "$weather_json" | tr -d '\n')'
EOF
printf '#!/bin/sh\necho "cmux $*"\n' >"$stubs/cmux"
cat >"$stubs/kubectl" <<EOF
#!/bin/sh
echo run >>"$tmp_dir/kubectl-runs"
echo "zdot_test_completion=yes"
EOF
chmod +x "$stubs"/*
stub_path="$stubs:/usr/bin:/bin:/usr/sbin:/sbin:$(dirname "$(command -v jq)")"
# zsh can be outside /usr/bin and /bin, such as in the Homebrew folder on Linux. A test with "env -i" has no PATH,
# so each test starts zsh by its full path.
zsh_bin="$(command -v zsh)" || {
    echo "FAIL  zsh is not installed"
    exit 1
}

# Make a copy of the repo with only the files that git can see, like a new clone.
copy="$tmp_dir/copy"
{
    git ls-files
    git ls-files --others --exclude-standard
} | sort -u | while IFS= read -r f; do
    [ -f "$f" ] || continue
    mkdir -p "$copy/$(dirname "$f")"
    cp -p "$f" "$copy/$f"
done

# Run termbg.sh from the copy with the state folder in $1 and the next arguments.
termbg() {
    state="$1"
    shift
    env XDG_STATE_HOME="$state" PATH="$stub_path" "$copy/ascii-art/terminal-bg/termbg.sh" "$@"
}

# Wait up to 30 seconds for the termbg runs in the background. Stop the runs that do not stop, and fail.
wait_termbg() {
    tick=0
    while pgrep -f "$copy/ascii-art/terminal-bg" >/dev/null; do
        tick=$((tick + 1))
        if [ "$tick" -ge 300 ]; then
            pkill -f "$copy/ascii-art/terminal-bg"
            fail "termbg: a run did not stop in 30 seconds"
            break
        fi
        sleep 0.1
    done
    wait
}

# termbg: runs at the same time must leave the shader of the mode that won.
state="$tmp_dir/termbg-race"
termbg "$state" stars >/dev/null
stars="$(cat "$state/ghostty/termbg.glsl")"
termbg "$state" sovereign >/dev/null
sovereign="$(cat "$state/ghostty/termbg.glsl")"
bad=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
    termbg "$state" stars >/dev/null 2>&1 &
    termbg "$state" sovereign >/dev/null 2>&1 &
    termbg "$state" stars >/dev/null 2>&1 &
    wait_termbg
    case "$(cat "$state/ghostty/termbg.mode")" in
        stars) [ "$(cat "$state/ghostty/termbg.glsl")" = "$stars" ] || bad=$((bad + 1)) ;;
        sovereign) [ "$(cat "$state/ghostty/termbg.glsl")" = "$sovereign" ] || bad=$((bad + 1)) ;;
        *) bad=$((bad + 1)) ;;
    esac
done
expect "termbg: runs at the same time install the shader of the mode (10 rounds)" "$bad" 0
expect "termbg: no lock or temporary file stays" \
    "$(find "$state/ghostty" -name '*lock*' -o -name '*tmp*' | wc -l | tr -d ' ')" 0

# termbg: hourly updates from many shells make one weather request.
state="$tmp_dir/termbg-hourly"
termbg "$state" weather >/dev/null 2>&1
rm -f "$state/ghostty/termbg.stamp" "$tmp_dir/requests"
for _ in 1 2 3 4 5 6; do
    termbg "$state" update --hourly >/dev/null 2>&1 &
done
wait_termbg
expect "termbg: 6 hourly updates at the same time make 1 request" "$(count_lines "$tmp_dir/requests")" 1

# termbg: an overlay change in weather mode needs no network.
STUB_CURL_FAIL=1 termbg "$state" overlay dog-leaf >/dev/null 2>&1
expect "termbg: overlay on in weather mode with no network" "$?" 0
expect "termbg: the overlay list has the overlay" "$(cat "$state/ghostty/termbg.overlays")" dog-leaf
rm -f "$state/ghostty/termbg.weather.glsl"
STUB_CURL_FAIL=1 termbg "$state" overlay dog-leaf >/dev/null 2>&1
expect "termbg: overlay change fails with no cache and no network" "$?" 1
expect "termbg: a failed overlay change keeps the list" "$(cat "$state/ghostty/termbg.overlays")" dog-leaf

# termbg: a symlink to the script finds the designs in the repo.
ln -s "$copy/ascii-art/terminal-bg/termbg.sh" "$tmp_dir/tbg-link"
link_out="$(env XDG_STATE_HOME="$tmp_dir/termbg-link" PATH="$stub_path" "$tmp_dir/tbg-link" sovereign 2>&1)"
expect "termbg: runs through a symlink" "$link_out" "mode: sovereign"

# termbg: a new computer has no state files, and the zsh hook must print nothing.
state="$tmp_dir/termbg-new"
expect "termbg: list prints no error with no state" "$(termbg "$state" list 2>&1 >/dev/null)" ""
hook_err="$(env XDG_STATE_HOME="$state" PATH="$stub_path" "$zsh_bin" -fc \
    ". $copy/config/zsh/modules/termbg.zsh; _zdot_termbg_precmd" 2>&1)"
expect "termbg: the zsh hook prints no error with no state" "$hook_err" ""

# termbg: light writes the bone and black colors. dark removes the colors, so the Ghostty config wins.
state="$tmp_dir/termbg-theme"
expect "termbg: light prints the theme" "$(termbg "$state" light 2>&1)" "theme: light"
expect "termbg: light writes the bone and black colors" "$(grep -v '^#' "$state/ghostty/termbg.colors" | tr '\n' ';')" \
    "theme = Catppuccin Latte;background = #e4e0d8;foreground = #000000;"
expect "termbg: list shows the theme" "$(termbg "$state" list | grep '^theme:')" "theme: light"
termbg "$state" dark >/dev/null
expect "termbg: dark writes no colors" "$(grep -cv '^#' "$state/ghostty/termbg.colors")" 0
expect "termbg: no temporary colors file stays" "$(count_entries "$state/ghostty")" 2

# Run install-agents.sh from the copy with the home folder in $1, the PATH in $2, and the next arguments.
install_agents() {
    agents_home="$1"
    agents_path="$2"
    shift 2
    env -i HOME="$agents_home" PATH="$agents_path" "$copy/agents/install-agents.sh" "$@"
}

# install-agents: the cmux claude wrapper does not count as Claude Code.
real_claude="$tmp_dir/real-claude"
shim_claude="$tmp_dir/shim/cmux-cli-shims/1"
mkdir -p "$real_claude" "$shim_claude"
printf '#!/bin/sh\n' >"$real_claude/claude"
cp "$real_claude/claude" "$shim_claude/claude"
chmod +x "$real_claude/claude" "$shim_claude/claude"
agents_home="$tmp_dir/agents-home"
install_agents "$agents_home" "$real_claude:/usr/bin:/bin" >/dev/null
skill_count="$(find "$copy/agents/skills" -mindepth 2 -maxdepth 3 -name SKILL.md | wc -l | tr -d ' ')"
expect "install-agents: a real claude gets the skills" "$(count_entries "$agents_home/.claude/skills")" "$skill_count"
install_agents "$agents_home" "$shim_claude:/usr/bin:/bin" >/dev/null
expect "install-agents: only the cmux wrapper removes the skills" "$(count_entries "$agents_home/.claude/skills")" 0

# install-agents: a claude in ~/.local/bin counts when PATH does not have it.
mkdir -p "$agents_home/.local/bin"
cp "$real_claude/claude" "$agents_home/.local/bin/claude"
install_agents "$agents_home" "/usr/bin:/bin" >/dev/null
expect "install-agents: a claude in ~/.local/bin gets the skills" "$(count_entries "$agents_home/.claude/skills")" \
    "$skill_count"

# install-agents: the second run with a company changes nothing.
cp -R "$copy/agents/companies/_template" "$copy/agents/companies/acme"
agents_home="$tmp_dir/company-home"
north_rules="$agents_home/.north-code/userdata/north-opencode/engine/AGENTS.md"
mkdir -p "$(dirname "$north_rules")"
: >"$north_rules"
install_agents "$agents_home" "$real_claude:/usr/bin:/bin" acme >/dev/null
expect "install-agents: the empty North Code rules get the company copy" "$(head -n 1 "$north_rules")" \
    "<!-- Generated by zdotfiles agents/install-agents.sh for company: acme -->"
changes="$(install_agents "$agents_home" "$real_claude:/usr/bin:/bin" | grep -E '^(link|move|copy|skip|write|prune) ')"
expect "install-agents: the second run with a company changes nothing" "$changes" ""
mv "$copy/agents/companies/acme/skills/progress/linear" "$copy/agents/companies/acme/skills/writing/linear"
moved_status=0
install_agents "$agents_home" "$real_claude:/usr/bin:/bin" >/dev/null 2>&1 || moved_status=$?
expect "install-agents: a company skill that moved to a new section installs" "$moved_status" 0
moved_link="$(readlink "$agents_home/.agents/skills/linear")"
expect "install-agents: the link follows the moved company skill" "${moved_link##*/companies/}" \
    "acme/skills/writing/linear"
rm -rf "$copy/agents/companies/acme"

# install-agents: a skill name in 2 sections stops the install before any write.
mkdir -p "$copy/agents/skills/writing/fix"
cp "$copy/agents/skills/dev/fix/SKILL.md" "$copy/agents/skills/writing/fix/SKILL.md"
duplicate_status=0
install_agents "$tmp_dir/duplicate-home" "/usr/bin:/bin" >/dev/null 2>&1 || duplicate_status=$?
expect "install-agents: a skill name in 2 sections stops the install" "$duplicate_status" 1
duplicate_links="$(find "$tmp_dir/duplicate-home" -type l 2>/dev/null | wc -l | tr -d ' ')"
expect "install-agents: the stopped install makes no skill links" "$duplicate_links" 0
rm -rf "$copy/agents/skills/writing/fix"

# install-agents: OpenCode gets a deny policy for each secret rule, after its other policies, and the grep plugin.
# Its other settings stay.
# Claude Code gets a deny rule for each secret rule. The second run changes nothing.
agents_home="$tmp_dir/rules-home"
jq_path="$real_claude:/usr/bin:/bin:$(dirname "$(command -v jq)")"
secret_rules="$copy/agents/permissions/secrets.json"
mkdir -p "$agents_home/.config/opencode"
echo '{"a": 1, "policies": [{"action": "tool.use", "resource": "*", "effect": "allow"}], "plugins": ["other"]}' \
    >"$agents_home/.config/opencode/opencode.json"
install_agents "$agents_home" "$jq_path" >/dev/null
expect "install-agents: OpenCode keeps its plugins and gets the grep plugin" \
    "$(jq -c '.plugins' "$agents_home/.config/opencode/opencode.json")" \
    "[\"other\",\"$(cd "$copy" && pwd -P)/agents/permissions/opencode-plugin\"]"
# Each file gets 3 OpenCode policies: read, edit, and shell. The first file is a folder that ends in "**".
expect "install-agents: OpenCode keeps its settings and gets the deny policies last" \
    "$(jq -c '[.a, (.policies | length), .policies[0].effect, (.policies[1:4] | map(.resource)),
        .policies[-1].resource]' "$agents_home/.config/opencode/opencode.json")" \
    "$(jq -c '.files[0] as $f | [1, (.files | length) * 3 + (.commands | length) + 1, "allow",
        ["read:*\($f)", "edit:*\($f)", "shell:*\($f | rtrimstr("**"))*"], "shell:\(.commands[-1])"]' "$secret_rules")"
expect "install-agents: Claude Code gets the deny rules" \
    "$(jq -r '.permissions.deny | "\(length) \(.[0]) \(.[-1])"' "$agents_home/.claude/settings.json")" \
    "$(jq -r '"\((.files | length) * 2 + (.commands | length)) Read(~/\(.files[0])) Bash(\(.commands[-1]))"' \
        "$secret_rules")"
changes="$(install_agents "$agents_home" "$jq_path" | grep -E '^(write|skip) ')"
expect "install-agents: the second run does not change the deny rules" "$changes" ""

# install-dotfiles: an old secret file in the repo moves to ~/.config/zsh/private/.
dotfiles_home="$tmp_dir/dotfiles-home"
mkdir -p "$dotfiles_home" "$copy/config/zsh/private"
echo 'export ZDOT_OLD_SECRET=yes' >"$copy/config/zsh/private/secrets.zsh"
env -i HOME="$dotfiles_home" PATH=/usr/bin:/bin "$copy/scripts/install-dotfiles.sh" >/dev/null
expect "install-dotfiles: moves the old secrets out of the repo" \
    "$(cat "$dotfiles_home/.config/zsh/private/secrets.zsh") $(count_entries "$copy/config/zsh/private")" \
    "export ZDOT_OLD_SECRET=yes 0"
rm -rf "$copy/config/zsh/private"

# install: on Linux with a bash login shell and no terminal for chsh, the script adds the zsh block to ~/.bashrc.
# The stubs make the computer look like Linux with Homebrew. The zsh in PATH is the real zsh.
linux_bin="$tmp_dir/linux-bin"
linux_home="$tmp_dir/linux-home"
mkdir -p "$linux_bin" "$linux_home"
printf '#!/bin/sh\necho Linux\n' >"$linux_bin/uname"
printf '#!/bin/sh\necho "test:x:1000:1000::%s:/bin/bash"\n' "$linux_home" >"$linux_bin/getent"
printf '#!/bin/sh\nexit 0\n' >"$linux_bin/brew"
chmod +x "$linux_bin"/*
chmod 664 "$copy/config/ssh/config"
install_status=0
for _ in 1 2; do
    env -i HOME="$linux_home" PATH="$linux_bin:/usr/bin:/bin:$(dirname "$zsh_bin")" \
        "$copy/scripts/install.sh" </dev/null >"$tmp_dir/install-out" 2>&1 || install_status=$?
done
expect "install: 2 runs on Linux succeed" "$install_status" 0
[ "$install_status" -eq 0 ] || sed 's/^/      /' "$tmp_dir/install-out"
expect "install: the ~/.bashrc block is added 1 time" "$(grep -c '^# zdotfiles: start zsh\.' "$linux_home/.bashrc")" 1
bash_status=0
bash -n "$linux_home/.bashrc" || bash_status=$?
expect "install: the ~/.bashrc block is valid bash" "$bash_status" 0
expect "install: Linux gets no Ghostty config" "$(find "$linux_home/.config" -name 'ghostty*' | wc -l | tr -d ' ')" 0
expect "install: the ssh config gets mode 600" "$(find "$copy/config/ssh/config" -perm 0600)" "$copy/config/ssh/config"

# sshkill: a host or a ref selects the SSH workspaces. A local workspace and an unknown host match nothing.
cat >"$tmp_dir/workspaces.json" <<'EOF'
{"workspaces": [{"ref": "workspace:1", "remote": {"destination": null}},
    {"ref": "workspace:2", "remote": {"destination": "zw"}},
    {"ref": "workspace:3", "remote": {"destination": "vm"}}]}
EOF
kill_out="$(env PATH="$stub_path" "$zsh_bin" -fc ". $src/config/zsh/modules/aliases.zsh
    cmux() { case \$* in 'workspace list --json') cat $tmp_dir/workspaces.json ;; *) echo \"\$2 \$3\" ;; esac }
    sshkill zw; sshkill workspace:3; sshkill; sshkill nohost || echo none" 2>/dev/null | tr '\n' ';')"
expect "sshkill: the workspaces of 4 forms" "$kill_out" \
    "--workspace workspace:2;close workspace:2;--workspace workspace:3;close workspace:3;\
--workspace workspace:2;close workspace:2;--workspace workspace:3;close workspace:3;none;"

# secret: each function gives security the zdot service. with-secret gives the token to one command only.
# The security stub prints to stderr, because the functions send the output of security to /dev/null.
secret_out="$(env PATH="$stub_path" "$zsh_bin" -fc ". $src/config/zsh/modules/aliases.zsh
    security() { case \$1 in find-generic-password) echo tok ;; *) echo \"\$*\" >&2 ;; esac }
    secret-set A; secret-rm A; with-secret A sh -c 'echo \$A'; echo \"[\${A:-}]\"
    secret 2>/dev/null || echo \$?" 2>&1 | tr '\n' ';')"
expect "secret: the security calls and the scope of the token" "$secret_out" \
    "add-generic-password -U -s zdot -a A -T  -w;set-generic-password-partition-list -S  -s zdot -a A;\
delete-generic-password -s zdot -a A;tok;[];2;"

# secret-check: it reads the general list and the company list, and it does not read a token.
# secret-setup runs secret-set only for the missing token. The security stub has only the token A.
lists_dir="$tmp_dir/secret-lists"
mkdir -p "$lists_dir/companies/co"
printf '# C  a comment\nA  token a\n\n' >"$lists_dir/secrets.list"
echo 'B  token b' >"$lists_dir/companies/co/secrets.list"
lists_out="$(env PATH="$stub_path" "$zsh_bin" -fc ". $src/config/zsh/modules/aliases.zsh
    zdot_secret_dir=$lists_dir zdot_company=co
    security() { case \$* in add* | set*) echo set ;; *-w*) echo read ;; 'find-generic-password -s zdot -a A') ;;
        *) return 1 ;; esac }
    secret-check || echo \$?; secret-setup" 2>&1 | tr '\n' ';')"
expect "secret-check: the lists, and secret-setup sets only the missing token" "$lists_out" \
    "ok       A;missing  B  token b;1;B  token b;set;ok       A;missing  B  token b;"

# secret: with no security command, each function uses an age file with mode 600. A name cannot be a path.
# The age stub copies the token. The PATH has no security command, so the functions use age.
age_bin="$tmp_dir/age-bin"
mkdir -p "$age_bin"
for tool in cat mkdir mv rm sh find; do
    ln -s "$(command -v "$tool")" "$age_bin/$tool"
done
# shellcheck disable=SC2016
printf '#!/bin/sh\ncase "$1" in -p) cat >"$3" ;; -d) cat "$2" ;; esac\n' >"$age_bin/age"
chmod +x "$age_bin/age"
age_home="$tmp_dir/age-home"
age_file="$age_home/.config/zsh/private/age/A.age"
age_out="$(env -i HOME="$age_home" PATH="$age_bin" "$zsh_bin" -fc ". $src/config/zsh/modules/aliases.zsh
    print tok | secret-set A; echo; secret A; echo; with-secret A sh -c 'echo \$A'; echo \"[\${A:-}]\"
    find $age_file -perm 0600; secret-rm A; secret A || echo \$?; secret ../x || echo \$?" 2>/dev/null | tr '\n' ';')"
expect "secret: the age files and the scope of the token" "$age_out" ";tok;tok;[];$age_file;1;2;"

# completions: the second shell reads the cache and does not run the tool.
cache="$tmp_dir/cache"
for _ in 1 2; do
    completion="$(env -i HOME="$tmp_dir" XDG_CACHE_HOME="$cache" PATH="$stub_path" "$zsh_bin" -fc \
        "autoload -Uz compinit && compinit -D; . $src/config/zsh/modules/completions.zsh
        echo \$zdot_test_completion" 2>/dev/null)"
done
expect "completions: the cached completion loads" "$completion" yes
expect "completions: the tool runs 1 time for 2 shells" "$(count_lines "$tmp_dir/kubectl-runs")" 1

# paths.zsh: the helpers add a folder only if it exists.
path_out="$(env -i HOME="$tmp_dir" "$zsh_bin" -fc ". $src/config/zsh/paths/paths.zsh
    zdot_path_prepend $tmp_dir; zdot_path_append $tmp_dir/missing; echo \$path[1] \${path[(I)$tmp_dir/missing]}")"
expect "paths.zsh: zdot_path_prepend adds a folder, and zdot_path_append skips a missing folder" "$path_out" \
    "$tmp_dir 0"

# .zshenv: the secrets load from outside the repo.
secrets_home="$tmp_dir/secrets-home"
mkdir -p "$secrets_home/.config/zsh/private"
echo 'export ZDOT_TEST_SECRET=yes' >"$secrets_home/.config/zsh/private/secrets.zsh"
# shellcheck disable=SC2016
expect ".zshenv: loads ~/.config/zsh/private/secrets.zsh" \
    "$(env -i HOME="$secrets_home" ZDOTDIR="$src/config/zsh" "$zsh_bin" -c 'echo $ZDOT_TEST_SECRET')" yes

# git: the pager works when delta is not installed.
repo="$tmp_dir/repo"
git init -q "$repo"
git -C "$repo" -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m first
# script gives git a terminal, so git starts the pager. The macOS script takes the command as arguments.
# The util-linux script of Linux takes the command as one string after -c.
if script -V 2>/dev/null | grep -q util-linux; then
    set -- script -qec "git -C '$repo' log -1 --format=%s" /dev/null
else
    set -- script -q /dev/null git -C "$repo" log -1 --format=%s
fi
pager_out="$(env -i HOME="$tmp_dir" PATH=/usr/bin:/bin TERM=xterm GIT_CONFIG_GLOBAL="$src/config/git/config" \
    "$@" </dev/null 2>&1)"
case "$pager_out" in
    *first*) pass "git: the pager falls back to less with no delta" ;;
    *) fail "git: the pager falls back to less with no delta: $pager_out" ;;
esac

# git: the log aliases that build on lg.
for alias_name in lg lga lgp; do
    alias_out="$(GIT_CONFIG_GLOBAL="$src/config/git/config" git -C "$repo" --no-pager "$alias_name" 2>&1)"
    case "$alias_out" in
        *first*) pass "git: the $alias_name alias" ;;
        *) fail "git: the $alias_name alias: $alias_out" ;;
    esac
done

# tmux: the options load, and a reload adds no duplicate overrides.
# The pane runs sleep, not a shell, so that your .zshrc and its hooks do not run. HOME hides your local.conf.
if command -v tmux >/dev/null 2>&1; then
    mkdir -p "$tmp_dir/tmux-home"
    tmux_test() { env HOME="$tmp_dir/tmux-home" TMUX_TMPDIR="$tmp_dir" tmux -L zdot-test "$@"; }
    tmux_test -f "$src/config/tmux/tmux.conf" new-session -d 'sleep 60'
    tmux_options="$(for option in prefix base-index pane-base-index renumber-windows mode-keys status-position; do
        tmux_test show -gv "$option" 2>/dev/null || tmux_test show -gwv "$option"
    done | tr '\n' ' ')"
    expect "tmux: the options load" "$tmux_options" "C-a 1 1 on vi top "
    before="$(tmux_test show -s terminal-overrides | wc -l)"
    tmux_test source-file "$src/config/tmux/tmux.conf"
    expect "tmux: a reload adds no duplicate overrides" "$(tmux_test show -s terminal-overrides | wc -l)" "$before"
    tmux_test kill-server
fi

# The copies of one value must agree.
lazy_sha="$(sed -n 's/^local lazy_sha = "\(.*\)"$/\1/p' config/nvim/init.lua)"
lock_sha="$(jq -r '."lazy.nvim".commit' config/nvim/lazy-lock.json)"
expect "nvim: lazy_sha agrees with lazy-lock.json" "$lazy_sha" "$lock_sha"
default_modules="$(sed -n 's/^    zdot_zsh_modules=(\(.*\))$/\1/p' config/zsh/.zshrc)"
expect "zsh: the example list of modules agrees with the default" \
    "$(sed -n 's/^# zdot_zsh_modules=(\(.*\))$/\1/p' config/zsh/local/zshenv.local.example)" "$default_modules"
# shellcheck disable=SC2016
expect "zsh: the README list of modules agrees with the default" \
    "$(sed -n 's/^| `zdot_zsh_modules` | `(\(.*\))`.*/\1/p' README.md)" "$default_modules"

if [ "$failed" -ne 0 ]; then
    echo "One or more tests failed."
    exit 1
fi
echo "All tests passed."
