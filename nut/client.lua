local thispath = string.match(select("1", ...), ".+%.") or ""
local nut_library_base = require(thispath .. "nut_library")

local BitBuffer = require(thispath .. "bitbuf.bitbuf")

local socket = require("socket")
local copas = require("copas")

local NUTCLIENT = {}

NUTCLIENT.__index = NUTCLIENT

function NUTCLIENT:NetworkIDToString(id)
	return self._stringtable[id]
end

function NUTCLIENT:NetworkStringToID(str)
	return self._stringtoid[str] or 0
end

function NUTCLIENT:ReceiveStringTable(sock)
	local len = BitBuffer(sock:receive(3)):ReadUInt(24)
	local buffer = BitBuffer(sock:receive(len))

	local num_entries = buffer:ReadUInt(16)

	for _ = 1, num_entries do
		local id = buffer:ReadUInt(16)
		local name = buffer:ReadString()
		self._stringtable[id] = name
		self._stringtoid[name] = id
		print("Received string table entry", id, name)
	end
end

function NUTCLIENT:ConnectToServer(host, port)
	self._clientsocket = socket.connect(host, port)

	copas.connect(self._clientsocket, host, port)

	self:ReceiveStringTable(self._clientsocket)

	copas.addthread(function()
		copas.sleep(0)

		local datasize_buf = copas.receive(self._clientsocket, 2)
		if datasize_buf then
			local datasize = BitBuffer(datasize_buf):ReadUInt(16)
			local data = copas.receive(self._clientsocket, datasize)
			self:_OnMessageReceived(datasize, BitBuffer(data))
		end
	end)

	copas.loop()
end

function NUTCLIENT:CreateNetLibrary()
	local util = {
		NetworkIDToString = function(id)
			return self:NetworkIDToString(id)
		end,

		NetworkStringToID = function(str)
			return self:NetworkStringToID(str)
		end,
	}

	local net = { state = nut_library_base }

	net.state._util = util
	net.state.Receivers = {}

	for k, v in pairs(nut_library_base) do
		if type(v) == "function" and string.sub(k, 1, 4) ~= "Send" then
			net[k] = v
		end
	end

	net.Start = function(name)
		self._curmsgname = name
		net.state._writebuf = {}
		net.state._writepos = 0
	end

	function self:_OnMessageReceived(len, data_buf)
		net.state._readbuf = data_buf

		net.Incoming(len * 8) -- todo: accurate len?
	end

	net.Broadcast = nil

	net.SendToServer = function()
		self:SendServerMessage(net.state._writebuf)
	end

	return net, util
end

local function NutClient()
	return setmetatable({
		_stringtable = {},
		_stringtoid = {},
		_curid = 1
	}, NUTCLIENT)
end

return NutClient
