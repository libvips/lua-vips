-- a lua version of
-- https://github.com/jcupitt/pyvips/blob/master/examples/soak-test.py
-- this should run in a steady amount of memory

local vips = require "vips"

vips.leak_set(true)
vips.cache_set_max(0)

if #arg ~= 2 then
    print("usage: luajit soak.lua image-file iterations")
    error()
end

for i = 0, tonumber(arg[2]) do
    print("loop ", i)

    local im = vips.Image.new_from_file(arg[1])
    im = im:embed(100, 100, 3000, 3000, { extend = "mirror" })
    local buf = im:write_to_buffer(".jpg")
end
