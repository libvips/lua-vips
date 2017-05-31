-- an Image class with overloads

local ffi = require "ffi"

local log = require "vips/log"
local gvalue = require "vips/gvalue"
local vobject = require "vips/vobject"
local voperation = require "vips/voperation"
local vimage = require "vips/vimage"
local Image = require "vips/Image"

local vips = ffi.load("vips")

ffi.cdef[[
    const char* vips_foreign_find_load (const char* name);
    const char* vips_foreign_find_load_buffer (const void* data, size_t size);
    const char* vips_foreign_find_save (const char* name);
    const char* vips_foreign_find_save_buffer (const char* suffix);

    VipsImage* vips_image_new_matrix_from_array (int width, int height,
            const double* array, int size);

    unsigned long int vips_image_get_typeof (const VipsImage* image, 
        const char* name);
    int vips_image_get (const VipsImage* image, 
        const char* name, GValue* value_copy);

    void vips_image_set (VipsImage* image, const char* name, GValue* value);

]]

-- either a single number, or a table of numbers
local function is_pixel(value)
    return type(value) == "number" or
        (type(value) == "table" and not Image.is_Image(value))
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

local function swap_Image_left(left, right)
    if Image.is_Image(left) then
        return left, right
    elseif Image.is_Image(right) then
        return right, left
    else
        error("must have one image argument")
    end
end

-- either a single number, or a table of numbers
local function is_pixel(value)
    return type(value) == "number" or
        (type(value) == "table" and not Image.is_Image(value))
end

local function call_enum(image, other, base, operation)
    if type(other) == "number" then
        return image[base .. "_const"](image, operation, {other})
    elseif is_pixel(other) then
        return image[base .. "_const"](image, operation, other)
    else
        return image[base](image, other, operation)
    end
end

-- class methods

function Image.is_Image(thing)
    return type(thing) == "table" and getmetatable(thing) == Image.mt
end

function Image.imageize(self, value)
    -- careful! self can be nil if value is a 2D array
    if Image.is_Image(value) then
        return value
    elseif is_2D(value) then
        return Image.new_from_array(value)
    else
        return self:new_from_image(value)
    end
end

-- constructors

-- we add an unref finalizer too! be careful
function Image.new(vimage)
    local image = {}

    vobject.new(vimage)
    image.vimage = vimage
    setmetatable(image, Image.mt)

    return image
end

function Image.new_from_file(filename, ...)
    local name = vips.vips_foreign_find_load(filename)
    if name == nil then
        error(vobject.get_error())
    end

    return voperation.call(ffi.string(name), filename, unpack{...})
end

