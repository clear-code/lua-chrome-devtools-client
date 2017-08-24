local chrome_devtools = require("chrome-devtools-client")
pgmoon = require("pgmoon-mashape")

function split_text(text, delimiter)
  if text.find(text, delimiter) == nil then
    return { text }
  end

  local splited_texts = {}
  local last_position

  for splited_text, position in text:gmatch("(.-)"..delimiter.."()") do
    table.insert(splited_texts, splited_text)
    last_position = position
  end
  table.insert(splited_texts, string.sub(text, last_position))

  return splited_texts
end

function parse_connection_spec(connection_spec)
  parsed_connection_spec = {}
  for number, connection_spec_value in pairs(split_text(connection_spec, " ")) do
    key, value = connection_spec_value:match("(.-)=(.-)$")
    parsed_connection_spec[key] = value
  end
  return parsed_connection_spec
end

function save_xml(connection_spec, xml, source_html_path)
  parsed_connection_spec = parse_connection_spec(connection_spec)
  local pg = pgmoon.new(parsed_connection_spec)
  assert(pg:connect())

  assert(pg:query("CREATE TABLE IF NOT EXISTS converted_xml("..
                  "id serial,"..
                  "xml xml,"..
                  "source_html_path text"..
                  ");"))
  assert(pg:query("INSERT INTO converted_xml (xml, source_html_path)"..
                  "VALUES (XMLPARSE(DOCUMENT " .. pg:escape_literal(xml) .. "), "..
                           pg:escape_literal(source_html_path)..")"))
end

if #arg ~= 2 then
  print("Usage: "..arg[0].." CONNECTION_SPEC SOURCE_HTML")
  print(" e.g.: "..arg[0].." 'database=test_db user=postgres' source.html")
  os.exit(1)
end

local connect_ip = "localhost"
local connect_port = "9222"

local client = chrome_devtools.connect(connect_ip, connect_port)

client:page_navigate("file://"..arg[2])
client:close()

client = chrome_devtools.connect(connect_ip, connect_port)
xml = client:convert_html_to_xml()
save_xml(arg[1], xml, arg[2])
client:close()
os.exit(0)
