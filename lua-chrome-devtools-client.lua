package.path=package.path..';./?.lua'
local chrome_devtools = require("chrome-devtools-client")

local client = chrome_devtools.connect("localhost")

client:page_navigate(
  "file:///home/horimoto/%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89/before.html")
client:close()

client = chrome_devtools.connect("localhost")
xml = client:convert_html_to_xml()
print(xml)
client:close()