function Image.new_from_buffer(data, format_string, ...)
    local name = vips.vips_foreign_find_load_buffer(data, #data)
    if name == nil then
        error(vobject.get_error())
    end

    return voperation.call(ffi.string(name), data, unpack{...})
end

function Image.new_from_array(array, scale, offset)
    local width
    local height

    if not is_2D(array) then
        array = {array}
    end
    width = #array[1]
    height = #array

    local n = width * height
    local a = ffi.new(gvalue.pdouble_typeof, n)
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            a[x + y * width] = array[y + 1][x + 1]
        end
    end
    local vimage = vips.vips_image_new_matrix_from_array(width, height, a, n)
    local image = Image.new(vimage)

    image:set_type(gvalue.gdouble_type, "scale", scale or 1)
    image:set_type(gvalue.gdouble_type, "offset", offset or 0)

    return image
end

function Image.new_from_image(base_image, value)
    local pixel = (Image.black(1, 1) + value):cast(base_image:format())
    local image = pixel:embed(0, 0, base_image:width(), base_image:height(),
        {extend = "copy"})
    image = image:copy{
        interpretation = base_image:interpretation(),
        xres = base_image:xres(),
        yres =  base_image:yres(),
        xoffset = base_image:xoffset(),
        yoffset = base_image:yoffset()
    }

    return image
end

-- this is for undefined class methods, like Image.text
function Image.__index(table, name)
    return function(...)
        return voperation.call(name, unpack{...})
    end
end

-- overloads

function Image.mt.__add(a, b)
    a, b = swap_Image_left(a, b)

    if type(b) == "number" then
        return a:linear({1}, {b})
    elseif is_pixel(b) then
        return a:linear({1}, b)
    else
        return a:add(b)
    end
end

function Image.mt.__sub(a, b)
    if Image.is_Image(a) then
        if type(b) == "number" then
            return a:linear({1}, {-b})
        elseif is_pixel(b) then
            return a:linear({1}, map(function(x) return -x end, b))
        else
            return a:subtract(b)
        end
    else
        -- therefore a is a constant and b is an image
        if type(a) == "number" then
            return (b * -1):linear({1}, {a})
        else
            -- assume a is a pixel
            return (b * -1):linear({1}, a)
        end
    end
end

function Image.mt.__mul(a, b)
    a, b = swap_Image_left(a, b)

    if type(b) == "number" then
        return a:linear({b}, {0})
    elseif is_pixel(b) then
        return a:linear(b, {0})
    else
        return a:multiply(b)
    end
end

function Image.mt.__div(a, b)
    if Image.is_Image(a) then
        if type(b) == "number" then
            return a:linear({1 / b}, {0})
        elseif is_pixel(b) then
            return a:linear(map(function(x) return x ^ -1 end, b), {0})
        else
            return a:divide(b)
        end
    else
        -- therefore a is a constant and b is an image
        if type(a) == "number" then
            return (b ^ -1):linear({a}, {0})
        else
            -- assume a is a pixel
            return (b ^ -1):linear(a, {0})
        end
    end
end

function Image.mt.__mod(a, b)
    if not Image.is_Image(a) then
        error("constant % image not supported by libvips")
    end

    if type(b) == "number" then
        return a:remainder_const({b})
    elseif is_pixel(b) then
        return a:remainder_const(b)
    else
        return a:remainder(b)
    end
end

function Image.mt.__unm(self)
    return self * -1
end

function Image.mt.__pow(a, b)
    if Image.is_Image(a) then
        return a:pow(b)
    else
        return b:wop(a)
    end

end

function Image.mt.__eq(self, other)
    -- this is only called for pairs of images
    return self:relational(other, "equal")
end

function Image.mt.__lt(a, b)
    print("in image __lt")
    print("a =", a)
    print("b =", b)

    if Image.is_Image(a) then

        local result = a:less(b)

        print("result =", result)

        return result
        
    else
        local result = b:more(a)

        print("result =", result)

        return result
    end
end

function Image.mt.__le(a, b)
    if Image.is_Image(a) then
        return a:lesseq(b)
    else
        return b:moreeq(a)
    end
end

function Image.mt.__tostring(self)
    local result = (self:filename() or "(nil)") .. ": " ..
        self:width() .. "x" .. self:height() .. " " .. 
        self:format() .. ", " ..
        self:bands() .. " bands, " ..
        self:interpretation()

    if self:get_typeof("vips-loader") ~= 0 then
        result = result .. ", " .. self:get("vips-loader")
    end

    return result
end

    -- others are
    -- __call (image(x, y) to get pixel, perhaps)
    -- __concat (.. to join bands, perhaps?)
    -- __len (#image to get bands?)
    -- could add image[n] with number arg to extract a band


-- instance methods

-- this __index handles defined instance methods, like image:bandsplit
Image.mt.__index = {

    -- utility methods

    vobject = function(self)
        return ffi.cast(vobject.typeof, self.vimage)
    end,

    -- handy to have as instance methods too

    imageize = function(self, value)
        return Image.imageize(self, value)
    end,

    new_from_image = function(self, value)
        return Image.new_from_image(self, value)
    end,

    -- writers

    write_to_file = function(self, filename, ...)
        local name = vips.vips_foreign_find_save(filename)
        if name == nil then
            error(vobject.get_error())
        end

        return voperation.call(ffi.string(name), self, filename, unpack{...})
    end,

    write_to_buffer = function(self, format_string, ...)
        local name = vips.vips_foreign_find_save_buffer(format_string)
        if name == nil then
            error(vobject.get_error())
        end

        return voperation.call(ffi.string(name), self, unpack{...})
    end,

    -- get/set metadata

    get_typeof = function(self, name)
        return vips.vips_image_get_typeof(self.vimage, name)
    end,

    get = function(self, name)
        local pgv = gvalue.newp()

        local result = vips.vips_image_get(self.vimage, name, pgv)
        if result ~= 0 then
            error("unable to get " .. name)
        end

        local result = pgv[0]:get()

        vips.g_value_unset(pgv[0])

        return result
    end,

    set_type = function(self, gtype, name, value)
        local gv = gvalue.new()
        gv:init(gtype)
        gv:set(value)
        vips.vips_image_set(self.vimage, name, gv)
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
    -- these don't wrap well automatically, since self is held separately

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
            return voperation.call("bandjoin_const", self, other)
        else
            return voperation.call("bandjoin", {self, unpack(other)})
        end
    end,

    bandrank = function(self, other, options)
        if type(other) ~= "table" then
            other = {other}
        end

        return voperation.call("bandrank", {self, unpack(other)})
    end,

    -- convenience functions

    bandsplit = function(self)
        local result 

        result = {}
        for i = 0, self:bands() - 1 do
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
            if Image.is_Image(v) then
                match_image = v
                break
            end
        end

        if not Image.is_Image(then_value) then
            then_value = match_image:imageize(then_value)
        end

        if not Image.is_Image(else_value) then
            else_value = match_image:imageize(else_value)
        end

        return voperation.call("ifthenelse", self, 
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
    end
}

Image.mt.mt = {
    -- this is for undefined instance methods, like image:linear
    __index = function(table, name)
        return function(...)
            return voperation.call(name, unpack{...})
        end
    end
}

setmetatable(Image.mt.__index, Image.mt.mt)

return Image
