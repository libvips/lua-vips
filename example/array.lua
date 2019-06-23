-- write a vips image to lua data structure

local vips = require "vips"
local ffi = require "ffi"

-- make a tiny two band u16 image whose pixels are their coordinates
local im = vips.Image.xyz(3, 2):cast("ushort")

-- write as a C-style memory array, so band-interleaved, a set of scanlines,
-- each array element a uint8
local data = im:write_to_memory()

-- the type of each pixel
local ptype = ffi.typeof("typedef unsigned short int[$][?]", im:bands())

-- cast the memory area we got back from vips to an array of pixels
local data16 = ffi.cast(ptype, data)

-- and print! ffi arrays number from 0
for y = 0, im:height() do
    for x = 0, im:width() do
        local i = x + y * im:width()

        print("x = ", x, "y = ", y, data16[i][0], data[i][1])
    end
end
