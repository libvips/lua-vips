package = "lua-vips"
version = "1.1-11"
rockspec_format = "3.0"

source = {
   url = "git://github.com/libvips/lua-vips.git",
   tag = "v1.1-11",
}

description = {
   summary = "A fast image processing library with low memory needs.",
   detailed = [[
      This rock implements a binding for the libvips image processing library.
      It is usually faster and needs less memory than similar libraries.

      For use with standard Lua, the dependency luaffi-tkl is used as a drop-in
      replacement for LuaJIT's ffi module.
   ]],
   homepage = "https://github.com/libvips/lua-vips",
   license = "MIT",
   labels = { "image" }
}

dependencies = {
    "lua >= 5.1, < 5.5",   -- standard Lua or LuaJIT >= 2.0
    "luaffi-tkl >= 1.0"    -- provided by VM with LuaJIT, use `luarocks config rocks_provided.luaffi-tkl 2.1-1` in that case
}

test_dependencies = {
   "busted"
}

test = {
   type = "busted"
}

build = {
   type = "builtin",
   modules = {
       vips = "src/vips.lua",
       ["vips.cdefs"] = "src/vips/cdefs.lua",
       ["vips.verror"] = "src/vips/verror.lua",
       ["vips.version"] = "src/vips/version.lua",
       ["vips.log"] = "src/vips/log.lua",
       ["vips.gvalue"] = "src/vips/gvalue.lua",
       ["vips.vobject"] = "src/vips/vobject.lua",
       ["vips.voperation"] = "src/vips/voperation.lua",
       ["vips.Image"] = "src/vips/Image.lua",
       ["vips.Image_methods"] = "src/vips/Image_methods.lua",
       ["vips.Interpolate"] = "src/vips/Interpolate.lua"
   }
}
