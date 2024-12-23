local vips = require "vips"

if #arg ~= 2 then
    error("Usage: lua target.lua ~/pics/k2.png .avif > x")
end

local infilename = arg[1]
local fmt = arg[2]

local descriptor = {
    stdin = 0,
    stdout = 1,
    stderr = 2,
}

local image = vips.Image.new_from_file(infilename)
local target = vips.Target.new_to_descriptor(descriptor.stdout)
image:write_to_target(target, fmt)
