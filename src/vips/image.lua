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

local function map(fn, array)
    local new_array = {}

    for i,v in ipairs(array) do
        new_array[i] = fn(v)
    end

    return new_array
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

    __sub = function(self, other)
        if type(other) == "number" then
            return self:linear({1}, {-other})
        elseif type(other) == "table" then
            return self:linear({1}, map(function(x) return -x end, other))
        else
            return self:subtract(other)
        end
    end,

    __mul = function(self, other)
        if type(other) == "number" then
            return self:linear({other}, {0})
        elseif type(other) == "table" then
            return self:linear(other, {0})
        else
            return self:multiply(other)
        end
    end,

    __div = function(self, other)
        if type(other) == "number" then
            return self:linear({1}, {1 / other})
        elseif type(other) == "table" then
            return self:linear({1}, map(function(x) return x ^ -1 end, other))
        else
            return self:divide(other)
        end
    end,

    __mod = function(self, other)
        if type(other) == "number" then
            return self:remainder_const({other})
        elseif type(other) == "table" then
            return self:remainder_const(other)
        else
            return self:remainder(other)
        end
    end,

    __unm = function(self)
        return self:linear({-1}, {0})
    end,

    __pow = function(self, other)
        if type(other) == "number" then
            return self:math2_const({other}, "pow")
        elseif type(other) == "table" then
            return self:math2_const(other, "pow")
        else
            return self:math2(other, "pow")
        end
    end,

    __eq = function(self, other)
        -- this is only called for two images
        return self:relational(other, "equal")
    end,

    __lt = function(self, other)
        if type(other) == "number" then
            return self:relational_const({other}, "less")
        elseif type(other) == "table" then
            return self:relational_const(other, "less")
        else
            return self:relational(other, "less")
        end
    end,

    __le = function(self, other)
        if type(other) == "number" then
            return self:relational_const({other}, "lesseq")
        elseif type(other) == "table" then
            return self:relational_const(other, "lesseq")
        else
            return self:relational(other, "lesseq")
        end
    end,

    -- others are
    -- __concat (.. to join bands, perhaps?)
    -- __call (image(x, y) to get pixel, perhaps)
    -- __len (#image to get bands?)
    -- could add image[n] with number arg to invoke __index and 

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

