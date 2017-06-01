# lua-vips 

A Lua binding for the libvips image processing library. This binding uses ffi
and needs luajit 2.0 or later. 

libvips is a fast image processing library with low memory needs. See:

[http://jcupitt.github.io/libvips](http://jcupitt.github.io/libvips)

For a benchmark, see:

[https://github.com/jcupitt/lua-vips-bench](https://github.com/jcupitt/lua-vips-bench)

This binding works and has a fairly complete test-suite which it passes with no 
errors or leaks. 

See the libvips API documentation for more information --- lua-vips binds the
whole of libvips, so you can use anything in there:

[http://jcupitt.github.io/libvips/API/current/](http://jcupitt.github.io/libvips/API/current/)

Notes below introduce the general features of this binding.

# Example

Install with
	
	luarocks install lua-vips

Then:

```lua
vips = require "vips"

image = vips.Image.text("Hello <i>World!</i>", {dpi = 300})

-- call a method
image = image:invert()

-- use the `..` operator to join images bandwise
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

-- go to Yxy colourspace
image = image:colourspace("yxy")

image:write_to_file("x.png")

-- fast thumbnail generator
image = vips.Image.thumbnail("somefile.jpg", 128)
image:write_to_file("tiny.jpg")
```

If it doesn't work, check that you have the libvips shared library on your
system, and that luajit can find it. 

# How it works

libvips has quite a bit of introspection machinery built in. This Lua binding
opens the vips library with ffi and uses these introspection facilities to build
a complete binding at runtime. 

It uses `__index` to call into libvips, so `image:hough_circle()`, for example,
will perform a Hough transform, even though this binding knows nothing about
the `hough_circle` operator. 

This means this binding is small and simple to maintain. It will expand
automatically as features are added to libvips. 

# Features

This section runs through the main features of the binding. To load the binding
use:

```lua
vips = require "vips"
```

## Make images

You can make images from files or from memory buffers (Lua strings), or you can
use one of the libvips create operators to make an image for you. 

### `vips.Image.new_from_file(filename [, options])`

Opens the file and returns an image. You can pass a set of options in a final
table argument, for example:

```lua
local image = vips.Image.new_from_file("somefile.jpg", {access = "sequential"})
```

Some options are specific to some file types, for example, `shrink`, meaning
shrink by an integer factor during load, only applies to images loaded via
libjpeg.

You can call specific file format loaders directly, for example:

```lua
lyocal image = vips.Image.jpegload("somefile.jpg", {shrink = 4})
```

See the API docs for information on all the loaders:

[http://jcupitt.github.io/libvips/API/current/VipsForeignSave.html](http://jcupitt.github.io/libvips/API/current/VipsForeignSave.html)

A simple way to see the arguments for a loader is to try running it from the
command-line. Try:

```bash
$ vips jpegload
load jpeg from file
usage:
   jpegload filename out
where:
   filename     - Filename to load from, input gchararray
   out          - Output image, output VipsImage
optional arguments:
   flags        - Flags for this file, output VipsForeignFlags
   disc         - Open to disc, input gboolean
			default: true
   access       - Required access pattern for this file, input VipsAccess
			default: random
			allowed: random, sequential, sequential-unbuffered
   shrink       - Shrink factor on load, input gint
			default: 1
			min: 1, max: 16
   fail         - Fail on first error, input gboolean
			default: false
   autorotate   - Rotate image using exif orientation, input gboolean
			default: false
```

### `vips.Image.new_from_buffer(string [, options])`

The string argument should contain an image file in some container format, such
as JPEG. You can supply options, just as with `new_from_file`. Use (for
example) `vips.Image.jpegload_buffer` to call a loader directly.

### `vips.Image.new_from_image(image, pixel)`

Makes a new image with the size, format, and resoluion of `image`, but with
each pixel having the value `pixel`. For example:

```lua
local new_image = vips.Image.new_from_image(image, 12)
```

Will make a new image with one band where every pixel has the value 12. You can
call it as a member function. `pixel` can be a table to make a many-band image,
for example:

```lua
local new_image = image:new_from_image({1, 2, 3})
```

Will make a new three-band image, where all the red pixels have the value 1,
greens are 2 and blues are 3.

### `vips.Image.new_from_array(array [, scale, offset])`

Makes a new image from a Lua array (or table). For example:

```lua
local image = vips.Image.new_from_array({1, 2, 3})
```

Makes a one-band image, three pixels across and one high. Use nested tables for
2D images. You can set a scale and offset with two extra number parameters,
which is handy for integer convolution masks.

```lua
local mask = vips.Image.new_from_array(
    {{-1,  -1, -1}, 
     {-1,  16, -1}, 
     {-1,  -1, -1}}, 8)
local image = image:conv(mask, {precision = "integer"})
```

### `vips.Image.black(width, height)`

Makes a new one band, 8 bit, black image. You can call any of the libvips image
creation operators in this way, for example:

```lua
local noise = vips.Image.perlin(256, 256, {cell_size = 128})
```

See:

[http://jcupitt.github.io/libvips/API/current/libvips-create.html](http://jcupitt.github.io/libvips/API/current/libvips-create.html)

## Get and set image metadata

## Call any libvips operation

You can call any libvips operation as a member function, for example
`hough_circle`, the circular Hough transform:

[http://jcupitt.github.io/libvips/API/current/libvips-arithmetic.html#vips-hough-circle](http://jcupitt.github.io/libvips/API/current/libvips-arithmetic.html#vips-hough-circle)

Can be called from Lua like this:

```lua
local image2 = image:hough_circle({scale = 2, max_radius = 50})
```

The rules are:

1. `self` is used to set the first required input image argument.

2. If you supply one more argument than the number of required arguments, 
   and the final argument you supply is a table, 
   that extra table is used to set any optional input arguments. 

3. If you supply a constant (a number, of a table of numbers) and libvips 
   wants an image, your constant is automatically turned into an image using
   the first input image you supplied as a guide. 

4. For enums, you can supply a number or a string. The string is an enum member
   nickname (the part after the final underscore).

5. Operation results are returned as an unpacked array in the order: all
   required output args, then all optional output args, then all deprecated
   output args.

You can write (for example):

```lua
max_value = image:max()
```

To get the maximum value from an image. If you look at the `max` operator, it
can actually return a lot more than this. You can write:

```lua
max_value, x, y = image:max()
```

To get the position of the maximum, or:

```lua
max_value, x, y, maxes = image:max({size = 10})
```

and maxes will be an array of the top 10 maximum values in order. 

## Operator overloads

The Lua operators are overloaded in the obvious way, so you can write (for
example):

```lua
image = (image * 2 + 13) % 4
```

and the appropriate vips operations will be called. You can mix images, number
constants, and array constants freely.

The relational operators are not overloaded, unfortunately, Lua does not
permit this. You must write something like:

```lua
image = image:less(128):ifthenelse(128, image)
```

to set all pixels less than 128 to 128.

`__call` (ie. `()`) is overloaded to call the libvips `getpoint` operator. 
You can write:

```lua
image = vips.Image.new_from_file("k2.jpg")
r, g, b = image(10, 10)
```

the RGB values for the pixel at coordinate (10, 10).

`..` is overloaded to mean `bandjoin`. 

`#` is overloaded to get the number of bands in an image, although this seems
to only work with LuaJIT 2.1.

`[]` ought to mean `extract_band`, but it's not working.

## Convenience functions

A set of convenience functions are also defined.

### `image:bandsplit()`

This splits a many-band image into an array of one band images.

### `image:bandjoin()`

The `bandjoin` operator takes an array of images as input. This can be awkward
to call --- you must write:


```lua
image = vips.Image.bandjoin({image, image})
```

to join an image to itself. Instead, lua-vips defines `bandjoin` as a member
function, so you write:

```lua
image = image:bandjoin(image)
```

to join an image to itself, or perhaps:

```lua
image = R:bandjoin({G, B})
```

to join three RGB bands. 

The `bandrank` operator works in the same way. 

### `condition_image:ifthenelse(then_image, else_image [, options])`

This uses the condition image to pick pixels between then and else. Unlike all
other operators, if you use a constant for `then_image` or `else_image`, they
first match to each other, and only match to the condition image if both then
and else are constants. 

### `image:sin()`

Many vips arithmetic operators are implemented by larger operators which take
an enum to set their action. For example, sine is implemented by the `math`
operator, so you must write:

```lua
image = image:math("sin")
```

This is annoying, so a set of convenience functions are defined to enable you
to write:

```lua
image = image:sin()
```

There are about 40 of these. 

## Write

You can write images to files or to formatted strings. 

### `image:write_to_file(filename [, options])`

The filename suffix is used to pick the save operator. Just as with 
`new_from_file`, not all options will be correct for all file
types. You can call savers directly if you wish, for example:

```lua
image:jpegsave("x.jpg", {Q = 90})
```

### `image:write_to_buffer(suffix [, options])`

The suffix is used to pick the saver that is used to generate the result, so
`".jpg"` will make a JPEG-formatted string. Again, you can call the savers
directly if you wish, perhaps:

```lua
local str = image:jpegsave_buffer({Q = 90})
```

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
and this breaks luajit GC with ffi (I think).

### Test

Run the example script with:

	luajit example/hello-world.lua

### Update rock
	
	luarocks upload lua-vips-0.1-1.rockspec --api-key=xxxxxxxxxxxxxx

### Links

	http://luajit.org/ext_ffi_api.html
	http://luajit.org/ext_ffi_semantics.html
	https://github.com/luarocks/luarocks/wiki/creating-a-rock
	https://olivinelabs.com/busted/

