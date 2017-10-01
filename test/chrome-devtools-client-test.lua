package.path = package.path..";../?.lua"
require("chrome-devtools-client")

function test_html_remove_office_p_tag()
  test_data = {}
  expect_data = {}

  table.insert(test_data, "<o:p hogehoge /o:p>")
  table.insert(test_data, "<o:phogehoge/o:p>")
  table.insert(test_data, "<o:p  /o:p>")
  table.insert(test_data, "<o:p/o:p>")

  table.insert(expect_data, "<p hogehoge /p>")
  table.insert(expect_data, "<phogehoge/p>")
  table.insert(expect_data, "<p  /p>")
  table.insert(expect_data, "<p/p>")

  local client = Client:new()
  for i = 1, #test_data do
    assert(expect_data[i] ==
           client:html_remove_office_p_tag(test_data[i]))
  end
end

function test_html_remove_double_hyphen()
  test_data = {}
  expect_data = {}

  table.insert(test_data, "<!---->")
  table.insert(test_data, "<!----->")
  table.insert(test_data, "<!------>")
  table.insert(test_data, "<!-- -- -->")
  table.insert(test_data, "<!-- <!-- --> -->")
  table.insert(test_data, "abc<!-- <!-- --> -->b<!-- -- -->c")


  table.insert(expect_data, "<!---->")
  table.insert(expect_data, "<!---->")
  table.insert(expect_data, "<!---->")
  table.insert(expect_data, "<!-- - -->")
  table.insert(expect_data, "<!-- <!- -> -->")
  table.insert(expect_data, "abc<!-- <!- -> -->b<!-- - -->c")

  local client = Client:new()
  for i = 1, #test_data do
    result = client:html_remove_double_hyphen(test_data[i])
    assert(expect_data[i] == result, "\nresult="..result.."\nexpect="..expect_data[i])
  end
end

function test_html_remove_invalid_attribute_name()
  test_data = {}
  expect_data = {}

  table.insert(test_data, "<meta data=\"hoge\"> 0\"=\"\" <img src=\"/tmp/hoge/test.html\"/>")
  table.insert(test_data, "<meta data=\"hoge\"> 0123ABC\"=\"\" <img src=\"/tmp/hoge/test.html\"/>")
  table.insert(test_data, "<meta data=\"hoge\"> 0123ABC\"=\"\" <img\nsrc=\"/tmp/hoge/test.html\"/>")
  table.insert(test_data, "<meta data=\"hoge\"> 0123ABC\"=\"\" <img\r\nsrc=\"/tmp/hoge/test.html\"/>")
  table.insert(test_data, "<meta data=\"hoge\"> 0123ABC\"=\"\" <imgsrc=\"/tmp/hoge/test.html\"/>")

  table.insert(expect_data, "<meta data=\"hoge\"> <img src=\"/tmp/hoge/test.html\"/>")
  table.insert(expect_data, "<meta data=\"hoge\"> <img src=\"/tmp/hoge/test.html\"/>")
  table.insert(expect_data, "<meta data=\"hoge\"> <img src=\"/tmp/hoge/test.html\"/>")
  table.insert(expect_data, "<meta data=\"hoge\"> <img src=\"/tmp/hoge/test.html\"/>")
  table.insert(expect_data, "<meta data=\"hoge\"> <img src=\"/tmp/hoge/test.html\"/>")

  local client = Client:new()
  for i = 1, #test_data do
    result = client:html_remove_invalid_attribute_name(test_data[i])
    assert(expect_data[i] == result, "\nresult="..result.."\nexpect="..expect_data[i])
  end
end

function test_capture_screenshot()
  local connect_ip = "localhost"
  local connect_port = "9222"

  local client = Client:new()
  client:connect(connect_ip, connect_port)

  client:page_navigate("https://www.google.co.jp/")

  local capture_img = client:capture_screenshot()
  assert(capture_img, "\nscreenshot is failes:result="..capture_img)
end

test_html_remove_office_p_tag()
test_html_remove_double_hyphen()
test_html_remove_invalid_attribute_name()
test_capture_screenshot()
