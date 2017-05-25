-- an Image class with overloads

local log = require "vips/log"
local gvalue = require "vips/gvalue"
local vobject = require "vips/vobject"
local voperation = require "vips/voperation"
local vimage = require "vips/vimage"

local Image = {}
Image.mt = {}

function Image.new(vimage)
    local image = {}

    image.vimage = vimage
    setmetatable(image, Image.mt)

    return image
end

function Image.mt.__add(left, right)
    print( "in __add!")
end

function Image.mt.__index(table, name)
    return function(...)
        return vimage[name](unpack{...})
    end
end

return Image
