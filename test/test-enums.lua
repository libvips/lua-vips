local vips = require "vips"

image = vips.image.new_from_file("images/Gugg_coloured.jpg")
print("on load, image =", image)

image = image:sin()

image = image + 12

print("format =", image:format())
print("image =", image)

image:write_to_file("x.jpg")
