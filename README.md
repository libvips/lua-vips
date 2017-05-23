# LuaVips 

A Lua binding for the libvips image processing library. This binding uses ffi
and needs luajit 2.0 or later. 

This binding works, but is not yet finished. See the issues. 

# Example

```lua
vips = require "vips"

image = vips.image.text("Hello <i>World!</i>", {dpi = 300})
image = image:invert()
image:write_to_file("x.png")

image = vips.image.thumbnail("somefile.jpg", 128)
image:write_to_file("tiny.jpg")
```

# Development

### Setup for ubuntu 17.04

Add packages

	sudo apt-get install luajit luarocks libcurl4-openssl-dev 

Configure `luarocks` for a local tree

	luarocks help path

add

	eval `luarocks path`

to `~/.bashrc`

### Install

	luarocks --local make

### Test

Run the example script with:

	luajit example/hello-world.lua

### Links

	http://luajit.org/ext_ffi_api.html
	http://luajit.org/ext_ffi_semantics.html
	https://github.com/luarocks/luarocks/wiki/creating-a-rock
