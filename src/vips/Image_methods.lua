-- an Image class with overloads

local ffi = require "ffi"

local verror = require "vips.verror"
local version = require "vips.version"
local gvalue = require "vips.gvalue"
local vobject = require "vips.vobject"
local voperation = require "vips.voperation"
local Image = require "vips.Image"

local type = type
local error = error
local pairs = pairs
local ipairs = ipairs
local unpack = unpack or table.unpack
local rawget = rawget
local setmetatable = setmetatable
local getmetatable = getmetatable

local vips_lib
local gobject_lib
local glib_lib
if ffi.os == "Windows" then
    vips_lib = ffi.load("libvips-42.dll")
    gobject_lib = ffi.load("libgobject-2.0-0.dll")
    glib_lib = ffi.load("libglib-2.0-0.dll")
else
    vips_lib = ffi.load("vips")
    gobject_lib = vips_lib
    glib_lib = vips_lib
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
        return image[base .. "_const"](image, operation, { other })
    elseif is_pixel(other) then
        return image[base .. "_const"](image, operation, other)
    else
        return image[base](image, other, operation)
    end
end

-- turn a string from libvips that must be g_free()d into a lua string
local function to_string_copy(vips_string)
    local lua_string = ffi.string(vips_string)
    glib_lib.g_free(vips_string)
    return lua_string
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

    image.vimage = vobject.new(vimage)

    return setmetatable(image, Image.mt)
end

function Image.find_load(filename)
    local name = vips_lib.vips_foreign_find_load(filename)
    if name == nil then
        return nil
    else
        return ffi.string(name)
    end
end

function Image.new_from_file(vips_filename, ...)
    local filename = to_string_copy(vips_lib.vips_filename_get_filename(vips_filename))
    local options = to_string_copy(vips_lib.vips_filename_get_options(vips_filename))

    local name = Image.find_load(filename)
    if name == nil then
        error(verror.get())
    end

    return voperation.call(name, options, filename, unpack { ... })
end

