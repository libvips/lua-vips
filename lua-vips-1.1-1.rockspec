package = "lua-vips"
version = "1.1-1"

source = {
   url = "git://github.com/jcupitt/lua-vips.git"
}

description = {
   summary = "A fast image processing library with low memory needs.",
   detailed = [[
      This LuaJIT rock implements a binding for the libvips image 
      processing library. It is usually faster and needs less memory than 
      similar libraries. 
   ]],
   homepage = "https://github.com/jcupitt/lua-vips",
   license = "MIT" 
}

dependencies = {
    "lua >= 5.1", -- "luajit >= 2.0.0"
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
