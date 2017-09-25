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

function test_remove_hyphen_from_single_line()
  test_data = {}
  expect_data = {}

  table.insert(test_data, "pre<!---comment--->post")

  table.insert(expect_data, "pre<!--comment-->post")

  local client = Client:new()
  for i = 1, #test_data do
     result = client:remove_hyphen_from_single_line(test_data[i])
     assert(expect_data[i] == result)
  end
end

function test_remove_hyphen_in_multi_line()
  test_data = {}
  expect_data = {}
  offset_data = {}

  table.insert(test_data, "pre-<!---comment\r\n-post")
  table.insert(test_data, "comment--->\r\n-post-")
  table.insert(test_data, "<!---keep---><!---\r\ncomment")
  table.insert(test_data, "-comment--->\r\n---keep--->")
  table.insert(test_data, "-comment--->\r\n---comment2--->")

  table.insert(expect_data, "pre-<!--comment\r\npost")
  table.insert(expect_data, "comment-->\r\n-post-")
  table.insert(expect_data, "<!---keep---><!--\r\ncomment")
  table.insert(expect_data, "comment-->\r\n---keep--->")
  table.insert(expect_data, "comment>\r\ncomment2-->")

  table.insert(offset_data, 1)
  table.insert(offset_data, 1)
  table.insert(offset_data, 12)
  table.insert(offset_data, 1)
  table.insert(offset_data, 11)

  local client = Client:new()
  for i = 1, #test_data do
    result = client:remove_hyphen_in_multi_line(test_data[i], offset_data[i])
    assert(expect_data[i] == result)
  end
end

function test_html_remove_double_hyphen()
  test_data = {}
  expect_data = {}

  table.insert(test_data, "<!----->\r\n")
  table.insert(test_data, "<!--\r\n-comment-\r\n-->\r\n")
  table.insert(test_data, "<!--\r\ncomment\r\n--><!---\r\ncomment2\r\n--->\r\n")

  table.insert(expect_data, "\r\n<!---->\r\n")
  table.insert(expect_data, "\r\n<!--\r\ncomment\r\n-->\r\n")
  table.insert(expect_data, "\r\n<!--\r\ncomment\r\n--><!--\r\ncomment2\r\n-->\r\n")

  local client = Client:new()
  for i = 1, #test_data do
    result = client:html_remove_double_hyphen(test_data[i])
--    result = client:html_remove_double_hyphen(test_data[1])
    --assert(expect_data[i] == result)
  end
end

--test_html_remove_office_p_tag()
--test_remove_hyphen_from_single_line()
--test_remove_hyphen_in_multi_line()
test_html_remove_double_hyphen()
