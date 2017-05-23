local vips = require "vips"

print("array = {1, 2, 3, 4}")
array = {1, 2, 3 ,4}
local im = vips.image.new_from_array(array)
width, height = im:size()
print("width =", width)
print("height =", height)
print("scale =", im:get("scale"))
print("offset =", im:get("offset"))

print("array = {{1, 2}, {3, 4}}")
array = {{1, 2}, {3, 4}}
local im = vips.image.new_from_array(array, 12, 3)
width, height = im:size()
print("width =", width)
print("height =", height)

print("scale =", im:get("scale"))
print("offset =", im:get("offset"))
