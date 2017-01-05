local NutClient = require("nut.client")

local myclient = NutClient()

local net, util = myclient:CreateNetLibrary()

-- gmod compatible code

net.Receive("test_broadcast", function(len)
	print("Received test broadcast from server with len: ", len)
	print("Received: ", net.ReadType())
	print("Received: ", net.ReadType())
	print("Received: ", net.ReadType())
	print("Received: ", net.ReadType())
end)

-- now start the loop

myclient:ConnectToServer("localhost", 6969)
