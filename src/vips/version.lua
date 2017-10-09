-- detect and test libvips version

local ffi = require "ffi" 

local vips = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

ffi.cdef[[
    int vips_version (int flag);

]]

local version = {}

version = {
    major = vips.vips_version(0),
    minor = vips.vips_version(1),
    micro = vips.vips_version(2),

    -- test for libvips version is better than x.y .. we use this to turn on 
    -- various workarounds for older libvips
    at_least = function(x, y)
        return version.major > x or (version.major == x and version.minor >= y)
    end,

}

return version

