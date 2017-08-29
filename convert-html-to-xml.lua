require("chrome-devtools-client")
require("postgresql-client")

local connect_ip = "localhost"
local connect_port = "9222"

local client = Client:new()
client:connect(connect_ip, connect_port)

local fd = io.open(arg[2], "r")
local html = fd:read("*all")
fd:close()

xml = client:convert_html_to_xml(html)
client:close()

local pgclient = PGClient:new()
pgclient:save_xml(arg[1], xml, arg[2])
