-- manage the cdata VipsImage value

local ffi = require "ffi"

ffi.cdef [[
    typedef struct _VipsImage {
        VipsObject parent_instance;

        // opaque
    } VipsImage;

]]
