require("chrome-devtools-client")

local client = Client:new()
print(client.get_version())
