package = "lua-vips"
version = "0.1-1"
source = {
   url = "https://github.com/jcupitt/lua-vips"
}
description = {
   summary = "A fast image processing library with low memory needs.",
   detailed = [[
      This luajit rock implements a binding for the libvips image 
      processing library. It is usually faster and needs less memory than 
      similar libraries. 

      This binding works, but is not yet finished. 
   ]],
   homepage = "https://github.com/jcupitt/lua-vips",
   license = "MIT" 
}
dependencies = {
   -- I think we're probably luajit-only, thanks to ffi, but maybe not.
   -- How do we express this? "luajit >= 2.0" doesn't work.
   -- We also need ffi and bit
}
build = {
   type = "builtin",
   modules = {
       vips = "src/vips.lua",
       ["vips.gvalue"] = "src/vips/gvalue.lua",
       ["vips.object"] = "src/vips/object.lua",
       ["vips.operation"] = "src/vips/operation.lua",
       ["vips.image"] = "src/vips/image.lua"
   }
}
