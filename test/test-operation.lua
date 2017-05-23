local vips = require "vips"

local im = vips.operation.call("black", 100, 200, {bands = 3})
print("  im =", im)

print("")
print("get height:")
local height = im:get("height")
print("height = ", height)
