-- top include for lua-vips

local ffi = require "ffi" 

local vips = ffi.load("vips")

ffi.cdef[[
    void vips_init (const char* argv0);
]]

vips.vips_init("")

return { 
    log = require "vips/log",
    gvalue = require "vips/gvalue",
    vobject = require "vips/vobject",
    voperation = require "vips/voperation",
    vimage = require "vips/vimage",
    vbuffer = require "vips/vbuffer",
    Image = require "vips/Image",
    require "vips/Image_methods",
}
