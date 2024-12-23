-- An output connection

local ffi = require "ffi"

local verror = require "vips.verror"
local Connection = require "vips.Connection"

local vips_lib = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

local Source = {}

Source.new_from_descriptor = function(descriptor)
    local source = vips_lib.vips_source_new_from_descriptor(descriptor)
    if source == ffi.NULL then
        error("Can't create source from descriptor " .. descriptor .. "\n" .. verror.get())
    end

    return Connection.new(source)
end

Source.new_from_file = function(filename)
    local source = vips_lib.vips_source_new_from_file(filename)
    if source == ffi.NULL then
        error("Can't create source from filename " .. filename .. "\n" .. verror.get())
    end

    return Connection.new(source)
end

Source.new_from_memory = function(data) -- data is an FFI memory array containing the image data
    local source = vips_lib.vips_source_new_from_memory(data, ffi.sizeof(data))
    if source == ffi.NULL then
        error("Can't create input source from memory \n" .. verror.get())
    end

    return Connection.new(source)
end

return ffi.metatype("VipsSource", {
    __index = Source
})
