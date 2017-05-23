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

    VipsImage* vips_image_new_matrix_from_array (int width, int height,
            const double* array, int size);

    unsigned long int vips_image_get_typeof (const VipsImage* image, 
        const char* name);
    int vips_image_get (const VipsImage* image, 
        const char* name, GValue* value_copy);

    void vips_image_set (VipsImage* image, const char* name, GValue* value);

]]

local function is_2D(table)
    if type(table) ~= "table" then
        return false
    end

    for i = 1, #table do
        if type(table[i]) ~= "table" then
            return false
        end
        if #table[i] ~= #table[1] then
            return false
        end
    end

    return true
end

local image
local image_mt = {
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

        new_from_file = function(filename, ...)
            local operation_name = vips.vips_foreign_find_load(filename)
            if operation_name == nil then
                error(object.get_error())
            end
            return operation.call(ffi.string(operation_name), 
                filename, unpack{...})
        end,

        new_from_array = function(array, scale, offset)
            local width
            local height

            if not is_2D(array) then
                array = {array}
            end
            width = #array[1]
            height = #array

            local n = width * height
            local a = ffi.new(gvalue.pdouble_typeof, n)
            for y = 1, height do
                for x = 1, width do
                    a[x + y * width] = array[y][x]
                end
            end
            local self = 
                vips.vips_image_new_matrix_from_array(width, height, a, n)

            self:set_type(gvalue.gdouble_type, "scale", scale or 1)
            self:set_type(gvalue.gdouble_type, "offset", offset or 0)

            return self
        end,

        write_to_file = function(self, filename, ...)
            local operation_name = vips.vips_foreign_find_save(filename)
            if operation_name == nil then
                error(object.get_error())
            end
            return operation.call(ffi.string(operation_name), 
                self, filename, unpack{...})
        end,

        -- image get/set reads and writes the header, object get/set reads and
        -- writes GObject properties
        get_typeof = function(self, name)
            return vips.vips_image_get_typeof(self, name)
        end,

        get = function(self, name)
            local gva = gvalue.newp()
            local result = vips.vips_image_get(self, name, gva)
            if result ~= 0 then
                error("unable to get " .. name)
            end

            return gva[0]:get()
        end,

        set_type = function(self, gtype, name, value)
            local gv = gvalue.new()
            gv:init(gtype)
            gv:set(value)
            vips.vips_image_set(self, name, gv)
        end,

        set = function(self, name, value)
            local gtype = self:get_typeof(name)
            self:set_type(gtype, name, value)
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

    }
}

setmetatable(image_mt.__index, {
    __index = function(table, name)
        return function(...)
            return operation.call(name, unpack{...})
        end
    end
})

image = ffi.metatype("VipsImage", image_mt)
return image

