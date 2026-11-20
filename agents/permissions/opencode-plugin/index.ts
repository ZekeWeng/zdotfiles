// Block each grep call that searches a folder with secret files in it, or a folder in a secret folder.
// A grep call shows the file content. Its include glob gets past the ignore files, and its policy resource is the
// regex, not the path. Thus, the policies in secrets.json cannot block it.
import { readFileSync, realpathSync } from "node:fs"
import { homedir } from "node:os"
import { isAbsolute, join, resolve, sep } from "node:path"

// Read the rules at each call, so that a new rule works with no restart of OpenCode.
const rules = (): { files: string[] } =>
  JSON.parse(readFileSync(new URL("../secrets.json", import.meta.url), "utf8"))

// Give the path in $path and its real path, so that a symlink cannot hide a secret.
const forms = (path: string) => {
  try {
    return [path, realpathSync(path)]
  } catch {
    return [path]
  }
}

// The part of each file rule before the first glob character, such as ~/.ssh for .ssh/id_*.
const secretPaths = () =>
  rules().files.flatMap((file) => {
    const parts = file.split("/")
    const glob = parts.findIndex((part) => /[*?[{]/.test(part))
    return forms(join(homedir(), ...(glob === -1 ? parts : parts.slice(0, glob))))
  })

const contains = (folder: string, path: string) => path === folder || path.startsWith(folder.replace(/\/$/, "") + sep)

export default {
  id: "zdot-secrets",
  async setup(ctx: any) {
    await ctx.tool.hook("execute.before", (event: { tool: string; input: any }) => {
      if (event.tool !== "grep") return
      const path = String(event.input?.path || ".").replace(/^~(?=$|\/)/, homedir())
      const roots = forms(isAbsolute(path) ? path : resolve(ctx.location.directory, path))
      const near = (secret: string) => roots.some((root) => contains(root, secret) || contains(secret, root))
      if (secretPaths().some(near)) {
        throw new Error(`grep cannot search ${roots[0]}, because it has secret files. Search a smaller folder.`)
      }
    })
  },
}
