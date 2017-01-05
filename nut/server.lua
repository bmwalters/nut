local thispath = string.match(select("1", ...), ".+%.") or ""
local nut_library_base = require(thispath .. "nut_library")

local BitBuffer = require(thispath .. "bitbuf.bitbuf")

local socket = require("socket")
local copas = require("copas")

local NUTSERVER = {}

NUTSERVER.__index = NUTSERVER

function NUTSERVER:AddNetworkString(str)
	if self._stringtoid[str] then return self._stringtoid[str] end

	local id = self._curid

	self._stringtable[id] = str
	self._stringtoid[str] = id

	self._curid = id + 1

	return id
end

function NUTSERVER:NetworkIDToString(id)
	return self._stringtable[id]
end

function NUTSERVER:NetworkStringToID(str)
	return self._stringtoid[str] or 0
end

NUTSERVER.OnClientConnect = function() end

function NUTSERVER:Listen(host, port)
	self._serversocket = socket.bind(host, port)

	copas.addserver(self._serversocket, function(client)
		self._clients[#self._clients + 1] = client

		self:SendClientStringTable(client)

		self:OnClientConnect(client)

		while true do
			local data = copas.receive(client)

			if data then
				print("Client sent us data of length:", #data)
			end
		end
	end)

	copas.loop()
end

function NUTSERVER:SendClientStringTable(client)
	local num_entries = #self._stringtable

	local buffer = BitBuffer()

	buffer:WriteUInt(num_entries, 16)

	for id = 1, num_entries do
		buffer:WriteUInt(id, 16)
		buffer:WriteString(self._stringtable[id])
	end

	local lenstr = BitBuffer():WriteUInt(#buffer, 24):AsString()

	copas.send(client, lenstr .. buffer:AsString())
end

function NUTSERVER:SendClientMessage(client, writebuf)
	copas.send(client, BitBuffer():WriteUInt(#writebuf, 16):AsString())

	local sent, err = copas.send(client, writebuf:AsString())
	print("Sent message to", client, "message:", sent, "err:", err)
end

function NUTSERVER:CreateNetLibrary()
	local util = {
		AddNetworkString = function(name)
			self:AddNetworkString(name)
		end,

		NetworkIDToString = function(id)
			return self:NetworkIDToString(id)
		end,

		NetworkStringToID = function(str)
			return self:NetworkStringToID(str)
		end,
	}

	local net = { state = nut_library_base }

	net.state._util = util

	for k, v in pairs(nut_library_base) do
		if type(v) == "function" then
			net[k] = v
		end
	end

	net.Start = function(name)
		if not self._stringtoid[name] then
			error("Calling net.Start with unpooled message name [http://goo.gl/qcx0y]")
		end

		net.state._writebuf = BitBuffer()
		net.state.Receivers = {}

		net.WriteUInt(self._stringtoid[name], 16)
	end

	function self:_OnMessageReceived(len, client)
		net.Incoming(len, client)
	end

	net.Send = function(clients)
		for _, client in pairs(clients) do
			self:SendClientMessage(client, net.state._writebuf)
		end
	end

	net.Broadcast = function()
		net.Send(self._clients)
	end

	net.SendToServer = nil

	return net, util
end

local function NutServer()
	return setmetatable({
		_stringtable = {},
		_stringtoid = {},
		_curid = 1,
		_clients = {}
	}, NUTSERVER)
end

return NutServer
