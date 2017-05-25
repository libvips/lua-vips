local vips = require "vips"

image = vips.image.new_from_file("images/Gugg_coloured.jpg")

image = image:sin()

print("format =", image:format())

image:write_to_file("x.jpg")
