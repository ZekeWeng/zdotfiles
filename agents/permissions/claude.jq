# Add a deny rule for each rule in secrets.json to the Claude Code settings. Keep the other settings.
# A deny rule wins over each allow rule in each settings file.
# A Read rule also blocks file commands in Bash that name the file, such as cat.
($rules[0] | [
    (.files[] | "Read(~/\(.))", "Edit(~/\(.))"),
    (.commands[] | "Bash(\(.))")
]) as $deny
| .permissions.deny = ((.permissions.deny // []) - $deny) + $deny
