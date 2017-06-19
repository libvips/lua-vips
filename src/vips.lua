-- top include for lua-vips

local ffi = require "ffi" 

local vips = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

ffi.cdef[[
    int vips_init (const char* argv0);

    const char* vips_error_buffer (void);
    void vips_error_clear (void);
]]

local result = vips.vips_init("")
if result ~= 0 then
    local errstr = ffi.string(vips.vips_error_buffer())
    vips.vips_error_clear()

    error("unable to start up libvips: " .. errstr)
end

return { 
    log = require "vips/log",
    gvalue = require "vips/gvalue",
    vobject = require "vips/vobject",
    voperation = require "vips/voperation",
    vimage = require "vips/vimage",
    Image = require "vips/Image",
    require "vips/Image_methods",
}
