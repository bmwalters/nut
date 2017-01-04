local thispath = string.match(select("1", ...), ".+%.") or ""
local nut_library_base = require(thispath .. "nut_library")

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

local function uint16tobuf(uint16)
	return string.char(uint16 >> 8) .. string.char(uint16 & tonumber("11111111", 2))
end

function NUTSERVER:SendClientStringTable(client)
	local num_entries = #self._stringtable

	copas.send(client, uint16tobuf(num_entries))

	for id = 1, num_entries do
		copas.send(client, uint16tobuf(id))
		local name = self._stringtable[id]
		copas.send(client, uint16tobuf(#name))
		copas.send(client, name)
	end
end

function NUTSERVER:SendClientMessage(client, writebuf)
	local len = #writebuf

	copas.send(client, uint16tobuf(len))

	local str = ""

	for _, byte in ipairs(writebuf) do
		str = str .. string.char(byte)
	end

	local sent, err = copas.send(client, str)
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

		net.state._writebuf = {}
		net.state._writepos = 0
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
