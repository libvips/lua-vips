-- top include for lua-vips

local ffi = require "ffi"

local vips_lib = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

require "vips.cdefs"

local result = vips_lib.vips_init("lua-vips")
if result ~= 0 then
    local errstr = ffi.string(vips_lib.vips_error_buffer())
    vips_lib.vips_error_clear()

    error("unable to start up libvips: " .. errstr)
end

local vips = {
    verror = require "vips.verror",
    version = require "vips.version",
    log = require "vips.log",
    gvalue = require "vips.gvalue",
    vobject = require "vips.vobject",
    voperation = require "vips.voperation",
    Image = require "vips.Image_methods",
}

function vips.leak_set(leak)
    vips_lib.vips_leak_set(leak)
end

function vips.cache_set_max(max)
    vips_lib.vips_cache_set_max(max)
end

function vips.cache_get_max()
    return vips_lib.vips_cache_get_max()
end

function vips.cache_set_max_files(max)
    vips_lib.vips_cache_set_max_files(max)
end

function vips.cache_get_max_files()
    return vips_lib.vips_cache_get_max_files()
end

function vips.cache_set_max_mem(max)
    vips_lib.vips_cache_set_max_mem(max)
end

function vips.cache_get_max_mem()
    return vips_lib.vips_cache_get_max_mem()
end

-- for compat with 1.1-6, when these were misnamed
vips.set_max = vips.cache_set_max
vips.get_max = vips.cache_get_max
vips.set_max_files = vips.cache_set_max_files
vips.get_max_files = vips.cache_get_max_files
vips.set_max_mem = vips.cache_set_max_mem
vips.get_max_mem = vips.cache_get_max_mem

return vips
