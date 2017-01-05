local thispath = string.match(select("1", ...), ".+%.") or ""
local TYPE = require(thispath .. "enum.type")

local typestringtoid = {
	["nil"] = TYPE.NIL,
	boolean = TYPE.BOOL,
	string = TYPE.STRING,
	thread = TYPE.THREAD,
	userdata = TYPE.USERDATA,
	number = TYPE.NUMBER,
	table = TYPE.TABLE,
	["function"] = TYPE.FUNCTION,
}

return function(data)
	local typestring = type(data)

	if typestringtoid[typestring] then
		return typestringtoid[typestring]
	end
end
