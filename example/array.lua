#!/usr/bin/luajit

-- turn a vips image into a lua array

local vips = require "vips"
local ffi = require "ffi"

-- make a tiny two band u16 image whose pixels are their coordinates
local im = vips.Image.xyz(3, 2):cast("ushort")

-- write as a C-style memory array, so band-interleaved, a series of scanlines
--
-- "data" is a pointer of type uchar*, though the underlying memory is really
-- pairs of int16s, see above
local data = im:write_to_memory()

-- the type of each pixel ... a pair of shorts
ffi.cdef [[
  typedef struct {
      unsigned short x;
      unsigned short y;
  } pixel;
]]
-- and cast the image pointer to a 1D array of pixel structs
local ptype = ffi.typeof("pixel*")
local array = ffi.cast(ptype, data)

-- and print! ffi arrays number from 0
for y = 0, im:height() - 1 do
    for x = 0, im:width() - 1 do
        local i = x + y * im:width()

        print("x = ", x, "y = ", y, "value = ", array[i].x, array[i].y)
    end
end
