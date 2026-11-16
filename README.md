# shred-break

Play [Shredsauce](https://shredsauce.com), the snowboarding game, during a coding break: in a VS Code tab, or from Neovim in a game-only window.

The game runs from shredsauce.com itself, ads and all, so the developer still gets support.

## VS Code

### Install

macOS / Linux:

```bash
curl -fsSL https://github.com/ErikBavenstrand/shred-break/releases/latest/download/shredsauce.vsix -o /tmp/shredsauce.vsix && code --install-extension /tmp/shredsauce.vsix
```

Windows (PowerShell):

```powershell
iwr https://github.com/ErikBavenstrand/shred-break/releases/latest/download/shredsauce.vsix -OutFile $env:TEMP\shredsauce.vsix; code --install-extension $env:TEMP\shredsauce.vsix
```

Or download `shredsauce.vsix` from [Releases](https://github.com/ErikBavenstrand/shred-break/releases) and use **Extensions → ⋯ → Install from VSIX…**. Run the same command again to update.

### Use

- Click **🏂 Shred** in the status bar, or run **Shredsauce: Play** from the Command Palette.
- The game fits the tab with its aspect ratio kept.
- Tab toolbar: reload the game, switch to the full site and back, or open shredsauce.com in your browser.
- The first time, answer the cookie dialog (switch to the full site if you can't see it); the choice is remembered.

## Neovim

`:Shred` opens the game in its own borderless window next to your terminal, showing only the game, with full speed, keyboard and sound. It uses Chrome, Chromium, Edge or Brave (whichever is installed) with a separate profile, so your normal browser is untouched.

Needs Neovim 0.11+ and `curl`.

### Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "ErikBavenstrand/shred-break", cmd = { "Shred", "ShredStop" }, opts = {} }
```

Without a plugin manager:

```bash
git clone https://github.com/ErikBavenstrand/shred-break ~/.local/share/nvim/site/pack/plugins/start/shredsauce
```

Update with `:Lazy update`, or `git pull` in that folder.

### Use

- `:Shred` opens the game, or brings its window to the front. `:ShredStop` closes it (so does quitting Neovim).
- It goes straight into the game: the cookie dialog is answered with essential cookies only (it never clicks "Consent"), and Play is pressed for you.
- Options (defaults): `width = 1280`, `height = 800`, `browser = nil` (auto-detect), `decline_cookies = true`, `auto_play = true`, `devtools_port = 9339`.

How it works: the plugin talks to the window's DevTools port (localhost only) to add a style that hides everything but the game, and the small scripts that answer the cookie dialog and press Play.

## Release a new version

Bump `version` in `package.json`, commit, then tag and push:

```bash
git tag v1.0.1 && git push origin v1.0.1
```

The Release workflow builds `shredsauce.vsix` and attaches it to a GitHub release. The Neovim plugin installs straight from the repo.
