-- top include for lua-vips

local ffi = require "ffi" 

local vips_lib = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

ffi.cdef[[
    int vips_init (const char* argv0);

    void vips_cache_set_max (int max);
    int vips_cache_get_max (void);
    void vips_cache_set_max_mem (size_t max_mem);
    size_t vips_cache_get_max_mem (void);
    void vips_cache_set_max_files (int max_files);
    int vips_cache_get_max_files (void);

]]

local result = vips_lib.vips_init("")
if result ~= 0 then
    local errstr = ffi.string(vips_lib.vips_error_buffer())
    vips_lib._libvips_error_clear()

    error("unable to start up libvips: " .. errstr)
end

local vips = {
    verror = require "vips/verror",
    version = require "vips/version",
    log = require "vips/log",
    gvalue = require "vips/gvalue",
    vobject = require "vips/vobject",
    voperation = require "vips/voperation",
    vimage = require "vips/vimage",
    Image = require "vips/Image",

    cache_set_max = function(max)
        vips_lib.vips_cache_set_max(max)
    end,

    cache_get_max = function ()
        return vips_lib.vips_cache_get_max()
    end,

    cache_set_max_files = function(max)
        vips_lib.vips_cache_set_max_files(max)
    end,

    cache_get_max_files = function ()
        return vips_lib.vips_cache_get_max_files()
    end,

    cache_set_max_mem = function(max)
        vips_lib.vips_cache_set_max_mem(max)
    end,

    cache_get_max_mem = function ()
        return vips_lib.vips_cache_get_max_mem()
    end,

}

require "vips/Image_methods"

-- for compat with 1.1-6, when these were misnamed
vips.set_max = vips.cache_set_max
vips.get_max = vips.cache_get_max
vips.set_max_files = vips.cache_set_max_files
vips.get_max_files = vips.cache_get_max_files
vips.set_max_mem = vips.cache_set_max_mem
vips.get_max_mem = vips.cache_get_max_mem

return vips 
