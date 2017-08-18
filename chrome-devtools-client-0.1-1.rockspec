package = "chrome-devtools-client"
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
}
build = {
   type = "builtin",
   modules = {
      ["chrome-devtools-client"] = "chrome-devtools-client.lua"
   }
}
