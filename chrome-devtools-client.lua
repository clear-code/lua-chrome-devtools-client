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
  html = self:html_remove_invalid_character(html)
  html = self:html_remove_invalid_attribute_name(html)
  html = self:html_remove_nest_double_quotation(html)

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

function Client.capture_screenshot(self, opt)
  local command = {
    id = 0,
    method = "Page.captureScreenshot",
    params = opt
  }
  local response = self.send_command(self.connection, command)
  return response.result.data
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

function Client.html_remove_double_hyphen(self, html)
  local sanitized_xml = ""
  local position = 1
  local comment_start_point = nil
  local nest_level = 0
  local content = nil
  local match_data = ""
  local comment_start_start_position = 0
  local comment_start_end_position = 0
  local comment_start_position = 0
  local comment_end_start_position = 0
  local comment_end_end_position = 0

  local function strip_hyphen(text)
    text = rex.gsub(text, "(?:\\A-+|-+\\z)", "")
    return text
  end

  local function shorten_double_hyphen(text)
    if text == nil then
      return text
    end
    text = rex.gsub(text, "--+", "-")
    return text
  end

  local function sanitize_comment(comment)
    content = rex.gsub(comment, "\\A<!--|-->\\z", "")
    content = strip_hyphen(content)
    content = shorten_double_hyphen(content)
    if content == nil then
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
        if nest_level == 0 then
	  if position == comment_start_start_position then
	    sanitized_xml = ""
	  else
            sanitized_xml = sanitized_xml..html_lines:sub(position, comment_start_start_position - 1)
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
          comment_start_start_position = nil
        end
	position = comment_end_end_position + 1
      end
      match_data = rex.match(html_lines, "<!--|-->", position)
    end
    sanitized_xml = sanitized_xml..html_lines:sub(position, -1)
    return sanitized_xml
  end

  return remove_double_hyphen(html)
end

function Client.html_remove_office_p_tag(self, html)
  pre = string.gsub(html, "<o:p", "<p")
  post = string.gsub(pre, "/o:p>", "/p>")
  return string.gsub(post, "\r?\n", "")
end

function Client.html_remove_invalid_attribute_name(self, html)
  html = rex.gsub(html, "\\s[0-9]+?[^0-9]*?\"=\"\"\\s", " ")
  html = rex.gsub(html, "img\nsrc|img\r\nsrc|imgsrc", "img src")
  return html
end

function Client.html_remove_invalid_character(self, html)
  html = rex.gsub(html, "\x01", "")
  return html
end

function Client.html_remove_nest_double_quotation(self, html)
  html = rex.gsub(html, "\"Sunrise.*?\"", "")
  return html
end

function Client.get_version()
  return "0.8-1"
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
