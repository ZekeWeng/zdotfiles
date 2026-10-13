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
printf '#!/bin/sh\necho "ssh $*"\n' >"$stubs/ssh"
cat >"$stubs/kubectl" <<EOF
#!/bin/sh
echo run >>"$tmp_dir/kubectl-runs"
echo "zdot_test_completion=yes"
EOF
chmod +x "$stubs"/*
stub_path="$stubs:/usr/bin:/bin:/usr/sbin:/sbin:$(dirname "$(command -v jq)")"

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
hook_err="$(env XDG_STATE_HOME="$state" PATH="$stub_path" zsh -fc \
    ". $copy/config/zsh/modules/termbg.zsh; _zdot_termbg_precmd" 2>&1)"
expect "termbg: the zsh hook prints no error with no state" "$hook_err" ""

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
skill_count="$(count_entries "$copy/agents/skills")"
expect "install-agents: a real claude gets the skills" "$(count_entries "$agents_home/.claude/skills")" "$skill_count"
install_agents "$agents_home" "$shim_claude:/usr/bin:/bin" >/dev/null
expect "install-agents: only the cmux wrapper removes the skills" "$(count_entries "$agents_home/.claude/skills")" 0

# install-agents: the second run with a company changes nothing.
cp -R "$copy/agents/companies/_template" "$copy/agents/companies/acme"
agents_home="$tmp_dir/company-home"
install_agents "$agents_home" "$real_claude:/usr/bin:/bin" acme >/dev/null
changes="$(install_agents "$agents_home" "$real_claude:/usr/bin:/bin" | grep -E '^(link|move|copy|skip|write|prune) ')"
expect "install-agents: the second run with a company changes nothing" "$changes" ""
rm -rf "$copy/agents/companies/acme"

# ssh(): only "ssh HOST" in a cmux terminal opens cmux ssh. script gives zsh a terminal.
ssh_out="$(env PATH="$stub_path" script -q /dev/null zsh -fc ". $src/config/zsh/modules/aliases.zsh
    CMUX_WORKSPACE_ID=test
    ssh zw; ssh zw ls; echo x | ssh zw; ssh -p 22 zw
    unset CMUX_WORKSPACE_ID; ssh zw" </dev/null 2>&1 | tr -d '\r\010' | sed 's/^\^D//' | grep -E '^(cmux|ssh) ')"
expect "ssh(): the routes of 5 forms" "$(printf '%s' "$ssh_out" | tr '\n' ';')" \
    "cmux ssh zw;ssh zw ls;ssh zw;ssh -p 22 zw;ssh zw"

# completions: the second shell reads the cache and does not run the tool.
cache="$tmp_dir/cache"
for _ in 1 2; do
    completion="$(env -i HOME="$tmp_dir" XDG_CACHE_HOME="$cache" PATH="$stub_path" zsh -fc \
        "autoload -Uz compinit && compinit -D; . $src/config/zsh/modules/completions.zsh
        echo \$zdot_test_completion" 2>/dev/null)"
done
expect "completions: the cached completion loads" "$completion" yes
expect "completions: the tool runs 1 time for 2 shells" "$(count_lines "$tmp_dir/kubectl-runs")" 1

# paths.zsh: the helpers add a folder only if it exists.
path_out="$(env -i HOME="$tmp_dir" zsh -fc ". $src/config/zsh/paths/paths.zsh
    zdot_path_prepend $tmp_dir; zdot_path_append $tmp_dir/missing; echo \$path[1] \${path[(I)$tmp_dir/missing]}")"
expect "paths.zsh: zdot_path_prepend adds a folder, and zdot_path_append skips a missing folder" "$path_out" \
    "$tmp_dir 0"

# .zshenv: the secrets load from outside the repo.
secrets_home="$tmp_dir/secrets-home"
mkdir -p "$secrets_home/.config/zsh/private"
echo 'export ZDOT_TEST_SECRET=yes' >"$secrets_home/.config/zsh/private/secrets.zsh"
# shellcheck disable=SC2016
expect ".zshenv: loads ~/.config/zsh/private/secrets.zsh" \
    "$(env -i HOME="$secrets_home" ZDOTDIR="$src/config/zsh" zsh -c 'echo $ZDOT_TEST_SECRET')" yes

# git: the pager works when delta is not installed.
repo="$tmp_dir/repo"
git init -q "$repo"
git -C "$repo" -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m first
pager_out="$(env -i HOME="$tmp_dir" PATH=/usr/bin:/bin TERM=xterm GIT_CONFIG_GLOBAL="$src/config/git/config" \
    script -q /dev/null git -C "$repo" log -1 --format=%s </dev/null 2>&1)"
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
if command -v tmux >/dev/null 2>&1; then
    socket="zdot-test-$$"
    tmux -L "$socket" -f "$src/config/tmux/tmux.conf" new-session -d
    tmux_options="$(for option in prefix base-index pane-base-index renumber-windows mode-keys status-position; do
        tmux -L "$socket" show -gv "$option" 2>/dev/null || tmux -L "$socket" show -gwv "$option"
    done | tr '\n' ' ')"
    expect "tmux: the options load" "$tmux_options" "C-a 1 1 on vi top "
    before="$(tmux -L "$socket" show -s terminal-overrides | wc -l)"
    tmux -L "$socket" source-file "$src/config/tmux/tmux.conf"
    expect "tmux: a reload adds no duplicate overrides" "$(tmux -L "$socket" show -s terminal-overrides | wc -l)" \
        "$before"
    tmux -L "$socket" kill-server
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
