# History for the shell.

# History file
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

# Options
setopt SHARE_HISTORY            # Share history across terminals.
setopt EXTENDED_HISTORY         # Record timestamp and runtime.
setopt HIST_VERIFY              # Edit before running history expansion.
setopt HIST_IGNORE_ALL_DUPS     # Remove duplicate commands.
setopt HIST_IGNORE_SPACE        # Ignore commands that start with a space.
setopt HIST_REDUCE_BLANKS       # Remove extra blanks.
setopt HIST_FCNTL_LOCK          # Use fcntl() for locking.

# Ignored commands
HISTORY_IGNORE='(ls|ls *|ll|ll *|la|la *|lt|lt *|tree|tree *|pwd|clear|gs|g|ga|gp|gpl|gcm|gst|gstp|gl|gla|reload|df|du|path|mkdir|cp|mv|rm|c|h|v|vim|ports|myip|\.\.|\.\.\.|\.\.\.\.|\.\.\.\.\.)'

# Expiry
# zsh has no setting for this. Delete the entries older than zdot_history_days, one time each day.
# LC_ALL=C is necessary, because zsh stores non-ASCII bytes in a special encoding.
zmodload zsh/datetime
if [ -z "${zdot_history_days+set}" ]; then
    zdot_history_days=120
fi
zdot_history_mark="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history-expired"
zdot_history_recent=($zdot_history_mark(N.mh-24))
if [ -f "$HISTFILE" ] && [ ${#zdot_history_recent} -eq 0 ]; then
    zdot_history_tmp="$HISTFILE.expire.$$"
    if (umask 077 && LC_ALL=C awk -v cutoff=$(( EPOCHSECONDS - zdot_history_days * 86400 )) '
        BEGIN { keep = 1 }
        /^: [0-9]+:[0-9]+;/ { keep = (substr($0, 3) + 0 >= cutoff) }
        keep' "$HISTFILE" >"$zdot_history_tmp"); then
        command mv -f "$zdot_history_tmp" "$HISTFILE"
        command mkdir -p "${zdot_history_mark:h}"
        command touch "$zdot_history_mark"
    else
        command rm -f "$zdot_history_tmp"
    fi
fi
unset zdot_history_mark zdot_history_recent zdot_history_tmp
