local chrome_devtools = {}

local http = require ("socket.http")
local ltn12 = require("ltn12")
local json = require("cjson")
local websocket = require("http.websocket")
local url = require("socket.url")
local basexx = require("basexx")

-- Client Class
Client = {}
function Client.http_connect(url)
  local response_table = {}
  local http_response = ""

  local response,response_code,response_header =
    http.request{
      url = url,
      sink = ltn12.sink.table(response_table)
    }
  for i=1, #response_table do
    http_response =
      http_response..response_table[i]
  end
  return http_response
end

function Client.get_ws_url(connect_ip, connect_port, http_response)
  local ws_url =
    json.decode(http_response)[1]["webSocketDebuggerUrl"]
  if string.match(ws_url, connect_ip..":"..connect_port) == nil then
    ws_url = string.gsub(ws_url, connect_ip, connect_ip..":"..connect_port)
  end
  return ws_url
end

function Client.ws_connect(ws_url)
  local ws = websocket.new_from_uri(ws_url)
  assert(ws:connect())
  return ws
end

function Client.connect(self, connect_ip, connect_port)
  if connect_port == nil then
    connect_port = 9222
  end
  local http_response =
    self.http_connect("http://"..connect_ip..":"..connect_port.."/json")
  local ws_url = self.get_ws_url(connect_ip, connect_port, http_response)
  local ws_connection = self.ws_connect(ws_url)
  self.connection = ws_connection
  self.connect_ip = connect_ip
  self.connect_port = connect_port
end

function Client.convert_html_to_xml(self, html)
  local reconnect_ip = self.connect_ip
  local reconnect_port = self.connect_port

  self:page_navigate("data:text/html;charset=UTF-8;base64,"..basexx.to_base64(html))
  self:close()
  self:connect(reconnect_ip, reconnect_port)

  local command = {
    id = 0,
    method = "Runtime.evaluate",
    params = {
      expression =
        "new XMLSerializer().serializeToString(document)"
    }
  }
  local response =
    self.send_command(self.connection, command)
  xml = response.result.result.value
  return xml
end

function Client.page_navigate(self, page_url)
  local command = {
      id = 0,
      method = "Page.enable"
  }
  self.send_command(self.connection, command)

  command = {
    id = 0,
    method = "Page.navigate",
    params = {
      url = page_url
    }
  }
  self.send_command(self.connection, command)
  socket.sleep(1)
end

function Client.send_command(ws, command)
  command = json.encode(command)
  assert(ws:send(command))
  local response = assert(ws:receive())
  return json.decode(response)
end

function Client.close(self)
  assert(self.connection:close())
end

function Client.split_lines(data)
  local result = {}
  if data:match("(.-)\r\n") then
    data = data.."\r\n"
  else
    data = data.."\n"
  end
  local function splitter(line)
    table.insert(result, line)
    return ""
  end
  data:gsub("(.-)\r?\n", splitter)
  return result
end

function Client.find_pattern_line_index(pattern, index, lines)
  local s
  while (index <= #lines) do
    s = string.find(lines[index], pattern, 1, true)
    if s then
      if pattern == "<!--" then
        if not string.find(lines[index], "<!--[", s, true) then
          return index
	end
      else
        return index
      end
    end
    index = index + 1
  end
  return nil
end

function Client.remove_double_hyphen(line)
  local found
  found = string.find(line, "--", 1, true)
  while found do
    line = string.gsub(line, "%-%-", "%-")
    found = string.find(line, "--", 1, true)
  end
  return line
end

function Client.remove_hyphen_from_line(self, line)
  local s, e
  local pre, middle, post
  s = string.find(line, "<!--", 1, true)
  e = string.find(line, "-->", s + 4, true)
  if s and e then
    pre = string.sub(line, 1, s + 3)
    middle = string.sub(line, s + 4, e - 1)
    post = string.sub(line, e)
    return pre..string.gsub(middle, "-", "")..post
  else
    return line
  end
end

function Client.remove_hyphen_in_comment(self, line)
  local result
  local s = string.find(line, "<!--", 1, true)
  local e = string.find(line, "-->", 1, true)
  local pre, post
  if s then
    pre = string.sub(line, 1, s + 3)
    post = string.sub(line, s + 4)
    result = pre..string.gsub(post, "-", "")
  elseif e then
    pre = string.sub(line, 1, e - 1)
    post = string.sub(line, e)
    result = string.gsub(pre, "-", "")..post
  end
  return result
end

function Client.html_remove_double_hyphen(self, html)
  local lines = self.split_lines(html)
  local result = {}
  local index = 1
  local pre, middle, post
  local extracted
  local start_index, end_index
  local value
  while (index <= #lines) do
    start_index = self.find_pattern_line_index("<!--", index, lines)
    end_index = self.find_pattern_line_index("-->", index, lines)
    if start_index and end_index then
      if index < start_index and start_index <= end_index then
        for i = index, start_index - 1 do
          table.insert(result, lines[i])
        end
      end
      if start_index == end_index then
        -- single line
        extracted = self:remove_hyphen_from_line(lines[start_index])
        table.insert(result, extracted)
        index = start_index + 1
      elseif start_index < end_index then
        -- multi line
        pre = self:remove_hyphen_in_comment(lines[start_index])
        table.insert(result, pre)
        for i = start_index + 1, end_index - 1 do
          middle = string.gsub(lines[i], "-", "")
          table.insert(result, middle)
        end
        post = self:remove_hyphen_in_comment(lines[end_index])
        table.insert(result, post)
        index = end_index + 1
      else
        -- not match
        if index < start_index then
          for i = index, start_index - 1 do
            table.insert(result, lines[i])
          end
        end
	index = start_index
      end
    else
      for i = index, #lines do
        table.insert(result, lines[i])
      end
      index = #lines + 1
    end
  end
  value = ""
  for i,v in pairs(result) do
    value = value.."\r\n"..v
  end
  return value
end

function Client.new(self)
  local object = {}
  setmetatable(object, object)
  object.__index = self
  object.connection = nil
  object.connect_ip = nil
  object.connect_port = nil
  return object
end
