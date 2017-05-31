# lua-vips 

A Lua binding for the libvips image processing library. This binding uses ffi
and needs luajit 2.0 or later. 

libvips is a fast image processing library with low memory needs. See:

http://jcupitt.github.io/libvips

This binding works and has a fairly complete test-suite which it passes with no 
errors or leaks, but is not yet documented. See the issues.

# Example

```lua
vips = require "vips"

image = vips.Image.text("Hello <i>World!</i>", {dpi = 300})

-- call a method
image = image:invert()

-- make a three band image with ..
image = image .. image .. image

-- add a constant
image = image + 12
-- add a different value to each band
image = image + {1, 2, 3}
-- add two images
image = image + image

-- split bands up again
b1, b2, b3 = image:bandsplit()

-- read a pixel from coordinate (10, 20)
r, g, b = image(10, 20)

-- make all pixels less than 128 bright blue
image = image:less(128):ifthenelse({0, 0, 255}, image)

image:write_to_file("x.png")

-- fast thumbnail generator
image = vips.Image.thumbnail("somefile.jpg", 128)
image:write_to_file("tiny.jpg")
```

# How it works

libvips has quite a bit of introspection machinery built in. This Lua binding
opens the vips library with ffi and uses these introspection facilities to build
a complete binding at runtime. 

It uses `__index` to call into libvips, so `image:hough_circle()`, for example,
will perform a Hough transform, even though this binding knows nothing about
the `hough_circle` operator. 

This means this binding is small and very simple to maintain. It will expand
automatically as features are added to libvips. 

You can also use the standard libvips docs directly, see:

http://jcupitt.github.io/libvips/API/current/

# Development

### Setup for ubuntu 17.04

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

	(cd spec; for i in *_spec.lua; do luajit $i; done)

You can't do `busted .`, unfortunately, since busted `fork()`s between files
and this breaks luajit ffi (I think).

### Test

Run the example script with:

	luajit example/hello-world.lua

### Links

	http://luajit.org/ext_ffi_api.html
	http://luajit.org/ext_ffi_semantics.html
	https://github.com/luarocks/luarocks/wiki/creating-a-rock
	https://olivinelabs.com/busted/

