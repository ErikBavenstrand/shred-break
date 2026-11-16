-- Minimal Chrome DevTools Protocol client: finds the page over HTTP (curl), then sends
-- commands over a hand-rolled WebSocket (vim.uv TCP), so the plugin needs no extra tools.
local bit = require("bit")
local uv = vim.uv or vim.loop

local M = {}

local function frame(payload)
  -- Client frames must be masked (RFC 6455 5.3).
  local len = #payload
  local head
  if len < 126 then
    head = string.char(0x81, 0x80 + len)
  elseif len < 65536 then
    head = string.char(0x81, 0x80 + 126, bit.rshift(len, 8), bit.band(len, 0xff))
  else
    head = string.char(0x81, 0x80 + 127, 0, 0, 0, 0,
      bit.band(bit.rshift(len, 24), 0xff), bit.band(bit.rshift(len, 16), 0xff),
      bit.band(bit.rshift(len, 8), 0xff), bit.band(len, 0xff))
  end
  local mask = { math.random(0, 255), math.random(0, 255), math.random(0, 255), math.random(0, 255) }
  local out = {}
  for i = 1, len do
    out[i] = string.char(bit.bxor(payload:byte(i), mask[(i - 1) % 4 + 1]))
  end
  return head .. string.char(unpack(mask)) .. table.concat(out)
end

-- Send `commands` ({method=, params=} tables) to the page at ws_url. The connection stays
-- open (scripts added with Page.addScriptToEvaluateOnNewDocument only last as long as it does)
-- until the browser goes away or M.close() is called.
local conn
local next_id = 0

local function encode(commands)
  local frames = {}
  for i, c in ipairs(commands) do
    next_id = next_id + 1
    frames[i] = frame(vim.json.encode({ id = next_id, method = c.method, params = c.params }))
  end
  return table.concat(frames)
end

local function send(ws_url, commands, done)
  local host, port, path = ws_url:match("^ws://([^:/]+):(%d+)(/.*)$")
  local tcp = uv.new_tcp()
  conn = tcp
  tcp:connect(host, tonumber(port), function(err)
    if err then
      tcp:close()
      return done(err)
    end
    local buf, sent = "", false
    tcp:read_start(function(rerr, data)
      if rerr or not data then
        if not tcp:is_closing() then tcp:close() end
        return
      end
      if sent then
        return -- command replies; nothing to do with them
      end
      buf = buf .. data
      if buf:find("\r\n\r\n", 1, true) and not buf:find("^HTTP/1.1 101") then
        tcp:close()
        return done("websocket handshake failed")
      end
      if buf:find("^HTTP/1.1 101") then
        sent = true
        tcp:write(encode(commands), function(werr)
          done(werr)
        end)
      end
    end)
    tcp:write(table.concat({
      "GET " .. path .. " HTTP/1.1",
      "Host: " .. host .. ":" .. port,
      "Upgrade: websocket",
      "Connection: Upgrade",
      "Sec-WebSocket-Key: c2hyZWRzYXVjZS1udmltIQ==",
      "Sec-WebSocket-Version: 13",
      "", "",
    }, "\r\n"))
  end)
end

-- Send more commands on the open connection; false if there is none.
function M.send(commands)
  if not (conn and not conn:is_closing() and conn:is_writable()) then
    return false
  end
  conn:write(encode(commands))
  return true
end

function M.close()
  if conn and not conn:is_closing() then conn:close() end
  conn = nil
end

-- Poll http://127.0.0.1:<port>/json until a page whose URL contains `url_part` shows up
-- (up to `timeout` ms), then send.
function M.run(port, url_part, commands, timeout, done)
  local deadline = uv.now() + timeout
  local function try()
    vim.system({ "curl", "-s", "--max-time", "1", "http://127.0.0.1:" .. port .. "/json" }, {}, function(res)
      local ok, pages = pcall(vim.json.decode, res.stdout or "")
      if ok and type(pages) == "table" then
        for _, p in ipairs(pages) do
          if p.type == "page" and p.webSocketDebuggerUrl and (p.url or ""):find(url_part, 1, true) then
            return send(p.webSocketDebuggerUrl, commands, done)
          end
        end
      end
      if uv.now() > deadline then
        return done("browser did not come up")
      end
      vim.defer_fn(try, 500)
    end)
  end
  try()
end

return M
