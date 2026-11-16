-- Play Shredsauce in a floating Neovim terminal.
-- Renders through Carbonyl (Chromium for the terminal) in Docker: its Linux build ships the
-- software WebGL the game needs, which the macOS build lacks. Once the page loads, a style
-- injected over the DevTools protocol hides everything but the game and stretches it over the
-- whole view.
local cdp = require("shredsauce.cdp")

local M = {}

local CONTAINER = "shredsauce-nvim"

M.config = {
  width = 0.9, -- fraction of the editor
  height = 0.9,
  border = "rounded",
  zoom = 100, -- page zoom in percent; lower shows the game's UI smaller and sharper
  fps = 30,
  image = "fathyb/carbonyl",
  volume = "shredsauce-carbonyl", -- keeps cookies (e.g. the consent choice) between runs
  devtools_port = 9339, -- localhost port used once at startup to inject the game-only style
  hide_key = "<C-q>", -- hides the window from inside the game; the game keeps running
}

local state = { buf = nil, win = nil, bar_buf = nil, bar_win = nil, job = nil }

local function plugin_file(name)
  local src = debug.getinfo(1, "S").source:sub(2)
  return vim.fs.joinpath(vim.fs.dirname(src), name)
end

local function win_opts()
  local cols, lines = vim.o.columns, vim.o.lines - vim.o.cmdheight
  local w = math.max(40, math.floor(cols * M.config.width))
  local h = math.max(15, math.floor(lines * M.config.height))
  return {
    relative = "editor",
    width = w,
    height = h,
    col = math.floor((cols - w) / 2),
    row = math.floor((lines - h) / 2) - 1,
    style = "minimal",
    border = M.config.border,
    footer = " " .. M.config.hide_key .. " hide · :ShredStop quit ",
    footer_pos = "right",
  }
end

-- A one-line title strip over Carbonyl's address bar (the first terminal row).
local function draw_bar(width)
  if not (state.bar_buf and vim.api.nvim_buf_is_valid(state.bar_buf)) then
    state.bar_buf = vim.api.nvim_create_buf(false, true)
  end
  local title = "🏂 Shredsauce"
  local pad = math.max(0, math.floor((width - vim.fn.strdisplaywidth(title)) / 2))
  vim.api.nvim_buf_set_lines(state.bar_buf, 0, -1, false, { string.rep(" ", pad) .. title })
  local opts = {
    relative = "win", win = state.win, row = 0, col = 0, width = width, height = 1,
    style = "minimal", focusable = false, zindex = 60,
  }
  if state.bar_win and vim.api.nvim_win_is_valid(state.bar_win) then
    vim.api.nvim_win_set_config(state.bar_win, opts)
  else
    state.bar_win = vim.api.nvim_open_win(state.bar_buf, false, opts)
    vim.wo[state.bar_win].winhighlight = "Normal:FloatTitle"
  end
end

local function close_wins()
  for _, k in ipairs({ "bar_win", "win" }) do
    if state[k] and vim.api.nvim_win_is_valid(state[k]) then
      vim.api.nvim_win_close(state[k], true)
    end
    state[k] = nil
  end
end

local function open_win()
  local opts = win_opts()
  state.win = vim.api.nvim_open_win(state.buf, true, opts)
  vim.wo[state.win].winhighlight = "NormalFloat:Normal,FloatBorder:FloatBorder"
  draw_bar(opts.width)
  vim.cmd.startinsert()
end

local function docker_ok()
  if vim.fn.executable("docker") == 0 then
    return false, "docker not found. Install Docker (Docker Desktop, OrbStack or colima)."
  end
  vim.fn.system({ "docker", "info" })
  if vim.v.shell_error ~= 0 then
    return false, "Docker isn't running. Start it (e.g. `colima start`) and try again."
  end
  return true
end

local function inject_game_only()
  local js = table.concat(vim.fn.readfile(plugin_file("game_only.js")), "\n")
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
  local ok, err = docker_ok()
  if not ok then
    vim.notify("Shredsauce: " .. err, vim.log.levels.ERROR)
    return
  end
  vim.fn.system({ "docker", "rm", "-f", CONTAINER }) -- clear a leftover from a crashed run

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].bufhidden = "hide"
  open_win()

  local cmd = {
    "docker", "run", "--rm", "-it", "--name", CONTAINER,
    "-e", "COLORTERM=truecolor",
    "-v", M.config.volume .. ":/carbonyl/data",
    "-p", "127.0.0.1:" .. M.config.devtools_port .. ":9222",
    M.config.image,
    "--remote-debugging-port=9222", "--remote-debugging-address=0.0.0.0",
    "--zoom=" .. M.config.zoom,
    "--fps=" .. M.config.fps,
    "https://shredsauce.com/",
  }
  state.job = vim.fn.jobstart(cmd, {
    term = true,
    on_exit = function()
      vim.schedule(function()
        close_wins()
        for _, k in ipairs({ "buf", "bar_buf" }) do
          if state[k] and vim.api.nvim_buf_is_valid(state[k]) then
            vim.api.nvim_buf_delete(state[k], { force = true })
          end
          state[k] = nil
        end
        state.job = nil
        cdp.close()
      end)
    end,
  })
  inject_game_only()

  vim.keymap.set("t", M.config.hide_key, M.hide, { buffer = state.buf, desc = "Hide Shredsauce" })
  vim.keymap.set("n", "q", M.hide, { buffer = state.buf, desc = "Hide Shredsauce" })
end

function M.hide()
  close_wins()
end

function M.toggle()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    M.hide()
  elseif state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    open_win() -- the game kept running while hidden
  else
    start()
  end
end

function M.stop()
  if state.job then
    -- `docker stop` lets Chromium save cookies before exiting.
    vim.fn.jobstart({ "docker", "stop", "-t", "3", CONTAINER }, { detach = true })
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local group = vim.api.nvim_create_augroup("shredsauce", { clear = true })
vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.stop })
vim.api.nvim_create_autocmd("VimResized", {
  group = group,
  callback = function()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      local opts = win_opts()
      vim.api.nvim_win_set_config(state.win, opts)
      draw_bar(opts.width)
    end
  end,
})

return M
