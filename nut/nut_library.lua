local TYPE = require("enum.type")

local nut = { Receivers = {} }

-- receiving

function nut.Receive(name, func)
	nut.Receivers[string.lower(name)] = func
end

function nut.ReadHeader()
	return nut.ReadUInt(16)
end

function nut.Incoming(len, client)
	local id = nut.ReadHeader()

	local name = nut._util.NetworkIDToString(id)

	if not name then return end

	local func = nut.Receivers[name]

	if func then
		-- len includes the 16 bit int which told us the message name
		func(len - 16, client)
	end
end

-- sending

function nut.BytesWritten()
	return #nut._writebuf
end

-- these are set by the nut server/client
-- see server/client:CreateNetLibrary

function nut.Start(name)
	error("Not Configured")
end

function nut.Send(clients)
	error("Not Configured")
end

function nut.SendToServer()
	error("Not Configured")
end

function nut.Broadcast()
	error("Not Configured")
end

function nut.SendOmit()
	error("Not Implemented")
end

function nut.SendPAS()
	error("Not Implemented")
end

function nut.SendPVS()
	error("Not Implemented")
end

-- type reading/writing functions

local function first_n_bits(num, bits)
	return num >> math.max(math.ceil(math.log(num, 2)) - bits, 0)
end

function nut.ReadUInt(bits)
	local bits_remaining = bits

	local num = 0

	while bits_remaining > 0 do
		local curbyte = nut._readpos // 8
		local bits_remaining_in_curbyte = 8 - (nut._readpos % 8)

		local num_bits_to_read = math.min(bits_remaining_in_curbyte, bits_remaining)

		local truncate_to = (8 - (nut._readpos % 8))
		local read_bits = (nut._readbuf[curbyte + 1] & (2 ^ truncate_to - 1)) >> (truncate_to - num_bits_to_read)

		num = (num << num_bits_to_read) | read_bits
		bits_remaining = bits_remaining - num_bits_to_read
		nut._readpos = nut._readpos + num_bits_to_read
	end

	return num
end

function nut.WriteUInt(uint, bits)
	local bits_remaining = bits

	while bits_remaining > 0 do
		local curbyte = nut._writepos // 8
		local bits_remaining_in_curbyte = 8 - (nut._writepos % 8)

		local num_bits_to_add = math.min(bits_remaining_in_curbyte, bits_remaining)

		local bits_to_write = uint >> (bits_remaining - num_bits_to_write)

		nut._writebuf[curbyte + 1] = (nut._writebuf[curbyte + 1] or 0) | (bits_to_write << (8 - num_bits_to_write - (nut._writepos % 8)))

		uint = uint & (2 ^ (bits_remaining - num_bits_to_write) - 1)
		bits_remaining = bits_remaining - num_bits_to_write
		nut._writepos = nut._writepos + num_bits_to_write
	end
end

function nut.ReadInt(bits)
	local sign = nut.ReadUInt(1)
	local num = nut.ReadUInt(bits - 1)
	if sign == 1 then num = -num end
	return num
end

function nut.WriteInt(int, bits)
	nut.WriteUInt((int < 0) and 1 or 0, 1)
	nut.WriteUInt(math.abs(int), bits - 1)
end

function nut.ReadFloat()
	error("Not Implemented")
end

function nut.WriteFloat(float)
	error("Not Implemented")
end

function nut.ReadDouble()
	error("Not Implemented")
end

function nut.WriteDouble(double)
	error("Not Implemented")
end

function nut.ReadBit()
	return nut.ReadUInt(1)
end

function nut.WriteBit(bool_or_bit)
	if bool_or_bit == false or bool_or_bit == 0 then
		nut.WriteUInt(0, 1)
	else
		nut.WriteUInt(1, 1)
	end
end

function nut.ReadBool()
	return nut.ReadBit() == 1
end

function nut.WriteBool(bool)
	nut.WriteBit(bool and 1 or 0)
end

function nut.ReadString()
	local s = ""
	local c = nut.ReadUInt(8)

	while c ~= 0 do
		s = s .. string.char(c)
		c = nut.ReadUInt(8)
	end

	return s
end

function nut.WriteString(str)
	for i = 1, #str do
		nut.WriteUInt(string.byte(string.sub(str, i, i)), 8)
	end

	nut.WriteUInt(0, 8)
end

local typefuncs = {
	[TYPE.NIL]    = { function() end, function() end },
	[TYPE.STRING] = { nut.ReadString, nut.WriteString },
	[TYPE.NUMBER] = { nut.ReadDouble, nut.WriteDouble },
	[TYPE.TABLE]  = { nut.ReadTable, nut.WriteTable },
	[TYPE.BOOL]   = { nut.ReadBool, nut.WriteBool },
	[TYPE.ENTITY] = { nut.ReadEntity, nut.WriteEntity },
	[TYPE.VECTOR] = { nut.ReadVector, nut.WriteVector },
	[TYPE.ANGLE]  = { nut.ReadAngle, nut.WriteAngle },
	[TYPE.MATRIX] = { nut.ReadMatrix, nut.WriteMatrix },
	[TYPE.COLOR]  = { nut.ReadColor, nut.WriteColor },
}

function nut.ReadType(typeid)
	typeid = typeid or nut.ReadUInt(8)

	local readfunc = (typefuncs[typeid] or {})[1]

	if readfunc then
		return readfunc()
	else
		error("net.ReadType: Couldn't read type " .. typeid)
	end
end

function nut.WriteType(data)
	local typeid = TypeID(data)

	local writefunc = (typefuncs[typeid] or {})[2]

	if writefunc then
		nut.WriteUInt(typeid, 8)
		writefunc(data)
	else
		error("net.WriteType: Couldn't write " .. type(data) .. " (type " .. typeid .. ")")
	end
end

function nut.ReadTable()
	local tab = {}

	local key = nut.ReadType()

	while key do
		tab[key] = nut.ReadType()
		key = nut.ReadType()
	end

	return tab
end

function nut.WriteTable(data)
	for k, v in pairs(tab) do
		nut.WriteType(k)
		nut.WriteType(v)
	end

	nut.WriteType(nil)
end

function nut.ReadEntity()
	error("Not Implemented")
end

function nut.WriteEntity(ent)
	error("Not Implemented")
end

function nut.ReadVector()
	error("Not Implemented")
end

function nut.WriteVector(data)
	error("Not Implemented")
end

function nut.ReadAngle()
	error("Not Implemented")
end

function nut.WriteAngle(data)
	error("Not Implemented")
end

function nut.ReadMatrix()
	error("Not Implemented")
end

function nut.WriteMatrix(data)
	error("Not Implemented")
end

function nut.ReadNormal()
	error("Not Implemented")
end

function nut.WriteNormal(data)
	error("Not Implemented")
end

function nut.ReadColor()
	error("Not Implemented")
end

function nut.WriteColor(color)
	error("Not Implemented")
end

function nut.ReadData()
	error("Not Implemented")
end

function nut.WriteData(data)
	error("Not Implemented")
end

return nut
