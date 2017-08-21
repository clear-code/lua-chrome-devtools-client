local chrome_devtools = {}

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

function get_ws_url(connect_ip, connect_port, http_response)
  local ws_url =
    json.decode(http_response[1])[1]["webSocketDebuggerUrl"]
  if string.match(ws_url, connect_ip..":"..connect_port) == nil then
    ws_url = string.gsub(ws_url, connect_ip, connect_ip..":"..connect_port)
  end
  return ws_url
end

function ws_connect(ws_url)
  local ws = websocket.new_from_uri(ws_url)
  assert(ws:connect())
  return ws
end

function connect(connect_ip, connect_port)
  if connect_port == nil then
    connect_port = 9222
  end
  local http_response =
    http_connect("http://"..connect_ip..":"..connect_port.."/json")
  local ws_url = get_ws_url(connect_ip, connect_port, http_response)
  local ws_connection = ws_connect(ws_url)
  return Client:new(ws_connection)
end

-- Client Class
Client = {}
function Client.convert_html_to_xml(self)
  local command = {
    id = 0,
    method = "Runtime.evaluate",
    params = {
      expression =
        "new XMLSerializer().serializeToString(document)"
    }
  }
  local response =
    Client:send_command(self.connection, command)
  xml = response.result.result.value
  return xml
end

function Client.page_navigate(self, page_url)
  local command = {
      id = 0,
      method = "Page.enable"
  }
  Client:send_command(self.connection, command)

  command = {
    id = 0,
    method = "Page.navigate",
    params = {
      url = page_url
    }
  }
  Client:send_command(self.connection, command)
  socket.sleep(1)
end

function Client.send_command(self, ws, command)
  command = json.encode(command)
  assert(ws:send(command))
  local response = assert(ws:receive())
  return json.decode(response)
end

function Client.close(self)
  assert(self.connection:close())
end

function Client.new(self, connection)
  local object = {}
  setmetatable(object, object)
  object.__index = self
  object.connection = connection
  return object
end

chrome_devtools.connect = connect
return chrome_devtools
