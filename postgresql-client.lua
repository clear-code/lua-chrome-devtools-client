local postgresql_client = {}
pgmoon = require("pgmoon-mashape")

--PGClient Class
PGClient = {}
function PGClient.split_text(self, text, delimiter)
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

function PGClient.parse_connection_spec(self, connection_spec)
  parsed_connection_spec = {}
  for number, connection_spec_value in pairs(self:split_text(connection_spec, " ")) do
    key, value = connection_spec_value:match("(.-)=(.-)$")
    parsed_connection_spec[key] = value
  end
  return parsed_connection_spec
end

function PGClient.save_xml(self, connection_spec, xml, source_html_path)
  parsed_connection_spec = self:parse_connection_spec(connection_spec)
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

function PGClient.new(self)
  local object = {}
  setmetatable(object, object)
  object.__index = self
  return object
end
