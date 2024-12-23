-- abstract base Connection class

local ffi = require "ffi"

local vobject = require "vips.vobject"

local vips_lib = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

local Connection_method = {}

local Connection = {
    mt = {
        __index = Connection_method,
    }
}

function Connection.mt:__tostring()
    return self:filename() or self:nick() or "(nil)"
end

Connection.new = function(vconnection)
    local connection = {}
    connection.vconnection = vobject.new(vconnection)
    return setmetatable(connection, Connection.mt)
end
function Connection_method:vobject()
    return ffi.cast(vobject.typeof, self.vconnection)
end

function Connection_method:filename()
    -- Get the filename asscoiated with a connection. Return nil if there is no associated file.
    local so = ffi.cast('VipsConnection *', self.vconnection)
    local filename = vips_lib.vips_connection_filename(so)
    if filename == ffi.NULL then
        return nil
    else
        return ffi.string(filename)
    end
end

function Connection_method:nick()
    -- Make a human-readable name for a connection suitable for error messages.

    local so = ffi.cast('VipsConnection *', self.vconnection)
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
