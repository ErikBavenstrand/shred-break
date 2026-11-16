-- Play Shredsauce from Neovim in a borderless browser app window (Chrome, Chromium, Edge or
-- Brave) next to your terminal. The window uses its own browser profile and shows only the
-- game: once the page loads, a style injected over the DevTools protocol hides everything but
-- the game and stretches it over the window.
local cdp = require("shredsauce.cdp")

local M = {}

M.config = {
  browser = nil, -- path to a Chromium-based browser; nil finds one
  width = 1280, -- window size in pixels
  height = 800,
  devtools_port = 9339, -- localhost port the plugin uses to set up the game-only view
  decline_cookies = true, -- answer the cookie dialog with only essential cookies
  auto_play = true, -- press Play as soon as the page is ready
  profile = vim.fs.joinpath(vim.fn.stdpath("data"), "shredsauce-browser"), -- keeps cookies
}

local CANDIDATES = {
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/Applications/Chromium.app/Contents/MacOS/Chromium",
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
  "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
  "google-chrome", "google-chrome-stable", "chromium", "chromium-browser",
  "microsoft-edge", "brave-browser",
}

local state = { job = nil }

local function plugin_file(name)
  local src = debug.getinfo(1, "S").source:sub(2)
  return vim.fs.joinpath(vim.fs.dirname(src), name)
end

local function find_browser()
  if M.config.browser then
    return vim.fn.executable(M.config.browser) == 1 and M.config.browser or nil
  end
  for _, b in ipairs(CANDIDATES) do
    if vim.fn.executable(b) == 1 then
      return b
    end
  end
end

local function inject_game_only()
  local files = { "game_only.js" }
  if M.config.decline_cookies then
    table.insert(files, "decline_cookies.js")
  end
  if M.config.auto_play then
    table.insert(files, "auto_play.js")
  end
  local parts = {}
  for _, f in ipairs(files) do
    table.insert(parts, table.concat(vim.fn.readfile(plugin_file(f)), "\n"))
  end
  local js = table.concat(parts, "\n")
  local apply = { { method = "Runtime.evaluate", params = { expression = js } } }
  cdp.run(M.config.devtools_port, "shredsauce.com", {
    -- For later loads (reloads, in-game level links).
    { method = "Page.addScriptToEvaluateOnNewDocument", params = { source = js } },
    apply[1],
  }, 60000, function(err)
    if err then
      return vim.schedule(function()
        vim.notify("Shredsauce: couldn't switch to game-only view (" .. err .. ")", vim.log.levels.WARN)
      end)
    end
    -- The first call can land while the page is still loading and get lost, so re-apply for a
    -- minute; the script skips itself once the style is in place.
    local timer, runs = (vim.uv or vim.loop).new_timer(), 0
    timer:start(2000, 2000, function()
      runs = runs + 1
      if runs > 30 or not cdp.send(apply) then
        timer:stop()
        timer:close()
      end
    end)
  end)
end

local function start()
  local browser = find_browser()
  if not browser then
    vim.notify("Shredsauce: no Chrome, Chromium, Edge or Brave found. Set `browser` in setup().",
      vim.log.levels.ERROR)
    return
  end
  local cmd = {
    browser,
    "--app=https://shredsauce.com/",
    "--user-data-dir=" .. M.config.profile,
    "--remote-debugging-port=" .. M.config.devtools_port,
    "--window-size=" .. M.config.width .. "," .. M.config.height,
    "--no-first-run", "--no-default-browser-check",
    "--autoplay-policy=no-user-gesture-required", -- sound without a click first
  }
  state.job = vim.fn.jobstart(cmd, {
    on_exit = function()
      state.job = nil
      cdp.close()
    end,
  })
  if state.job <= 0 then
    state.job = nil
    vim.notify("Shredsauce: couldn't start " .. browser, vim.log.levels.ERROR)
    return
  end
  inject_game_only()
end

-- Open the game, or bring its window to the front if it is already open.
function M.open()
  if state.job then
    cdp.send({ { method = "Page.bringToFront" } })
  else
    start()
  end
end

function M.stop()
  if state.job then
    vim.fn.jobstop(state.job)
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("shredsauce", { clear = true }),
  callback = M.stop,
})

return M
