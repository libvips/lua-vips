-- An input connection

local ffi = require "ffi"

local Connection = require "vips.Connection"

local vips_lib = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

local Target = {}

Target.new_to_descriptor = function(descriptor)
    collectgarbage("stop")
    local target = vips_lib.vips_target_new_to_descriptor(descriptor)
    collectgarbage("restart")
    if target == ffi.NULL then
        error("can't create output target from descriptor " .. descriptor)
    else
        return Connection.new(target)
    end
end

Target.new_to_file = function(filename)
    collectgarbage("stop")
    local target = vips_lib.vips_target_new_to_file(filename)
    collectgarbage("restart")
    if target == ffi.NULL then
        error("can't create output target from filename " .. filename)
    else
        return Connection.new(target)
    end
end

Target.new_to_memory = function()
    collectgarbage("stop")
    local target = vips_lib.vips_target_new_to_memory()
    collectgarbage("restart")
    if target == ffi.NULL then
        error("can't create output target from memory")
    else
        return Connection.new(target)
    end
end

return ffi.metatype("VipsTarget", {
    __index = Target
})
