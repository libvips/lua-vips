# LuaVips 

A Lua binding for the libvips image processing library. This binding uses ffi
and needs luajit 2.0 or later. 

This binding works, but is not yet finished. See the issues. 

# Example

```lua
vips = require "vips"

image = vips.Image.text("Hello <i>World!</i>", {dpi = 300})
image = image:invert()
image:write_to_file("x.png")

image = vips.Image.thumbnail("somefile.jpg", 128)
image:write_to_file("tiny.jpg")
```

# Development

### Setup for ubuntu 17.04

You need to make your own luajit and luarocks that know about each other or
`busted` will not work. See this repo:

	git clone https://github.com/torch/luajit-rocks

Then 

	cd luajit-rocks
	mkdir build
	cd build/
	cmake .. -DCMAKE_INSTALL_PREFIX=/home/john/.luarocks -DWITH_LUAJIT21=ON
	make install

Configure `luarocks` for a local tree

	luarocks help path

append

	eval `luarocks path`
	export PATH="$HOME/.luarocks/bin:$PATH"

to `~/.bashrc`

### Install

	luarocks --local make

### Unit testing

You need:

	luarocks --local install busted 
	luarocks --local install luacov
	luarocks --local install say

Then to run the test suite:

    busted .

You seem to need the `.`, perhaps a problem with penlight?

### Test

Run the example script with:

	luajit example/hello-world.lua

### Links

	http://luajit.org/ext_ffi_api.html
	http://luajit.org/ext_ffi_semantics.html
	https://github.com/luarocks/luarocks/wiki/creating-a-rock
    https://olivinelabs.com/busted/

