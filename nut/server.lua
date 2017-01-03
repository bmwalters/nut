local nut_library_base = require("nut_library")

local NUTSERVER = {}

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

	local net = { Receivers = {}, _util = util }

	for k, v in pairs(nut_library_base) do
		if type(v) == "function" then
			net[k] = v
		end
	end

	net.Start = function(name)
		self._curmsgname = name
		self._writebuf = {}
		net._writebuf = self._writebuf
		net._writepos = 0
	end

	net.Send = function(clients)
		for _, client in pairs(clients) do
			self:SendClientMessage(self._curmsgname, self._writebuf)
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
		_curid = 1
	}, NUTSERVER)
end

return NutServer
