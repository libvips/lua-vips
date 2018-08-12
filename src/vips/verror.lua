-- handle the libvips error buffer

local ffi = require "ffi"

local vips_lib = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

local verror = {
    -- get and clear the error buffer
    get = function()
        local errstr = ffi.string(vips_lib.vips_error_buffer())
        vips_lib.vips_error_clear()

        return errstr
    end
}

return verror
