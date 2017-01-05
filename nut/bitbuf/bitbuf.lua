local thispath = string.match(select("1", ...), ".+%.") or ""
local checktype = require(thispath .. "util.checktype")

local READBUFFER = {}
READBUFFER.__index = READBUFFER

local WRITEBUFFER = {}
WRITEBUFFER.__index = WRITEBUFFER

function READBUFFER:__len()
	return #self._data
end

WRITEBUFFER.__len = READBUFFER.__len

function READBUFFER:AsString()
	local str = ""

	for i = 1, #self._data do
		str = str .. string.char(self._data[i])
	end

	return str
end

WRITEBUFFER.AsString = READBUFFER.AsString

function WRITEBUFFER:WriteUInt(uint, bits)
	checktype("WriteUInt", 1, "number", uint)
	checktype("WriteUInt", 2, "number", bits)

	local bits_remaining = bits

	while bits_remaining > 0 do
		local curbyte = self._pos // 8
		local bits_remaining_in_curbyte = 8 - (self._pos % 8)

		local num_bits_to_write = math.min(bits_remaining_in_curbyte, bits_remaining)

		local bits_to_write = uint >> (bits_remaining - num_bits_to_write)

		self._data[curbyte + 1] = (self._data[curbyte + 1] or 0) | (bits_to_write << (8 - num_bits_to_write - (self._pos % 8)))

		uint = uint & (2 ^ (bits_remaining - num_bits_to_write) - 1)
		bits_remaining = bits_remaining - num_bits_to_write
		self._pos = self._pos + num_bits_to_write
	end

	return self
end

function READBUFFER:ReadUInt(bits)
	checktype("ReadUInt", 1, "number", bits)

	local bits_remaining = bits

	local num = 0

	while bits_remaining > 0 do
		local curbyte = self._pos // 8
		local bits_remaining_in_curbyte = 8 - (self._pos % 8)

		local num_bits_to_read = math.min(bits_remaining_in_curbyte, bits_remaining)

		local truncate_to = (8 - (self._pos % 8))
		local read_bits = (self._data[curbyte + 1] & (2 ^ truncate_to - 1)) >> (truncate_to - num_bits_to_read)

		num = (num << num_bits_to_read) | read_bits
		bits_remaining = bits_remaining - num_bits_to_read
		self._pos = self._pos + num_bits_to_read
	end

	return num
end

function WRITEBUFFER:WriteInt(int, bits)
	checktype("WriteInt", 1, "number", int)
	checktype("WriteInt", 2, "number", bits)

	self:WriteUInt((int < 0) and 1 or 0, 1)
	self:WriteUInt(math.abs(int), bits - 1)

	return self
end

function READBUFFER:ReadInt(bits)
	checktype("ReadInt", 1, "number", bits)

	local sign = self:ReadUInt(1)
	local num = self:ReadUInt(bits - 1)
	if sign == 1 then num = -num end
	return num
end

function WRITEBUFFER:WriteBit(bit)
	checktype("WriteBit", 1, "number", bit)

	self:WriteUInt(bit, 1)

	return self
end

function READBUFFER:ReadBit()
	return self:ReadUInt(1)
end

function WRITEBUFFER:WriteFloat(float)
	error("Not Implemented")
end

function READBUFFER:ReadFloat()
	error("Not Implemented")
end

function WRITEBUFFER:WriteDouble(double)
	error("Not Implemented")
end

function READBUFFER:ReadDouble()
	error("Not Implemented")
end

-- todo: should there be string reading/writing funcs?
function WRITEBUFFER:WriteString(str)
	checktype("WriteString", 1, "string", str)

	for i = 1, #str do
		self:WriteUInt(string.byte(string.sub(str, i, i)), 8)
	end

	self:WriteUInt(0, 8)

	return self
end

function READBUFFER:ReadString()
	if self._writable then error("attempt to read from write buffer", 1) end

	local s = ""
	local c = self:ReadUInt(8)

	while c ~= 0 do
		s = s .. string.char(c)
		c = self:ReadUInt(8)
	end

	return s
end

return function(data)
	local obj = { _data = data or {}, _pos = 0 }

	if data and type(data) == "string" then
		obj._data = { string.byte(data, 1, #data) }
	end

	return setmetatable(obj, data and READBUFFER or WRITEBUFFER)
end
