package = "lua-chrome-devtools-client"
version = "0.1-1"
source = {
   url = "git://github.com/clear-code/lua-chrome-devtools-client"
}
description = {
   homepage = "https://github.com/clear-code/lua-chrome-devtools-client",
   maintainer = "Yasuhiro Horimoto <horimoto@clear-code.com>",
   license = "MIT"
}
dependencies = {
  "lua >= 5.1",
  "lua-cjson",
  "http",
  "luasocket"
}
build = {
   type = "builtin",
   modules = {
      ["lua-chrome-devtools-client"] = "lua-chrome-devtools-client.lua"
   }
}
