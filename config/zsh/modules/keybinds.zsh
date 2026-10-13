# Keybinds for the shell.

# Keymap
bindkey -e

# Word motion
bindkey '^[b' backward-word                 # Option+b
bindkey '^[f' forward-word                  # Option+f
bindkey '^[[1;3D' backward-word             # Option+Left
bindkey '^[[1;3C' forward-word              # Option+Right
bindkey '^[[1;5D' backward-word             # Ctrl+Left
bindkey '^[[1;5C' forward-word              # Ctrl+Right

# Word deletion
bindkey '^[^?' backward-kill-word           # Option+Backspace
bindkey '^[[3;3~' kill-word                 # Option+Delete
bindkey '^[d' kill-word                     # Option+d
bindkey '^[[3;5~' kill-word                 # Ctrl+Delete

# Line navigation
bindkey '^A' beginning-of-line              # Ctrl+a
bindkey '^E' end-of-line                    # Ctrl+e
bindkey '^[[H' beginning-of-line            # Home (Cmd+Left on macOS)
bindkey '^[[F' end-of-line                  # End (Cmd+Right on macOS)

# Line deletion
# Ghostty sends Ctrl+u for Cmd+Backspace and Cmd+Delete.
bindkey '^U' backward-kill-line             # Ctrl+u
bindkey '^K' kill-line                      # Ctrl+k (to end of line)
