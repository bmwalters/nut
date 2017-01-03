local nut_library_base = require("nut_library")

local NUTCLIENT = {}

function NUTCLIENT:NetworkIDToString(id)
	return self._stringtable[id]
end

function NUTCLIENT:NetworkStringToID(str)
	return self._stringtoid[str] or 0
end

function NUTCLIENT:ConnectToSurver(host, port)
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

	local net = { Receivers = {}, _util = util }

	for k, v in pairs(nut_library_base) do
		if type(v) == "function" and string.sub(k, 1, 4) ~= "Send" then
			net[k] = v
		end
	end

	net.Start = function(name)
		self._curmsgname = name
		self._writebuf = {}
		net._writebuf = self._writebuf
		net._writepos = 0
	end

	net.Broadcast = nil

	net.SendToServer = function()
		self:SendServerMessage(self._curmsgname, self._writebuf)
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
