Chrome DevTools client for Lua 5.x
==================================
This module is connect to Chrome with chrome devtools protocol.


LuaRocks Installation
---------------------
`luarocks install chrome-devtools-client`

Dependency
----------
- lua-cjson
- http
- luasocket

Usage
-----
API List:

- `connect`
- `close`
- `page_navigate`
- `translate_html_to_xml`

### `connect`

#### Examples
```lua
local connection = chrome_devtools.connect("localhost")
```

### `close`

#### Examples
```lua
local connection = chrome_devtools.connect()
chrome_devtools.close(connection)
```

### `page_navigate`

#### Examples
```lua
local connection = chrome_devtools.connect_to_chrome()
connection:page_navigate("file:///tmp/test.html")
chrome_devtools.close(connection)
```

### `translate_html_to_xml`

#### Examples
```lua
local connection = chrome_devtools.connect_to_chrome()
xml = connection:translate_html_to_xml()
print(xml)
chrome_devtools.close(connection)
```

License(MIT)
-------
Copyright(C) 2017 by Yasuhiro Horimoto

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
