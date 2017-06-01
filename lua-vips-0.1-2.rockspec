package = "lua-vips"
version = "0.1-2"
source = {
   url = "git://github.com/jcupitt/lua-vips.git"
}
description = {
   summary = "A fast image processing library with low memory needs.",
   detailed = [[
      This luajit rock implements a binding for the libvips image 
      processing library. It is usually faster and needs less memory than 
      similar libraries. 
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
       ["vips.log"] = "src/vips/log.lua",
       ["vips.gvalue"] = "src/vips/gvalue.lua",
       ["vips.vobject"] = "src/vips/vobject.lua",
       ["vips.voperation"] = "src/vips/voperation.lua",
       ["vips.vimage"] = "src/vips/vimage.lua",
       ["vips.Image"] = "src/vips/Image.lua",
       ["vips.Image_methods"] = "src/vips/Image_methods.lua"
   }
}
