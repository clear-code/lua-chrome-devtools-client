local http = require ("socket.http")
local ltn12 = require("ltn12")
local json = require("cjson")
local websocket = require("http.websocket")
local url = require("socket.url")
local utf8 = require 'lua-utf8'

--[[
function codepoint_to_utf8(str_codepoint)
  for codepoint in string.gmatch(str_codepoint, "\\u%w%w%w%w") do
    hex_codepoint = string.gsub(codepoint, "\\u", "0x")
    str_codepoint = string.gsub(str_codepoint, codepoint, utf8.char(hex_codepoint))
  end
end
--]]

function http_connect_to_chrome(url)
  local http_response = {}
  local response,response_code,response_header =
    http.request{
      url = url,
      sink = ltn12.sink.table(resp),
    }
  return http_response
end

function ws_connect_to_chrome(ws_url)
  local ws = websocket.new_from_uri(ws_url)
  assert(ws:connect())
  return ws
end

function send_command_to_chrome(ws, command)
  assert(ws:send(command))
  return assert(ws:receive())
end

local http_response =
  http_connect_to_chrome("http://localhost:9222/json")

local ws_url = json.decode(http_response[1])[1]["webSocketDebuggerUrl"]
ws_url = string.gsub(ws_url, "localhost", "localhost:9222")

local ws = ws_connect_to_chrome(ws_ulr)
send_command_to_chrome("{\"id\":1,\"method\":\"Page.enable\"}")

assert(ws:send("{\"id\":2,\"method\":\"Page.navigate\",\"params\":{\"url\":\"file:///home/horimoto/%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89/before.html\"}}"))
data = assert(ws:receive())
print(data)
assert(ws:close())

os.execute("sleep 10")
ws = websocket.new_from_uri(ws_url)
assert(ws:connect())
--assert(ws:send("{\"id\":3,\"method\":\"Page.loadEventFired\"}"))
--local data = assert(ws:receive())
--print(data)

assert(ws:send("{\"id\":4,\"method\":\"Runtime.evaluate\", \"params\":{\"expression\":\"new XMLSerializer().serializeToString(document)\"}}"))
local data = assert(ws:receive())
-- data = string.gsub(data, '(%%\%%\)', '(%%\)')
-- data = string.gsub(data, '\e\e', '\e')
-- data = string.gsub(data, '\\n', '\n')
-- data = string.gsub(data, '\\u', '0x')
print("json decode")
print(data)
data = json.decode(data)
print(type(data))
--print(data.result)
for k,v in pairs(data.result.result) do
  print(k,v)
end
--codepoint_to_utf8(data)
--for w in string.gmatch(data, "\\u%w%w%w%w") do
--  print(utf8.char(string.gsub(w, "\\u", "0x")))
--end

--print(json.encode(data))
--print(string.format("%s", data))
--print(data)

--print(url.unescape(data))
--assert(ws:send("{\"id\":2,\"method\":\"DOM.enable\"}"))
--local data = assert(ws:receive())
--print(data)
--
--assert(ws:send("{\"id\":4,\"method\":\"DOM.getDocument\"}"))
--local data = assert(ws:receive())
--print(data)

--f = io.open("write.txt", "w")
--f:write(data)
--f:close()
assert(ws:close())

--local ws_client = websocket.client.copas({timeout=2})
--local ok, err = ws_client:connect(ws_url)
--if not ok then
--  print("could not connect", err)
--end
