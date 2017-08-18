#!/usr/bin/env lua

pgmoon = require("pgmoon-mashape")

function split_text(text, delimiter)
  if text.find(text, delimiter) == nil then
    return { text }
  end

  local splited_text = {}
  local last_position

  for synonym, position in text:gmatch("(.-)"..delimiter.."()") do
    table.insert(splited_text, synonym)
    last_position = position
  end
  table.insert(splited_text, string.sub(text, last_position))

  return splited_text
end

function parse_connection_spec(connection_spec)
  parsed_connection_spec = {}
  for number, connection_spec_value in pairs(split_text(connection_spec, " ")) do
    key, value = connection_spec_value:match("(.-)=(.-)$")
    parsed_connection_spec[key] = value
  end
  return parsed_connection_spec
end

function convert_html(connection_spec, html_path)
  parsed_connection_spec = parse_connection_spec(connection_spec)
  local pg = pgmoon.new(parsed_connection_spec)
  assert(pg:connect())

  assert(pg:query("CREATE TABLE IF NOT EXISTS contents("..
                  "id serial,"..
                  "xml text"..
                  ");"))
  -- just for check
  xml = io.open('after-chrome.xml')
  assert(pg:query("INSERT INTO contents VALUES (XMLPARSE(DOCUMENT " .. pg:escape_literal(xml:read('*all')) .. "))"))
end

if #arg ~= 2 then
  print("Usage: "..arg[0].." CONNECTION_SPEC SOURCE_HTML")
  print(" e.g.: "..arg[0].." 'database=test_db user=postgres' source.html")
  return 1
end

convert_html(arg[1], arg[2])
