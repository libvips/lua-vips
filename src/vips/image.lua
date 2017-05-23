-- manage VipsImage

local ffi = require "ffi"

local log = require "vips/log"
local gvalue = require "vips/gvalue"
local object = require "vips/object"
local operation = require "vips/operation"

local vips = ffi.load("vips")

ffi.cdef[[
    typedef struct _VipsImage {
        VipsObject parent_instance;

        // opaque
    } VipsImage;

    const char* vips_foreign_find_load (const char *name);

    const char* vips_foreign_find_save (const char* name);

]]

local vimage
local vimage_mt = {
    __add = function(self, other)
        log.msg("__add type(other) =", type(other))

        if type(other) == "number" then
            return self:linear({1}, {other})
        elseif type(other) == "table" then
            return self:linear({1}, other)
        else
            return self:add(other)
        end
    end,

    __index = {
        -- cast to an object
        object = function(self)
            return ffi.cast(object.typeof, self)
        end,

        get_typeof = function(self, name)
            return self:object():get_typeof(name)
        end,

        get = function(self, name)
            return self:object():get(name)
        end,

        width = function(self)
            return self:get("width")
        end,

        height = function(self)
            return self:get("height")
        end,

        size = function(self)
            return self:width(), self:height()
        end,

        new_from_file = function(filename, ...)
            local operation_name = vips.vips_foreign_find_load(filename)
            if operation_name == nil then
                error(object.get_error())
            end
            return operation.call(ffi.string(operation_name), 
                filename, unpack{...})
        end,

        write_to_file = function(self, filename, ...)
            local operation_name = vips.vips_foreign_find_save(filename)
            if operation_name == nil then
                error(object.get_error())
            end
            return operation.call(ffi.string(operation_name), 
                self, filename, unpack{...})
        end,

    }
}

setmetatable(vimage_mt.__index, {
    __index = function(table, name)
        return function(...)
            return operation.call(name, unpack{...})
        end
    end
})

vimage = ffi.metatype("VipsImage", vimage_mt)
return vimage

