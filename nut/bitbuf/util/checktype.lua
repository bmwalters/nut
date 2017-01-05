local errfmt = "bad argument #%i to '%s' (%s expected, got %s)"

return function(func, index, expected, data)
	local got = type(data)
	if got ~= expected then
		error(errfmt:format(index, func, expected, got), 3)
	end
end
