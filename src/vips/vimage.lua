-- manage the cdata VipsImage value

local ffi = require "ffi"

local vips_lib = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

ffi.cdef[[
    typedef struct _VipsImage {
        VipsObject parent_instance;

        // opaque
    } VipsImage;

]]
