-- top include for lua-vips

local ffi = require "ffi" 

local vips = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

ffi.cdef[[
    int vips_init (const char* argv0);

    void vips_cache_set_max (int max);
    int vips_cache_get_max (void);
    void vips_cache_set_max_mem (size_t max_mem);
    size_t vips_cache_get_max_mem (void);
    void vips_cache_set_max_files (int max_files);
    int vips_cache_get_max_files (void);

]]

local result = vips.vips_init("")
if result ~= 0 then
    local errstr = ffi.string(vips.vips_error_buffer())
    vips.vips_error_clear()

    error("unable to start up libvips: " .. errstr)
end

return { 
    verror = require "vips/verror",
    version = require "vips/version",
    log = require "vips/log",
    gvalue = require "vips/gvalue",
    vobject = require "vips/vobject",
    voperation = require "vips/voperation",
    vimage = require "vips/vimage",
    Image = require "vips/Image",
    require "vips/Image_methods",

    set_max = function(max)
        vips.vips_cache_set_max(max)
    end,

    get_max = function ()
        return vips.vips_cache_get_max()
    end,

    set_max_files = function(max)
        vips.vips_cache_set_max_files(max)
    end,

    get_max_files = function ()
        return vips.vips_cache_get_max_files()
    end,

    set_max_mem = function(max)
        vips.vips_cache_set_max_mem(max)
    end,

    get_max_mem = function ()
        return vips.vips_cache_get_max_mem()
    end,

}
