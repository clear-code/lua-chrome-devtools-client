module("chrome_devtools", package.seeall)

local http = require ("socket.http")
local ltn12 = require("ltn12")
local json = require("cjson")
local websocket = require("http.websocket")
local url = require("socket.url")

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
end

function connect_to_chrome()
  local http_response =
    http_connect_to_chrome("http://localhost:9222/json")
  local ws_url = get_ws_url(http_response)
  local ws = ws_connect_to_chrome(ws_url)
  return ws
end

function close_to_chrome(connection)
  ws_close(connection)
end

function translate_html_to_xml(connection)
  local response =
    send_command_to_chrome(connection,
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
  print(xml)
  return xml
end

function page_navigate(connection, page_url)
  send_command_to_chrome(connection,
                        "{"..
                          "\"id\":0,"..
                          "\"method\":\"Page.enable\""..
                        "}")
  data =
    send_command_to_chrome(connection,
                          "{"..
                            "\"id\":0,"..
                            "\"method\":\"Page.navigate\","..
                            "\"params\":"..
                            "{"..
                              "\"url\":"..page_url..
                            "}"..
                          "}")
  socket.sleep(1)
end
