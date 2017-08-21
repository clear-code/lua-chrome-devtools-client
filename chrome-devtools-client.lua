module("chrome_devtools", package.seeall)

local http = require ("socket.http")
local ltn12 = require("ltn12")
local json = require("cjson")
local websocket = require("http.websocket")
local url = require("socket.url")

function http_connect(url)
  local http_response = {}
  local response,response_code,response_header =
    http.request{
      url = url,
      sink = ltn12.sink.table(http_response),
    }
  return http_response
end

function get_ws_url(connect_ip, http_response)
  local ws_url =
    json.decode(http_response[1])[1]["webSocketDebuggerUrl"]
  if string.match(ws_url, connect_ip..":9222") == nil then
    ws_url = string.gsub(ws_url, connect_ip, connect_ip..":9222")
  end
  return ws_url
end

function ws_connect(ws_url)
  local ws = websocket.new_from_uri(ws_url)
  assert(ws:connect())
  return ws
end

function connect(connect_ip)
  local http_response =
    http_connect("http://"..connect_ip..":9222/json")
  local ws_url = get_ws_url(connect_ip, http_response)
  local ws_connection = ws_connect(ws_url)
  return Devtools:new(ws_connection)
end

-- Devtools Class
Devtools = {}
function Devtools.convert_html_to_xml(self)
  local response =
    Devtools:send_command(self.connection,
                          "{"..
                            "\"id\":0,"..
                            "\"method\":\"Runtime.evaluate\","..
                            "\"params\":"..
                            "{"..
                              "\"expression\":"..
                              "\"new XMLSerializer().serializeToString(document)\""..
                            "}"..
                          "}")
  xml = json.decode(response).result.result.value
  return xml
end

function Devtools.page_navigate(self, page_url)
  Devtools:send_command(self.connection,
                        "{"..
                          "\"id\":0,"..
                          "\"method\":\"Page.enable\""..
                        "}")
  data =
    Devtools:send_command(self.connection,
                          "{"..
                            "\"id\":0,"..
                            "\"method\":\"Page.navigate\","..
                            "\"params\":"..
                            "{"..
                              "\"url\":\""..page_url.."\""..
                            "}"..
                          "}")
  socket.sleep(1)
end

function Devtools.send_command(self, ws, command)
  assert(ws:send(command))
  return assert(ws:receive())
end

function Devtools.close(self)
  assert(self.connection:close())
end

function Devtools.new(self, connection)
  local object = {}
  setmetatable(object, object)
  object.__index = self
  object.connection = connection
  return object
end
