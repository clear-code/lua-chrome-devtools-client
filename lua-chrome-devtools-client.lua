package.path=package.path..';./?.lua'
require("chrome-devtools-client")

local connection = chrome_devtools.connect_to_chrome()

chrome_devtools.page_navigate(connection,
  "file:///home/horimoto/%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89/before.html")
chrome_devtools.close_to_chrome(connection)

connection = chrome_devtools.connect_to_chrome()
xml = chrome_devtools.translate_html_to_xml(connection)
print(xml)
chrome_devtools.close_to_chrome(connection)
