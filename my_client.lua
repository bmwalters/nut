local NutClient = require("nut.client")

local myclient = NutClient()

local net, util = myclient:CreateNetLibrary()

myclient:ConnectToServer("localhost", 6969)

-- from here on out is gmod compatible code

net.Receive("test_broadcast", function(len)
	print("Received test broadcast from server with len: ", len)
	print("Received uint: ", net.ReadUInt(8))
end)
