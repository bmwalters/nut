local NutServer = require("nut.server")

local myserver = NutServer()

local net, util = myserver:CreateNetLibrary()

function myserver:OnClientConnect(client)
	print("Client connect", client)
	test_broadcast()
end

-- gmod compatible code

util.AddNetworkString("test_broadcast")

function test_broadcast()
	net.Start("test_broadcast")
		net.WriteType({ dog = "cat" })
		net.WriteType("Hello World")
		net.WriteType(nil)
		net.WriteType(true)
	net.Broadcast()
end

-- now start the loop

myserver:Listen("localhost", 6969)
