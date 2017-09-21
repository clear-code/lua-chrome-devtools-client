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

test_html_remove_office_p_tag()
test_remove_hyphen_from_single_line()