function Image.find_load_buffer(data)
    local name = vips_lib.vips_foreign_find_load_buffer(data, #data)
    if name == nil then
        return nil
    else
        return ffi.string(name)
    end
end

function Image.new_from_buffer(data, options, ...)
    local name = Image.find_load_buffer(data)
    if name == nil then
        error(verror.get())
    end

    return voperation.call(name, options or "", data, unpack { ... })
end

function Image.new_from_memory_ptr(data, size, width, height, bands, format)
    local format_value = gvalue.to_enum(gvalue.band_format_type, format)
    local vimage = vips_lib.vips_image_new_from_memory(data, size,
            width, height, bands, format_value)
    if vimage == nil then
        error(verror.get())
    end
    return Image.new(vimage)
end

function Image.new_from_memory(data, width, height, bands, format)
    local image = Image.new_from_memory_ptr(data, ffi.sizeof(data), width, height, bands, format)
    -- libvips is using the memory we passed in: save a pointer to the memory
    -- block to try to stop it being GCd
    image._data = data
    return image
end

function Image.new_from_array(array, scale, offset)
    if not is_2D(array) then
        array = { array }
    end
    local width = #array[1]
    local height = #array

    local n = width * height
    local arr = {}
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            arr[x + y * width] = array[y + 1][x + 1]
        end
    end
    local a = ffi.new(gvalue.double_arr_typeof, n, arr)

    local vimage = vips_lib.vips_image_new_matrix_from_array(width,
            height, a, n)
    local image = Image.new(vimage)

    image:set_type(gvalue.gdouble_type, "scale", scale or 1.0)
    image:set_type(gvalue.gdouble_type, "offset", offset or 0.0)

    return image
end

function Image.new_from_image(base_image, value)
    local pixel = (Image.black(1, 1) + value):cast(base_image:format())
    local image = pixel:embed(0, 0, base_image:width(), base_image:height(),
            { extend = "copy" })
    image = image:copy {
        interpretation = base_image:interpretation(),
        xres = base_image:xres(),
        yres = base_image:yres(),
        xoffset = base_image:xoffset(),
        yoffset = base_image:yoffset()
    }

    return image
end

-- overloads

function Image.mt.__add(a, b)
    a, b = swap_Image_left(a, b)

    if type(b) == "number" then
        return a:linear({ 1 }, { b })
    elseif is_pixel(b) then
        return a:linear({ 1 }, b)
    else
        return a:add(b)
    end
end

function Image.mt.__sub(a, b)
    if Image.is_Image(a) then
        if type(b) == "number" then
            return a:linear({ 1 }, { -b })
        elseif is_pixel(b) then
            return a:linear({ 1 }, map(function(x)
                return -x
            end, b))
        else
            return a:subtract(b)
        end
    else
        -- therefore a is a constant and b is an image
        if type(a) == "number" then
            return (b * -1):linear({ 1 }, { a })
        else
            -- assume a is a pixel
            return (b * -1):linear({ 1 }, a)
        end
    end
end

function Image.mt.__mul(a, b)
    a, b = swap_Image_left(a, b)

    if type(b) == "number" then
        return a:linear({ b }, { 0 })
    elseif is_pixel(b) then
        return a:linear(b, { 0 })
    else
        return a:multiply(b)
    end
end

function Image.mt.__div(a, b)
    if Image.is_Image(a) then
        if type(b) == "number" then
            return a:linear({ 1 / b }, { 0 })
        elseif is_pixel(b) then
            return a:linear(map(function(x)
                return x ^ -1
            end, b), { 0 })
        else
            return a:divide(b)
        end
    else
        -- therefore a is a constant and b is an image
        if type(a) == "number" then
            return (b ^ -1):linear({ a }, { 0 })
        else
            -- assume a is a pixel
            return (b ^ -1):linear(a, { 0 })
        end
    end
end

function Image.mt.__mod(a, b)
    if not Image.is_Image(a) then
        error("constant % image not supported by libvips")
    end

    if type(b) == "number" then
        return a:remainder_const({ b })
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

-- unfortunately, lua does not let you return non-bools from <, >, <=, >=, ==,
-- ~=, so there's no point overloading these ... call :more(2) etc. instead

function Image.mt:__tostring()
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

function Image.mt:__call(x, y)
    -- getpoint() will return a table for a pixel
    return unpack(self:getpoint(x, y))
end

function Image.mt:__concat(other)
    return self:bandjoin(other)
end

-- instance methods

local Image_method = {}

function Image_method:vobject()
    -- TODO: Could we use `self.vimage.parent_instance` here?
    return ffi.cast(vobject.typeof, self.vimage)
end

-- handy to have as instance methods too

function Image_method:imageize(value)
    return Image.imageize(self, value)
end

function Image_method:new_from_image(value)
    return Image.new_from_image(self, value)
end

function Image_method:copy_memory()
    local vimage = vips_lib.vips_image_copy_memory(self.vimage)
    if vimage == nil then
        error(verror.get())
    end
    return Image.new(vimage)
end

-- writers

function Image_method:write_to_file(vips_filename, ...)
    local filename = to_string_copy(vips_lib.vips_filename_get_filename(vips_filename))
    local options = to_string_copy(vips_lib.vips_filename_get_options(vips_filename))
    local name = vips_lib.vips_foreign_find_save(filename)
    if name == nil then
        error(verror.get())
    end

    return voperation.call(ffi.string(name), options,
            self, filename, unpack { ... })
end

function Image_method:write_to_buffer(format_string, ...)
    local options = to_string_copy(vips_lib.vips_filename_get_options(format_string))
    local name = vips_lib.vips_foreign_find_save_buffer(format_string)
    if name == nil then
        error(verror.get())
    end

    return voperation.call(ffi.string(name), options, self, unpack { ... })
end

function Image_method:write_to_memory()
    local psize = ffi.new(gvalue.psize_typeof, 1)
    local vips_memory = vips_lib.vips_image_write_to_memory(self.vimage, psize)
    local size = psize[0]

    local lua_memory = ffi.new(gvalue.mem_typeof, size)
    ffi.copy(lua_memory, vips_memory, size)
    glib_lib.g_free(vips_memory)

    return lua_memory
end

function Image_method:write_to_memory_ptr()
    local psize = ffi.new(gvalue.psize_typeof, 1)
    local vips_memory = vips_lib.vips_image_write_to_memory(self.vimage, psize)

    return ffi.gc(vips_memory, glib_lib.g_free), psize[0]
end

-- get/set metadata

function Image_method:get_typeof(name)
    -- on libvips 8.4 and earlier, we need to fetch the type via
    -- our superclass get_typeof(), since vips_image_get_typeof() returned
    -- enum properties as ints
    if not version.at_least(8, 5) then
        local vob = self:vobject()
        local gtype = vob:get_typeof(name)
        if gtype ~= 0 then
            return vob:get_type(name, gtype)
        end

        -- we must clear the error buffer after vobject typeof fails
        verror.get()
    end

    return vips_lib.vips_image_get_typeof(self.vimage, name)
end

function Image_method:get(name)
    -- on libvips 8.4 and earlier, we need to fetch gobject properties via
    -- our superclass get(), since vips_image_get() returned enum properties
    -- as ints
    if not version.at_least(8, 5) then
        local vo = self:vobject()
        local gtype = vo:get_typeof(name)
        if gtype ~= 0 then
            return vo:get(name)
        end

        -- we must clear the error buffer after vobject typeof fails
        verror.get()
    end

    local pgv = gvalue(true)

    local result = vips_lib.vips_image_get(self.vimage, name, pgv)
    if result ~= 0 then
        error("unable to get " .. name)
    end

    result = pgv[0]:get()
    gobject_lib.g_value_unset(pgv[0])

    return result
end

function Image_method:set_type(gtype, name, value)
    local pgv = gvalue(true)
    pgv[0]:init(gtype)
    pgv[0]:set(value)
    vips_lib.vips_image_set(self.vimage, name, pgv)
    gobject_lib.g_value_unset(pgv[0])
end

function Image_method:set(name, value)
    local gtype = self:get_typeof(name)
    self:set_type(gtype, name, value)
end

function Image_method:remove(name)
    return vips_lib.vips_image_remove(self.vimage, name) ~= 0
end

-- standard header fields

function Image_method:width()
    return self:get("width")
end

function Image_method:height()
    return self:get("height")
end

function Image_method:size()
    return self:width(), self:height()
end

function Image_method:bands()
    return self:get("bands")
end

function Image_method:format()
    return self:get("format")
end

function Image_method:interpretation()
    return self:get("interpretation")
end

function Image_method:xres()
    return self:get("xres")
end

function Image_method:yres()
    return self:get("yres")
end

function Image_method:xoffset()
    return self:get("xoffset")
end

function Image_method:yoffset()
    return self:get("yoffset")
end

function Image_method:filename()
    return self:get("filename")
end

-- many-image input operations
--
-- these don't wrap well automatically, since self is held separately

function Image_method:bandjoin(other, options)
    -- allow a single untable arg as well
    if type(other) == "number" or Image.is_Image(other) then
        other = { other }
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
        return voperation.call("bandjoin_const", "", self, other, options)
    else
        return voperation.call("bandjoin", "", { self, unpack(other) }, options)
    end
end

function Image_method:bandrank(other, options)
    if type(other) ~= "table" then
        other = { other }
    end

    return voperation.call("bandrank", "", { self, unpack(other) }, options)
end

function Image_method:composite(other, mode, options)
    -- allow a single untable arg as well
    if type(other) == "number" or Image.is_Image(other) then
        other = { other }
    end
    if type(mode) ~= "table" then
        mode = { mode }
    end

    -- need to map str -> int by hand, since the mode arg is actually
    -- arrayint
    for i = 1, #mode do
        mode[i] = gvalue.to_enum(gvalue.blend_mode_type, mode[i])
    end

    return voperation.call("composite", "", { self, unpack(other) }, mode, options)
end

-- convenience functions

function Image_method:bandsplit()
    local result

    result = {}
    for i = 0, self:bands() - 1 do
        result[i + 1] = self:extract_band(i)
    end

    return result
end

-- special behaviour wrappers

function Image_method:ifthenelse(then_value, else_value, options)
    -- We need different imageize rules for this. We need then_value
    -- and else_value to match each other first, and only if they
    -- are both constants do we match to self.

    local match_image

    for _, v in pairs({ then_value, else_value, self }) do
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

    return voperation.call("ifthenelse", "", self, then_value, else_value, options)
end

-- enum expansions

function Image_method:pow(other)
    return call_enum(self, other, "math2", "pow")
end

function Image_method:wop(other)
    return call_enum(self, other, "math2", "wop")
end

function Image_method:lshift(other)
    return call_enum(self, other, "boolean", "lshift")
end

function Image_method:rshift(other)
    return call_enum(self, other, "boolean", "rshift")
end

function Image_method:andimage(other)
    return call_enum(self, other, "boolean", "and")
end

function Image_method:orimage(other)
    return call_enum(self, other, "boolean", "or")
end

function Image_method:eorimage(other)
    return call_enum(self, other, "boolean", "eor")
end

function Image_method:less(other)
    return call_enum(self, other, "relational", "less")
end

function Image_method:lesseq(other)
    return call_enum(self, other, "relational", "lesseq")
end

function Image_method:more(other)
    return call_enum(self, other, "relational", "more")
end

function Image_method:moreeq(other)
    return call_enum(self, other, "relational", "moreeq")
end

function Image_method:equal(other)
    return call_enum(self, other, "relational", "equal")
end

function Image_method:noteq(other)
    return call_enum(self, other, "relational", "noteq")
end

function Image_method:floor()
    return self:round("floor")
end

function Image_method:ceil()
    return self:round("ceil")
end

function Image_method:rint()
    return self:round("rint")
end

function Image_method:bandand()
    return self:bandbool("and")
end

function Image_method:bandor()
    return self:bandbool("or")
end

function Image_method:bandeor()
    return self:bandbool("eor")
end

function Image_method:real()
    return self:complexget("real")
end

function Image_method:imag()
    return self:complexget("imag")
end

function Image_method:polar()
    return self:complex("polar")
end

function Image_method:rect()
    return self:complex("rect")
end

function Image_method:conj()
    return self:complex("conj")
end

function Image_method:sin()
    return self:math("sin")
end

function Image_method:cos()
    return self:math("cos")
end

function Image_method:tan()
    return self:math("tan")
end

function Image_method:asin()
    return self:math("asin")
end

function Image_method:acos()
    return self:math("acos")
end

function Image_method:atan()
    return self:math("atan")
end

function Image_method:exp()
    return self:math("exp")
end

function Image_method:exp10()
    return self:math("exp10")
end

function Image_method:log()
    return self:math("log")
end

function Image_method:log10()
    return self:math("log10")
end

function Image_method:erode(mask)
    return self:morph(mask, "erode")
end

function Image_method:dilate(mask)
    return self:morph(mask, "dilate")
end

function Image_method:fliphor()
    return self:flip("horizontal")
end

function Image_method:flipver()
    return self:flip("vertical")
end

function Image_method:rot90()
    return self:rot("d90")
end

function Image_method:rot180()
    return self:rot("d180")
end

function Image_method:rot270()
    return self:rot("d270")
end

-- this is for undefined class / instance methods, like Image.text or image:avg
local fall_back = function(name)
    return function(...)
        return voperation.call(name, "", unpack { ... })
    end
end

function Image.mt.__index(_, name)
    -- try to get instance method otherwise fallback to voperation
    return rawget(Image_method, name) or fall_back(name)
end

return setmetatable(Image, {
    __index = function(_, name)
        -- undefined class methods
        return fall_back(name)
    end
})
