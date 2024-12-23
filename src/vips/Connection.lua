-- abstract base Connection class

local ffi = require "ffi"

local vobject = require "vips.vobject"

local vips_lib = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

local Connection = {}

Connection.vobject = function(self)
    return ffi.cast(vobject.typeof, self)
end

Connection.new = function(self)
    return vobject.new(self)
end
Connection.filename = function(self)
    -- Get the filename asscoiated with a connection. Return nil if there is no associated file.
    local so = ffi.cast('VipsConnection *', self.pointer)
    local filename = vips_lib.vips_connection_filename(so)
    if filename == ffi.NULL then
        return nil
    else
        return ffi.string(filename)
    end
end

Connection.nick = function(self)
    -- Make a human-readable name for a connection suitable for error messages.

    local so = ffi.cast('VipsConnection *', self.pointer)
    local nick = vips_lib.vips_connection_nick(so)
    if nick == ffi.NULL then
        return nil
    else
        return ffi.string(nick)
    end
end

return ffi.metatype("VipsConnection", {
    __index = Connection
})
