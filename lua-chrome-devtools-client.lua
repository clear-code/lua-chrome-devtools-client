package.path=package.path..';./?.lua'
require("chrome-devtools-client")

chrome_devtools.connect_to_chrome("localhost")

chrome_devtools.page_navigate(
  "file:///home/horimoto/%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89/before.html")
chrome_devtools.close_to_chrome()

chrome_devtools.connect_to_chrome("localhost")
xml = chrome_devtools.translate_html_to_xml()
print(xml)
chrome_devtools.close_to_chrome()
