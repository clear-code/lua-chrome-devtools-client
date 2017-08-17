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
      sink = ltn12.sink.table(http_response),
    }
  return http_response
end

function get_ws_url(http_response)
  local ws_url =
    json.decode(http_response[1])[1]["webSocketDebuggerUrl"]
  if string.match(ws_url, "localhost:9222") == nil then
    ws_url = string.gsub(ws_url, "localhost", "localhost:9222")
  end
  return ws_url
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

function ws_close(ws)
  assert(ws:close())
  os.execute("sleep 5")
end

function connect_to_chrome()
  local http_response =
    http_connect_to_chrome("http://localhost:9222/json")
  local ws_url = get_ws_url(http_response)
  local ws = ws_connect_to_chrome(ws_url)
  return ws
end

local connection = connect_to_chrome()
send_command_to_chrome(connection, "{\"id\":1,\"method\":\"Page.enable\"}")

local data = send_command_to_chrome(connection, "{\"id\":2,\"method\":\"Page.navigate\",\"params\":{\"url\":\"file:///home/horimoto/%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89/before.html\"}}")
print(data)
ws_close(connection)

connection = connect_to_chrome()

data = send_command_to_chrome(connection, "{\"id\":4,\"method\":\"Runtime.evaluate\", \"params\":{\"expression\":\"new XMLSerializer().serializeToString(document)\"}}")

print("json decode")
print(data)
data = json.decode(data)
print(type(data))
for k,v in pairs(data.result.result) do
  print(k,v)
end

ws_close(connection)
