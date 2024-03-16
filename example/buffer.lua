#!/usr/bin/luajit

-- load and save images to and from memory buffers

local vips = require "vips"

if #arg ~= 1 then
    print("usage: luajit buffer.lua image-file")
    error()
end
local f = assert(io.open(arg[1], "rb"))
local content = f:read("*all")

local im = vips.Image.new_from_buffer(content, "", {access = "sequential"})

-- brighten 20%
im = (im * 1.2):cast("uchar")

-- print as mime jpg
local buffer = im:write_to_buffer(".jpg", {Q = 90})
print("Content-length: " .. #buffer)
print("Content-type: image/jpeg")
print("")
print(buffer)
