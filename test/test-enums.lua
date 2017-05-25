local vips = require "vips"

image = vips.image.new_from_file("images/Gugg_coloured.jpg")
print("on load, image =", image)

image = image:sin()

print("after sin, image =", image)

image = image + 12

print("after add, image =", image)

error()

image:write_to_file("x.jpg")
