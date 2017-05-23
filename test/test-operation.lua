local operation = require "vips/operation"

-- we need to include this as well, since we want to try getting fields from the
-- image
local image = require "vips/image"

local im = operation.call("black", 100, 200, {bands = 3})
print("  im =", im)

print("")
print("get height:")
local height = im:get("height")
print("height = ", height)
