# lua-vips

[![CI](https://github.com/libvips/lua-vips/workflows/CI/badge.svg)](https://github.com/libvips/lua-vips/actions)

This is a Lua binding for the [libvips image processing
library](http://libvips.github.io/libvips).  `libvips`
is a [fast image processing library with low memory needs](https://github.com/jcupitt/lua-vips-bench).
`lua-vips` uses ffi and needs either
- luajit >= 2.0 or
- standard Lua (5.1 up to 5.4) combined with the [`luaffi-tkl`](https://luarocks.org/modules/sudheerhebbale/luaffi-tkl) Lua package.

On the x64 architecture `lua-vips` is continuously tested
- on Linux and MacOS with Lua 5.1, 5.2, 5.3, 5.4 and openresty-luajit
- on Windows using [MSYS2 MinGW-w64](https://www.msys2.org/) with Lua 5.3, 5.4 and luajit

`lua-vips`  should work on arm64 (recently tested on a Pinephone Pro using PostmarketOS) and possibly x86 (currently untested)
as well.

The libvips documentation includes a handy searchable table of [every operation in
libvips](http://libvips.github.io/libvips/API/current/func-list.html). This
is a good place to check if it supports some feature you need. Read on to
see how to call libvips operations.

# Example

[Install the libvips shared
library](https://libvips.github.io/libvips/install.html), then install this rock with:
	
```shell
luarocks install lua-vips
```

When used with LuaJIT please first exhibit luaffi-tkl as provided by the VM via:
```shell
luarocks config --lua-version=5.1 rocks_provided.luaffi-tkl 2.1-1
```

Example:

```lua
local vips = require "vips"

-- fast thumbnail generator
local image = vips.Image.thumbnail("somefile.jpg", 128)
image:write_to_file("tiny.jpg")

-- make a new image with some text rendered on it
image = vips.Image.text("Hello <i>World!</i>", {dpi = 300})

-- call a method
image = image:invert()

-- use the `..` operator to join images bandwise
image = image .. image .. image

-- add a constant
image = image + 12
-- add a different value to each band
image = image + { 1, 2, 3 }
-- add two images
image = image + image

-- split bands up again
b1, b2, b3 = image:bandsplit()

-- read a pixel from coordinate (10, 20)
r, g, b = image(10, 20)

-- make all pixels less than 128 bright blue
--    :less(128) makes an 8-bit image where each band is 255 (true) if that 
--        value is less than 128, and 0 (false) if it's >= 128 ... you can use
---       images or {1,2,3} constants as well as simple values
--    :bandand() joins all image bands together with bitwise AND, so you get a
--        one-band image which is true where all bands are true
--    condition:ifthenelse(then, else) takes a condition image and uses true or
--        false values to pick pixels from the then or else images ... then and
--        else can be constants or images
image = image:less(128):bandand():ifthenelse({ 0, 0, 255 }, image)

-- go to Yxy colourspace
image = image:colourspace("yxy")

-- pass options to a save operation
image:write_to_file("x.png", { compression = 9 })
```

# How it works

libvips has quite a bit of introspection machinery built in. 

When you call something like `image:hough_circle{ scale = 4 }`, the `__index`
method on the `lua-vips` image class opens libvips with ffi and searches
for an operation called `hough_circle`. It discovers what arguments the
operation takes, checks you supplied the correct arguments, and transforms
them into the form that libvips needs. It executes the operator, then pulls
out all the results and returns them as a Lua table.

This means that, although `lua-vips` supports almost 300 operators, the
binding itself is small, should be simple to maintain, and should always
be up to date.

# Getting more help

The libvips website has a handy table of [all the libvips
operators](http://libvips.github.io/libvips/API/current/func-list.html). Each
one links to the main API docs so you can see what you need to pass to it.

A simple way to see the arguments for an operation is to try running it
from the command-line. For example:

```bash
$ vips embed
embed an image in a larger image
usage:
   embed in out x y width height
where:
   in           - Input image, input VipsImage
   out          - Output image, output VipsImage
   x            - Left edge of input in output, input gint
			default: 0
			min: -1000000000, max: 1000000000
   y            - Top edge of input in output, input gint
			default: 0
			min: -1000000000, max: 1000000000
   width        - Image width in pixels, input gint
			default: 1
			min: 1, max: 1000000000
   height       - Image height in pixels, input gint
			default: 1
			min: 1, max: 1000000000
optional arguments:
   extend       - How to generate the extra pixels, input VipsExtend
			default: black
			allowed: black, copy, repeat, mirror, white, background
   background   - Color for background pixels, input VipsArrayDouble
operation flags: sequential 
```

So you can call `embed` like this:

```lua
local image = image:embed(100, 100, image:width() + 200, image:height() + 200,
    { extend = "mirror" })
```

To add a 100 pixel mirror edge around an image.

# Features

This section runs through the main features of the binding. 

To load the binding use:

```lua
local vips = require "vips"
```

## Make images

You can make images from files or from buffers (Lua strings), you can wrap
a vips image around an ffi array, or you can use one of the libvips create
operators to make an image for you.

### `image = vips.Image.new_from_file(filename [, options])`

Opens the file and returns an image. You can pass a set of options in a final
table argument, for example:

```lua
local image = vips.Image.new_from_file("somefile.jpg", 
   { access = "sequential" })
```

Some options are specific to some file types, for example, `shrink`, meaning
shrink by an integer factor during load, only applies to images loaded via
libjpeg.

You can embed options in filenames using the standard libvips syntax. For
example, these are equivalent:

```lua
local image = vips.Image.new_from_file("somefile.jpg", { shrink = 2 })
local image = vips.Image.new_from_file("somefile.jpg[shrink=2]")
```

You can call specific file format loaders directly, for example:

```lua
local image = vips.Image.jpegload("somefile.jpg", { shrink = 4 })
```

The [loader section in the API
docs](http://libvips.github.io/libvips/API/current/VipsForeignSave.html) lists
all loaders and their options. 

### `image = vips.Image.new_from_buffer(string [, string_options, options])`

The string argument should contain an image file in some container format, such
as JPEG. You can supply options, just as with `new_from_file`. These are
equivalent:

```lua
local image = vips.Image.new_from_buffer(string, "", { shrink = 2 })
local image = vips.Image.new_from_buffer(string, "shrink=2")
```

Use (for example) `vips.Image.jpegload_buffer` to call a loader directly.

### `image = vips.Image.new_from_memory(data, width, height, bands, format)`

This wraps a libvips image around a FFI memory array. The memory array should be
formatted as a C-style array. Images are always band-interleaved, so an RGB
image three pixels across and two pixels down, for example, is laid out as:

```
RGBRGBRGB
RGBRGBRGB
```

Example:

```lua
local width = 64
local height = 32
local data = ffi.new("unsigned char[?]", width * height)
local im = vips.Image.new_from_memory(data, width, height, 1, "uchar")
```

The returned image is using a pointer to the `data` area, but the Lua/LuaJIT interpreter won't always know this. You should keep a reference to `data` alive for as long as you are using any downstream images, or you'll get a crash.

### `image = vips.Image.new_from_memory_ptr(data, size, width, height, bands, format)`

Same as `new_from_memory`, but for any kind of data pointer (non-FFI allocated) by specifying the length of the data in bytes. The pointed data must be valid for the lifespan of the image and any downstream images.

A string can be used as the data pointer thanks to FFI semantics.

### `image = vips.Image.new_from_image(image, pixel)`

Makes a new image with the size, format, and resolution of `image`, but with
each pixel having the value `pixel`. For example:

```lua
local new_image = vips.Image.new_from_image(image, 12)
```

Will make a new image with one band where every pixel has the value 12. You can
call it as a member function. `pixel` can be a table to make a many-band image,
for example:

```lua
local new_image = image:new_from_image{ 1, 2, 3 }
```

Will make a new three-band image, where all the red pixels have the value 1,
greens are 2 and blues are 3.

### `image = vips.Image.new_from_array(array [, scale [, offset]])`

Makes a new image from a Lua table. For example:

```lua
local image = vips.Image.new_from_array{ 1, 2, 3 }
```

Makes a one-band image, three pixels across and one high. Use nested tables for
2D images. You can set a scale and offset with two extra number parameters --
handy for integer convolution masks.

```lua
local mask = vips.Image.new_from_array(
    {{-1,  -1, -1}, 
     {-1,  16, -1}, 
     {-1,  -1, -1}}, 8)
local image = image:conv(mask, { precision = "integer" })
```

### `image = vips.Image.copy_memory(self)`

The image is rendered to a large memory buffer, and a new image is returned
which represents the memory area. 

This is handy for breaking a pipeline.

### `image = vips.Image.black(width, height)`

Makes a new one band, 8 bit, black image. You can call any of the libvips image
creation operators in this way, for example:

```lua
local noise = vips.Image.perlin(256, 256, { cell_size = 128 })
```

See:

[http://libvips.github.io/libvips/API/current/libvips-create.html](http://libvips.github.io/libvips/API/current/libvips-create.html)

## Get and set image metadata

You can read and write aribitrary image metadata. 

### `number = vips.Image.get_typeof(image, field_name)`

This returns the GType for a field, or 0 if the field does not exist.
`vips.gvalue` has a set of GTypes you can check against. 

### `mixed = vips.Image.get(image, field_name)`

This reads any named piece of metadata from the image, for example:

```lua
local version = image:get("exif-ifd2-ExifVersion")
```

The item is converted to some Lua type in the obvious way. There are convenient
shortcuts for many of the standard fields, so these are equivalent:

```lua
local width = image:get("width")
local width = image:width()
```

If the field does not exist, `lua-vips` will throw an error. Use `get_typeof`
to check for the existence of a field.

### `vips.Image.set_type(image, gtype, field_name, value)`

This creates a new metadata item of the specified type, name and value. 

### `vips.Image.set(image, field_name, value)`

This changes the value of an existing field, but will not change its type.

You can't use `set()` to change core fields such as like `width` or
`interpretation`.  Use `copy()` instead.

Image references will be shared by the operation cache, so modifying an image
can change an image somewhere else in your program. Before changing an image,
you must make sure you own a private copy of an image with `copy`.

```lua
local new_image = image:copy()
new_image:set("orientation", 7)
```

### `boolean = vips.Image.remove(image, field_name)`

This will remove a piece of metadata. It returns `true` if an item was
successfully removed, `false` otherwise. 

As with `set`, you must use copy before removing a metadata item.

## Call any libvips operation

You can call any libvips operation as a member function, for example
`hough_circle`, the circular Hough transform:

[http://libvips.github.io/libvips/API/current/libvips-arithmetic.html#vips-hough-circle](http://libvips.github.io/libvips/API/current/libvips-arithmetic.html#vips-hough-circle)

Can be called from Lua like this:

```lua
local image2 = image:hough_circle{ scale = 2, max_radius = 50 }
```

The rules are:

1. `self` is used to set the first required input image argument.

2. If you supply one more argument than the number of required arguments, 
   and the final argument you supply is a table, 
   that extra table is used to set any optional input arguments. 

3. If you supply a constant (a number, or a table of numbers) and libvips 
   wants an image, your constant is automatically turned into an image using
   the first input image you supplied as a guide. 

4. For enums, you can supply a number or a string. The string is an enum member
   nickname (the part after the final underscore).

5. `MODIFY` arguments, for example the image you pass to `draw_circle`, are
   copied to memory before being set, and the new image is returned as one of
   the results. 

6. Operation results are returned as an unpacked array in the order: all
   required output args, then all optional output args, then all deprecated
   output args.

You can write (for example):

```lua
max_value = image:max()
```

To get the maximum value from an image. If you look at [the `max`
operator](http://libvips.github.io/libvips/API/current/libvips-arithmetic.html#vips-max),
it can actually return a lot more than this. You can write:

```lua
max_value, x, y = image:max()
```

To get the position of the maximum, or:

```lua
max_value, x, y, maxes = image:max{ size = 10 }
```

and `maxes` will be an array of the top 10 maximum values in order. 

## Operator overloads

The Lua operators are overloaded in the obvious way, so you can write (for
example):

```lua
image = (image * 2 + 13) % 4
```

and the appropriate vips operations will be called. You can mix images, number
constants, and array constants freely.

The relational operators are not overloaded, unfortunately; Lua does not
permit this. You must write something like:

```lua
image = image:less(128):ifthenelse(128, image)
```

to set all values less than 128 to 128.

`__call` (ie. `()`) is overloaded to call the libvips `getpoint` operator. 
You can write:

```lua
image = vips.Image.new_from_file("k2.jpg")
r, g, b = image(10, 10)
```

and `r`, `g`, `b` will be the RGB values for the pixel at coordinate (10, 10).

`..` is overloaded to mean `bandjoin`. 

Use `im:bands()` to get the number of bands and `im:extract_band(N)` to extract a
band (note bands number from zero). lua-vips does not overload `#` and `[]` for
this, since mixing numbering from zero and one causes confusion. 

## Convenience functions

A set of convenience functions are also defined.

### `array<image> = image:bandsplit()`

This splits a many-band image into an array of one band images.

### `image:bandjoin()`

The `bandjoin` operator takes an array of images as input. This can be awkward
to call --- you must write:


```lua
image = vips.Image.bandjoin{ image, image }
```

to join an image to itself. Instead, `lua-vips` defines `bandjoin` as a member
function, so you write:

```lua
image = image:bandjoin(image)
```

to join an image to itself, or perhaps:

```lua
image = R:bandjoin{ G, B }
```

to join three RGB bands. Constants work too, so you can write:

```lua
image = image:bandjoin(255)
image = R:bandjoin{ 128, 23 }
```

The `bandrank` and `composite` operators works in the same way. 

### `image = condition_image:ifthenelse(then_image, else_image [, options])`

This uses the condition image to pick pixels between then and else. Unlike all
other operators, if you use a constant for `then_image` or `else_image`, they
first match to each other, and only match to the condition image if both then
and else are constants. 

### `image = image:sin()`

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

You can write images to files, to ffi arrays, or to formatted strings. 

### `image:write_to_file(filename [, options])`

The filename suffix is used to pick the save operator. Just as with 
`new_from_file`, not all options will be correct for all file
types. You can call savers directly if you wish, for example:

```lua
image:jpegsave("x.jpg", { Q = 90 })
```

### `string = image:write_to_buffer(suffix [, options])`

The suffix is used to pick the saver that is used to generate the result, so
`".jpg"` will make a JPEG-formatted string. Again, you can call the savers
directly if you wish, perhaps:

```lua
local str = image:jpegsave_buffer{ Q = 90 }
```

### `memory = image:write_to_memory()`

A large ffi char array is allocated and the image is rendered to it. 

```lua
local mem = image:write_to_memory()
print("written ", ffi.sizeof(mem), "bytes to", mem)
```

### `ptr, size = image:write_to_memory_ptr()`

An allocated char array pointer (GCd with a `ffi.gc` callback) and the length in bytes of the image data is directly returned from libvips (no intermediate FFI allocation).

## True Streaming

When processing images an image library would usually read an image from a file into memory, decode and process it and finally write the encoded result into a file. The processing can only start when the image is fully read into memory and the writing can only start when the processing step is completed.
Libvips can process images directly from a pipe and write directly to a pipe, without the need to read the whole image to memory before being able to start and without the need to finish processing before being able to start writing. This is achieved using a technique called true streaming. In this context there are sources and targets and the processing step happens from source to target. Sources can be created from files, memory or descriptors (like stdin) and targets can be created to files, memory or descriptors (like stdout). Here is an example:

```lua test.lua
local vips = require "vips"
local stdin, stdout = 0, 1
local source = vips.Source.new_from_descriptor(stdin)
local target = vips.Target.new_to_descriptor(stdout)
local image = vips.Image.new_from_source(source, '', { access = 'sequential' })
image = image:invert()
image:write_to_target(target, '.jpg')
```

Running this script in a Unix terminal via 
```term
curl https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Cat03.jpg/600px-Cat03.jpg | lua test.lua > out.jpg
```

will feed a cat image from the internet into standard input, from which the Lua script reads and inverts it and writes it to standard output, where it is redirected to a file. This all happens simultaneously, so the processing and writing doesn't need to wait until the whole image is downloaded from the internet.

## Error handling

Most `lua-vips` methods will call `error()` if they detect an error. Use
`pcall()` to call a method and catch an error. 

Use `get_typeof` to test for a field of a certain name without throwing an
error.

## The libvips operation cache

libvips keeps a cache of recent operations, such as load, save, shrink, and
so on. If you repeat an operation, you'll get the cached result back. 

It keeps track of the number of open files, allocated memory and cached
operations, and will trim the cache if more than 100 files are open at once,
more than 100mb of memory has been allocated, or more than 1,000 operations
are being held.

Normally this cache is useful and harmless, but for some applications you may 
want to change these values.

```lua
-- set number of cached operations
vips.cache_set_max(100)
-- set maximum cache memory use
vips.cache_set_max_mem(10 * 1024 * 1024)
-- set maximum number of open files
vips.cache_set_max_files(10)
```

# Development

### Setup for Ubuntu

Configure `luarocks` for a local tree

```shell
luarocks help path
```

append

```shell
eval `luarocks path`
export PATH="$HOME/.luarocks/bin:$PATH"
```

to `~/.bashrc`.

### Install

```shell
luarocks --local make
```

### Unit testing

You need:

```shell
luarocks --local install busted 
luarocks --local install luacov
luarocks --local install say
```

Then to run the test suite:

```shell
busted . 
```

for verbose output:

```shell
busted . -o gtest -v
```

### Linting and static analysis

You need:

```shell
luarocks --local install luacheck
```

Then to run the linter:

```shell
luacheck .
```

### Test

Run the example script with:

```shell
lua example/hello-world.lua
```

### Update rock

```shell
rm *.src.rock
luarocks upload lua-vips-1.1-12.rockspec --api-key=xxxxxxxxxxxxxx
```

### Links

http://luajit.org/ext_ffi_api.html

http://luajit.org/ext_ffi_semantics.html

https://github.com/luarocks/luarocks/wiki/creating-a-rock

https://olivinelabs.com/busted/

### Running on Windows using Mingw-w64

Installing `lua-vips` on Windows is a bit harder than on Unix systems. We recommend using MinGW (Minimalist GNU for Windows) for the installation. Here are the steps:

1. Install [MSYS2](https://www.msys2.org/) to the default path.
2. Start Mingw-w64 64bit console from the start menu. Check that is says MINGW64. The following steps happen in that console.
3. Update MSYS2 using
   ```shell
      pacman -Syuu
   ```
4. Install the build tools (including Lua 5.4 and Luarocks) via
   ```shell
      pacman -S git make mingw-w64-x86_64-toolchain mingw-w64-x86_64-lua-luarocks
   ```
5. Install `libvips` with (optional) dependencies via
   ```shell
      pacman -S
         mingw-w64-x86_64-libvips
         mingw-w64-x86_64-openslide
         mingw-w64-x86_64-libheif
         mingw-w64-x86_64-libjxl
         mingw-w64-x86_64-imagemagick
         mingw-w64-x86_64-poppler
   ```
6. Optionally: If you want to use `lua-vips` with LuaJIT instead of Lua 5.4 install LuaJIT via
   ```shell
      pacman -S mingw-w64-x86_64-luajit
      luarocks config --scope system lua_version 5.1
      luarocks config --scope system lua_interpreter luajit.exe
      luarocks config --scope system variables.LUA_DIR /mingw64/bin
      luarocks config --scope system variables.LUA_INCDIR /mingw64/include/luajit-2.1/
      luarocks config --scope system rocks_provided.luaffi-tkl 2.1-1
   ```
7. Install `lua-vips` via
   ```shell
      luarocks install lua-vips
   ```
   or clone the repository and run `luarocks make` in the `lua-vips` folder.
8.  Add `C:\msys64\mingw64\bin` and `C:\msys64\usr\bin` to the top of your `PATH`
   environment variable in the Windows Advanced system settings and restart the console.

9.  Run `lua` or `luajit` and try
    ```lua
    vips = require "vips"
    print(vips.Image.xyz(3,2))
    ```

### Running under Wine (Windows emulation on Linux)

@jcupitt used the luapower all-in-one to get a 64-bit Windows LuaJIT build:

https://luapower.com/

LuaJIT on Windows searches `PATH` to find DLLs. You can't set this directly
from Linux, you have to change the registry. See:

https://www.winehq.org/docs/wineusr-guide/environment-variables

Then add the `bin` area of the libvips Windows build to `PATH`.

```
z:\home\john\GIT\build-win64\8.5\vips-dev-8.5\bin
```

You must have no trailing backslash.

Try LuaJIT:

```
$ ~/packages/luajit/luapower-all-master/bin/mingw64/luajit.exe 
LuaJIT 2.1.0-beta2 -- Copyright (C) 2005-2016 Mike Pall.
http://luajit.org/
JIT: ON SSE2 SSE3 SSE4.1 fold cse dce fwd dse narrow loop abc sink fuse
> print(os.getenv("PATH"))
C:\windows\system32;C:\windows;C:\windows\system32\wbem;z:\home\john\GIT\build-win64\8.5\vips-dev-8.5\bin
> ffi = require "ffi"
> ffi.load("libvips-42.dll")
> ^D
```

The Windows luajit will pick up your `.luarocks/share/lua/5.1/vips.lua` install,
so to test just install and run:

```
$ ~/packages/luajit/luapower-all-master/bin/mingw64/luajit.exe
LuaJIT 2.1.0-beta2 -- Copyright (C) 2005-2016 Mike Pall. http://luajit.org/
  JIT: ON SSE2 SSE3 SSE4.1 fold cse dce fwd dse narrow loop abc sink fuse
> vips = require "vips"
> x = vips.Image.new_from_file("z:\\data\\john\\pics\\k2.jpg")
> print(x:width())
1450
> x = vips.Image.text("hello", {dpi = 300})
> x:write_to_file("x.png")
> 
```

