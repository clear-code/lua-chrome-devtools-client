package = "postgresql-client"
version = "0.1-1"
source = {
   url = "https://github.com/clear-code/lua-chrome-devtools-client"
}
description = {
  homepage = "https://github.com/clear-code/lua-chrome-devtools-client",
  maintainer = "Yasuhiro Horimoto <horimoto@clear-code.com>",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1",
  "pgmoon-mashape"
}
build = {
   type = "builtin",
   modules = {
      ["postgresql-client"] = "postgresql-client.lua"
   }
}
