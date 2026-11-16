# Shredsauce for VS Code and Neovim

Play [Shredsauce](https://shredsauce.com), the snowboarding game, in a VS Code tab, or from Neovim in a game-only window.

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

`:Shred` opens the game in its own borderless window next to your terminal, showing only the game, with full speed, keyboard and sound. It uses Chrome, Chromium, Edge or Brave (whichever is installed) with a separate profile, so your normal browser is untouched.

Needs Neovim 0.11+ and `curl`.

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "ErikBavenstrand/vscode-shredsauce", cmd = { "Shred", "ShredStop" }, opts = {} }
```

Without a plugin manager:

```bash
git clone https://github.com/ErikBavenstrand/vscode-shredsauce ~/.local/share/nvim/site/pack/plugins/start/shredsauce
```

- `:Shred` opens the game, or brings its window to the front. `:ShredStop` closes it (so does quitting Neovim).
- Options (defaults): `width = 1280`, `height = 800`, `browser = nil` (auto-detect), `devtools_port = 9339`.

How it shows only the game: the plugin talks to the window's DevTools port (localhost only) and adds a style that hides the rest of the page.

## Release a new version

Bump `version` in `package.json`, commit, then tag and push:

```bash
git tag v1.0.1 && git push origin v1.0.1
```

The Release workflow builds `shredsauce.vsix` and attaches it to a GitHub release. The Neovim plugin installs straight from the repo.
