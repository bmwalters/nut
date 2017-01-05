# nut
Nut is a Lua 5.3+ networking library designed for compatibility with [the `net` library](http://wiki.garrysmod.com/page/Net_Library_Usage) found in Garry's Mod.

## installation
This project depends on [LuaSocket](https://github.com/diegonehab/luasocket) and [Copas](https://github.com/keplerproject/copas) for networking, which can both be installed either manually or through [LuaRocks](https://luarocks.org/).

After installing the dependencies, stick the `nut` folder somewhere on your Lua [`package.path`](https://www.lua.org/manual/5.3/manual.html#pdf-package.path).
You can then `require("nut.client")` or `require("nut.server")` to your heart's content.

## usage
Nut provides two classes, NutClient and NutServer, which can be `require()`d from `nut/client.lua` and `nut/server.lua` respectively.

An example of using these classes is found in [my_client.lua](my_client.lua) and [my_server.lua](my_server.lua).
