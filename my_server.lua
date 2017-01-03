local NutServer = require("nut.server")

local myserver = NutServer()

local net, util = myserver:CreateNetLibrary()

myserver:Listen(6969)

function myserver:OnClientConnect(client)
	print("Client connect", client)
	test_broadcast()
end

-- from here on out is gmod compatible code

util.AddNetworkString("test_broadcast")

function test_broadcast()
	net.Start("test_broadcast")
		net.WriteUInt(42, 8)
	net.Broadcast()
end
