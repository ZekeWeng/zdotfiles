# Add a deny policy for each rule in secrets.json to the OpenCode config. Keep the other settings.
# A global policy runs after the permissions of projects and agents, so they cannot allow the rule again.
# A file pattern starts with "*", so that it matches an absolute path and a path in the folder of the session.
# Shell resources are the text of the command, so a shell policy blocks each command that names the file.
($rules[0] | [
    (.files[] | "read:*\(.)", "edit:*\(.)", "shell:*\(sub("\\*+$"; ""))*"),
    (.commands[] | "shell:\(.)")
] | map({action: "tool.use", resource: ., effect: "deny"})) as $deny
# The last statement that matches wins. Thus, the deny policies go to the end of the list.
| .policies = ((.policies // []) - $deny) + $deny
# The plugin blocks the grep calls that the policies cannot block. $plugin is the path of its folder.
| .plugins = ((.plugins // []) - [$plugin]) + [$plugin]
