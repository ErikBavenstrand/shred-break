# Shredsauce for VS Code and Neovim

Play [Shredsauce](https://shredsauce.com), the snowboarding game, in a VS Code tab or a Neovim floating window.

## Install

macOS / Linux:

```bash
curl -fsSL https://github.com/ErikBavenstrand/vscode-shredsauce/releases/latest/download/shredsauce.vsix -o /tmp/shredsauce.vsix && code --install-extension /tmp/shredsauce.vsix
```

Windows (PowerShell):

```powershell
iwr https://github.com/ErikBavenstrand/vscode-shredsauce/releases/latest/download/shredsauce.vsix -OutFile $env:TEMP\shredsauce.vsix; code --install-extension $env:TEMP\shredsauce.vsix
```

Or download `shredsauce.vsix` from [Releases](https://github.com/ErikBavenstrand/vscode-shredsauce/releases) and use **Extensions → ⋯ → Install from VSIX…**. Run the same command again to update.

## Use

- Click **🏂 Shred** in the status bar, or run **Shredsauce: Play** from the Command Palette.
- The game fits the tab with its aspect ratio kept.
- Tab toolbar: reload the game, switch to the full site (for the cookie dialog) and back, or open shredsauce.com in your browser.

The game runs from shredsauce.com itself, ads and all, so the developer still gets support.

## Neovim

Shows just the game, filling a floating window, drawn as colored text blocks by [Carbonyl](https://github.com/fathyb/carbonyl) (Chromium for the terminal) running in Docker. Blocky, but playable.

Needs Neovim 0.11+, `curl`, Docker running (Docker Desktop, OrbStack or `colima start`), and a true-color terminal such as Ghostty, Kitty or WezTerm. The first run pulls the `fathyb/carbonyl` image (about 120 MB).

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "ErikBavenstrand/vscode-shredsauce", cmd = { "Shred", "ShredStop" }, opts = {} }
```

- `:Shred` opens the game, or hides and shows it again (it keeps running while hidden).
- `Ctrl-q` hides it from inside the game. `:ShredStop` quits.
- Click with the mouse; the keyboard goes to the game while the window is focused.
- Your cookie choice is kept in the Docker volume `shredsauce-carbonyl`.
- Options (defaults): `width = 0.9`, `height = 0.9`, `border = "rounded"`, `zoom = 100`, `fps = 30`, `hide_key = "<C-q>"`, `devtools_port = 9339`.

How it shows only the game: the plugin talks to the browser's DevTools port (bound to localhost) and adds a style that hides the rest of the page.

No sound: the browser runs in a container without audio.

## Release a new version

Bump `version` in `package.json`, commit, then tag and push:

```bash
git tag v1.0.1 && git push origin v1.0.1
```

The Release workflow builds `shredsauce.vsix` and attaches it to a GitHub release. The Neovim plugin installs straight from the repo.
