-- an Image class with overloads

local log = require "vips/log"
local gvalue = require "vips/gvalue"
local vobject = require "vips/vobject"
local voperation = require "vips/voperation"
local vimage = require "vips/vimage"

local Image = {}

function Image.new(vimage)
    local image = {}

    image.vimage = vimage
    setmetatable(image, Image)

    return image
end

local function image_to_left(left, right)
    if Image.is_image(left) then
        return left, right
    elseif Image.is_image(right) then
        return right, left
    else
        error("must have one image argument")
    end
end

-- either a single number, or a table of numbers
local function is_pixel(value)
    return type(value) == "number" or
        (type(value) == "table" and not Image.is_image(value))
end

function Image.__add(a, b)
    print("in __add!")
    print("a =")
    log.print_r(a)
    print("a metatable =", getmetatable(a))
    print("Image =", Image)
    print("b =")
    log.print_r(b)
    print("b metatable =", getmetatable(b))

    a, b = image_to_left(a, b)

    if type(b) == "number" then
        return a:linear({1}, {b})
    elseif is_pixel(b) then
        return a:linear({1}, b)
    else
        return a:add(b)
    end
end

function Image.__index(table, name)
    print("in Image.__index, name =", name)

    return function(...)
        return vimage[name](unpack{...})
    end
end

setmetatable(Image, Image)

return Image
