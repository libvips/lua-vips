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

local image = {}
local image_mt = {}

-- either a single number, or a table of numbers
local function is_pixel(value)
    return type(value) == "number" or
        (type(value) == "table" and not image.is_image(value))
end

-- test for rectangular array of something
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

    for i, v in ipairs(array) do
        new_array[i] = fn(v)
    end

    return new_array
end

local function call_enum(image, other, base, operation)
    if type(other) == "number" then
        return self[base .. "_const"](self, {other}, operation)
    elseif is_pixel(other) then
        return self[base .. "_const"](self, other, operation)
    else
        return self[base](self, other, operation)
    end
end

image_mt = {

    __add = function(self, other)
        print("in __add")
        print("no!! really, I am __add")

        log.msg("__add type(other) =", type(other))

        if type(other) == "number" then
            return self:linear({1}, {other})
        elseif is_pixel(other) then
            return self:linear({1}, other)
        else
            return self:add(other)
        end
    end,

    __sub = function(self, other)
        if type(other) == "number" then
            return self:linear({1}, {-other})
        elseif is_pixel(other) then
            return self:linear({1}, map(function(x) return -x end, other))
        else
            return self:subtract(other)
        end
    end,

    __mul = function(self, other)
        if type(other) == "number" then
            return self:linear({other}, {0})
        elseif is_pixel(other) then
            return self:linear(other, {0})
        else
            return self:multiply(other)
        end
    end,

    __div = function(self, other)
        if type(other) == "number" then
            return self:linear({1}, {1 / other})
        elseif is_pixel(other) then
            return self:linear({1}, map(function(x) return x ^ -1 end, other))
        else
            return self:divide(other)
        end
    end,

    __mod = function(self, other)
        if type(other) == "number" then
            return self:remainder_const({other})
        elseif is_pixel(other) then
            return self:remainder_const(other)
        else
            return self:remainder(other)
        end
    end,

    __unm = function(self)
        return self:linear({-1}, {0})
    end,

    __pow = function(self, other)
        return self:pow(other)
    end,

    __eq = function(self, other)
        -- this is only called for pairs of images
        return self:relational(other, "equal")
    end,

    __lt = function(self, other)
        return self:less(other)
    end,

    __le = function(self, other)
        return self:lesseq(other)
    end,

    __tostring = function(self)
        local result = (self:filename() or "(nil)") .. ": " ..
            self:width() .. "x" .. self:height() .. " " .. 
            self:format() .. ", " ..
            self:bands() .. " bands, " ..
            self:interpretation()

        if self:get_typeof("vips-loader") ~= 0 then
            result = result .. ", " .. self:get("vips-loader")
        end

        return result
    end,

    -- others are
    -- __concat (.. to join bands, perhaps?)
    -- __call (image(x, y) to get pixel, perhaps)
    -- __len (#image to get bands?)
    -- could add image[n] with number arg to invoke __index and 

    __index = {
        -- internal

        object = function(self)
            return ffi.cast(object.typeof, self)
        end,

        imageize = function(self, value)
            -- careful! self can be nil if value is a 2D array
            if is_2D(value) then
                return image.new_from_array(value)
            else
                return self:new_from_image(value)
            end
        end,

        is_image = function(value)
            return ffi.istype(gvalue.image_typeof, value) 
        end,

        -- constructors

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

        new_from_image = function(self, value)
            local pixel = (self.black(1, 1) + value).cast(self.format())
            local image = pixel.embed(0, 0, self:width(), self:height(),
                {extend = "copy"})
            image = image.copy{
                interpretation = self:interpretation(),
                xres = self:xres(),
                yres =  self:yres(),
                xoffset = self:xoffset(),
                yoffset = self:yoffset()
            }

            return image
        end,

        -- writers

        write_to_file = function(self, filename, ...)
            local operation_name = vips.vips_foreign_find_save(filename)
            if operation_name == nil then
                error(object.get_error())
            end
            return operation.call(ffi.string(operation_name), 
                self, filename, unpack{...})
        end,

        -- get/set metadata

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

        -- standard header fields

        width = function(self)
            return self:get("width")
        end,

        height = function(self)
            return self:get("height")
        end,

        size = function(self)
            return self:width(), self:height()
        end,

        bands = function(self)
            return self:get("bands")
        end,

        format = function(self)
            return self:get("format")
        end,

        interpretation = function(self)
            return self:get("interpretation")
        end,

        xres = function(self)
            return self:get("xres")
        end,

        yres = function(self)
            return self:get("yres")
        end,

        xoffset = function(self)
            return self:get("xoffset")
        end,

        yoffset = function(self)
            return self:get("yoffset")
        end,

        filename = function(self)
            return self:get("filename")
        end,

        -- many-image input operations
        --
        -- these don't wrap well automatically, since self is always separate

        bandjoin = function(self, other, options)
            -- allow a single untable arg as well
            if type(other) ~= "table" then
                other = {other}
            end

            -- if other is all constants, we can use bandjoin_const
            local all_constant = true
            for i = 1, #other do
                if type(other[i]) ~= "number" then
                    all_constant = false
                    break
                end
            end

            if all_constant then
                return operation.call("bandjoin_const", self, other)
            else
                return operation.call("bandjoin", {self, unpack(other)})
            end
        end,

        bandrank = function(self, other, options)
            if type(other) ~= "table" then
                other = {other}
            end

            return operation.call("bandrank", {self, unpack(other)})
        end,

        -- convenience functions

        bandsplit = function(self)
            local result 

            result = {}
            for i in 0, self:bands() do
                result[i + 1] = self:extract_band(i)
            end

            return result
        end,

        -- special behaviour wrappers

        ifthenelse = function(self, then_value, else_value, options)
            -- We need different imageize rules for this. We need then_value 
            -- and else_value to match each other first, and only if they 
            -- are both constants do we match to self.

            local match_image

            for i, v in pairs({then_value, else_value, self}) do
                if image.is_image(v) then
                    match_image = v
                    break
                end
            end

            if not image.is_image(then_value) then
                then_value = match_image:imageize(then_value)
            end

            if not image.is_image(else_value) then
                else_value = match_image:imageize(else_value)
            end

            return operation.call("ifthenelse", self, 
                then_value, else_value, options)
        end,

        -- enum expansions

        pow = function(self, other)
            return call_enum(self, other, "math2", "pow")
        end,

        wop = function(self, other)
            return call_enum(self, other, "math2", "wop")
        end,

        lshift = function(self, other)
            return call_enum(self, other, "boolean", "lshift")
        end,

        rshift = function(self, other)
            return call_enum(self, other, "boolean", "rshift")
        end,

        andimage = function(self, other)
            return call_enum(self, other, "boolean", "and")
        end,

        orimage = function(self, other)
            return call_enum(self, other, "boolean", "or")
        end,

        eorimage = function(self, other)
            return call_enum(self, other, "boolean", "eor")
        end,

        less = function(self, other)
            return call_enum(self, other, "relational", "less")
        end,

        lesseq = function(self, other)
            return call_enum(self, other, "relational", "lesseq")
        end,

        more = function(self, other)
            return call_enum(self, other, "relational", "more")
        end,

        moreeq = function(self, other)
            return call_enum(self, other, "relational", "moreeq")
        end,

        equal = function(self, other)
            return call_enum(self, other, "relational", "equal")
        end,

        noteq = function(self, other)
            return call_enum(self, other, "relational", "noteq")
        end,

        floor = function(self)
            return self:round("floor")
        end,

        ceil = function(self)
            return self:round("ceil")
        end,

        rint = function(self)
            return self:round("rint")
        end,

        bandand = function(self)
            return self:bandbool("and")
        end,

        bandor = function(self)
            return self:bandbool("or")
        end,

        bandeor = function(self)
            return self:bandbool("eor")
        end,

        real = function(self)
            return self:complexget("real")
        end,

        imag = function(self)
            return self:complexget("imag")
        end,

        polar = function(self)
            return self:complex("polar")
        end,

        rect = function(self)
            return self:complex("rect")
        end,

        conj = function(self)
            return self:complex("conj")
        end,

        sin = function(self)
            return self:math("sin")
        end,

        cos = function(self)
            return self:math("cos")
        end,

        tan = function(self)
            return self:math("tan")
        end,

        asin = function(self)
            return self:math("asin")
        end,

        acos = function(self)
            return self:math("acos")
        end,

        atan = function(self)
            return self:math("atan")
        end,

        exp = function(self)
            return self:math("exp")
        end,

        exp10 = function(self)
            return self:math("exp10")
        end,

        log = function(self)
            return self:math("log")
        end,

        log10 = function(self)
            return self:math("log10")
        end,

        erode = function(self, mask)
            return self:morph(mask, "erode")
        end,

        dilate = function(self, mask)
            return self:morph(mask, "dilate")
        end,

        fliphor = function(self)
            return self:flip("horizontal")
        end,

        flipver = function(self)
            return self:flip("vertical")
        end,

        rot90 = function(self)
            return self:rot("d90")
        end,

        rot180 = function(self)
            return self:rot("d180")
        end,

        rot270 = function(self)
            return self:rot("d270")
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

