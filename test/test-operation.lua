local operation = require "vips/operation"

local im = operation.call("black", 100, 200, {bands = 3})
print("  im =", im)

print("")
print("get height:")
local height = im:get("height")
print("height = ", height)
