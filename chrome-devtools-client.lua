local chrome_devtools = {}

local http = require ("socket.http")
local ltn12 = require("ltn12")
local json = require("cjson")
local websocket = require("http.websocket")
local url = require("socket.url")
local basexx = require("basexx")
local rex = require("rex_onig")

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
  html = self:html_remove_double_hyphen(html)
  html = self:html_remove_office_p_tag(html)

  self:page_navigate("data:text/html;charset=UTF-8;base64,"..basexx.to_base64(html))

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
  local command_id = command.id

  command = json.encode(command)
  assert(ws:send(command))

  while true do
    local err, response = pcall(ws.receive, ws)
    if err == false then
      return nil
    end

    response = json.decode(response)
    if command_id == response.id then
      return response
    end
  end
end

function Client.close(self)
  assert(self.connection:close())
end

function Client.split_lines(data)
  local result = {}

  if data:match("\r\n$") then
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
  while (index <= #lines) do
    local start_index, end_index = string.find(lines[index], pattern, 1, true)
    if start_index then
      if pattern == "<!--" then
        if not string.find(lines[index], "<!--[", start_index, true) then
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

--[[
  This function only use single line comment.
--]]
function Client.remove_hyphen_from_single_line(self, line)
  local left_bracket_start, left_bracket_end = string.find(line, "<!--", 1, true)
  local right_bracket_start, right_bracket_end = string.find(line, "-->", left_bracket_end + 1, true)
  local pre, middle, post

  if left_bracket_start and right_bracket_start then
    pre = string.sub(line, 1, left_bracket_end)
    middle = string.sub(line, left_bracket_end + 1, right_bracket_start - 1)
    post = string.sub(line, right_bracket_start)
    return pre..string.gsub(middle, "-", "")..post -- Remove hyphen in comment
  else
    return line
  end
end

--[[
  This function only use with multi line comment.
]]--
function Client.remove_hyphen_in_multi_line(self, line, offset)
  local result
  local left_bracket_start, left_bracket_end = string.find(line, "<!--", offset, true)
  local right_bracket_start, right_bracket_end = string.find(line, "-->", offset, true)
  local pre, post

  if left_bracket_start and right_bracket_start then
    if right_bracket_end < left_bracket_start then
      -- -->body<!--
      pre = string.sub(line, 1, right_bracket_start - 1)
      middle = string.sub(line, right_bracket_start, left_bracket_end)
      post = string.sub(line, left_bracket_end + 1)
      result = string.gsub(pre, "-", "")..middle..string.gsub(post, "-", "")
    else
      pre = string.sub(line, 1, left_bracket_end)
      middle = string.sub(line, left_bracket_end + 1, right_bracket_start - 1)
      post = string.sub(line, right_bracket_start)
      result = pre..string.gsub(middle, "-", "")..post
    end
  elseif left_bracket_start then
    pre = string.sub(line, 1, left_bracket_end)
    post = string.sub(line, left_bracket_end + 1)
    result = pre..string.gsub(post, "-", "") -- Remove hyphen in comment
  elseif right_bracket_start then
    pre = string.sub(line, 1, right_bracket_start - 1)
    post = string.sub(line, right_bracket_start)
    result = string.gsub(pre, "-", "")..post -- Remove hyphen in comment
  end

  return result
end

function Client.html_remove_double_hyphen(self, html)
  local sanitized_xml = ""
  local position = 1
  local comment_start_point = nil
  local nest_level = 0

  local function strip_hyphen(text)
    text = rex.gsub(text, "(?:\\A-+|-+\\z)", "")
    return text
  end

  local function shorten_double_hyphen(text)
    --print("3,", text)
    if text == nil then
      return text
    end
    text = rex.gsub(text, "--+", "-")
    return text
  end

  local function sanitize_comment(comment)
    --print("comment", comment)
    content = rex.gsub(comment, "\\A<!--|-->\\z", "")
    --print("content1", content)
    content = strip_hyphen(content)
    --print("content2", content)
    content = shorten_double_hyphen(content)
    --print("content3", content)
    if content == nil then
      --print("hoge")
      return "<!---->"
    else
      return "<!--"..content.."-->"
    end
  end

  local function remove_double_hyphen(html_lines)
    match_data = rex.match(html_lines, "<!--|-->", position)
    while match_data do
      if match_data == "<!--" then
        comment_start_start_position, comment_start_end_position = rex.find(html_lines, "<!--", position)
	--print("s, e", comment_start_start_position, comment_start_end_position)
        if nest_level == 0 then
	  --print("find", html_lines, rex.find(html_lines, "<!--"))
	  if position == comment_start_start_position then
	    sanitized_xml = ""
	  else
            sanitized_xml = sanitized_xml..html_lines:sub(position, comment_start_start_position - 1)
            --print("sani", html_lines, position, comment_start_start_position, sanitized_xml)
          end
          comment_start_position = comment_start_start_position
        end
	position = comment_start_end_position + 1
        nest_level = nest_level + 1
      else
        nest_level = nest_level - 1
        comment_end_start_position, comment_end_end_position = rex.find(html_lines, "-->", position)
        if nest_level == 0 then
          comment = html_lines:sub(comment_start_position, comment_end_end_position)
          sanitized_xml = sanitized_xml..sanitize_comment(comment)
	  --print("sanisani", sanitized_xml)
          comment_start_start_position = nil
        end
	position = comment_end_end_position + 1
      end
      --print(position)
      match_data = rex.match(html_lines, "<!--|-->", position)
    end
    sanitized_xml = sanitized_xml..html_lines:sub(position, -1)
    print("result", sanitized_xml)
  end
--    print("index", test_index)
  html = "<!---->"
  html = "<!----->"
  html = "<!------>"
  html = "<!-- -- -->"
  html = "<!-- <!-- --> -->"
  html = "abc<!-- <!-- --> -->b<!-- -- -->c"
  html = [[abc<!-- --cdf
  -->]]
  remove_double_hyphen(html)
--  end
end
--  local html_lines = self.split_lines(html)
--  for i=1, #html_lines, 1 do
--    start_comment_start_point, start_comment_end_point = html:find("<!%-%-")
--    end_comment_start_point, end_comment_end_point = html:find("%-%->")
--    splited_str = html:sub(start_comment_end_point+1, end_comment_start_point-1)
--    print(splited_str)
--  end
--[[
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
        extracted = self:remove_hyphen_from_single_line(lines[start_index])
        table.insert(result, extracted)
        index = start_index + 1
      elseif start_index < end_index then
        -- multi line
        pre = self:remove_hyphen_in_multi_line(lines[start_index])
        table.insert(result, pre)
        for i = start_index + 1, end_index - 1 do
          middle = string.gsub(lines[i], "-", "")
          table.insert(result, middle)
        end
        post = self:remove_hyphen_in_multi_line(lines[end_index])
        index = end_index
        left_bracket_start = string.find(lines[end_index], "<!--", 1, true)
        if left_bracket_start then
          table.insert(result, post)
          end_index = self.find_pattern_line_index("-->", index + 1, lines)
          for i = index + 1, end_index - 1 do
            middle = string.gsub(lines[i], "-", "")
            table.insert(result, middle)
          end
          post = self:remove_hyphen_in_multi_line(lines[end_index])
          table.insert(result, post)
        else
           table.insert(result, post)
        end
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
--]]

function Client.html_remove_office_p_tag(self, html)
  pre = string.gsub(html, "<o:p", "<p")
  post = string.gsub(pre, "/o:p>", "/p>")
  return string.gsub(post, "\r?\n", "")
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
