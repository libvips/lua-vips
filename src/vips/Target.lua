-- An input connection

local ffi = require "ffi"

local vobject = require "vips.vobject"
local Connection = require "vips.Connection"

local vips_lib = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

local Target = {}

Target.vobject = function(self)
    return ffi.cast(vobject.typeof, self)
end

Target.new_to_descriptor = function(descriptor)
    local target = vips_lib.vips_target_new_to_descriptor(descriptor)
    if target == ffi.NULL then
        error("can't create output target from descriptor " .. descriptor)
    else
        return Connection.new(target)
    end
end

Target.new_to_file = function(filename)
    local target = vips_lib.vips_target_new_to_file(filename)
    if target == ffi.NULL then
        error("can't create output target from filename " .. filename)
    else
        return Connection.new(target)
    end
end

Target.new_to_memory = function()
    local target = vips_lib.vips_target_new_to_memory()
    if target == ffi.NULL then
        error("can't create output target from memory")
    else
        return Connection.new(target)
    end
end

return ffi.metatype("VipsTarget", {
    __index = Target
})
