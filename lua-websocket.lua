local http = require ("socket.http")
local ltn12 = require("ltn12")
local json = require("cjson")
local websocket = require("http.websocket")
local url = require("socket.url")
local utf8 = require 'lua-utf8'

local resp = {}
-- 返値：応答、コード、ヘッダー
local r,c,h = http.request{
    url = "http://localhost:9222/json",
    sink = ltn12.sink.table( resp ),
}

local ws_url = json.decode(resp[1])[1]["webSocketDebuggerUrl"]
ws_url = string.gsub(ws_url, "localhost", "localhost:9222")

local ws = websocket.new_from_uri(ws_url)
assert(ws:connect())

assert(ws:send("{\"id\":1,\"method\":\"Page.enable\"}"))
local data = assert(ws:receive())

assert(ws:send("{\"id\":2,\"method\":\"Page.navigate\",\"params\":{\"url\":\"file:///home/horimoto/%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89/before.html\"}}"))
data = assert(ws:receive())
print(data)
assert(ws:close())

ws = websocket.new_from_uri(ws_url)
assert(ws:connect())

assert(ws:send("{\"id\":4,\"method\":\"Runtime.evaluate\", \"params\":{\"expression\":\"new XMLSerializer().serializeToString(document)\"}}"))
local xml_data = assert(ws:receive())
print(xml_data)

assert(ws:close())
