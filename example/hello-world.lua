vips = require "vips"

image = vips.image.text("Hello <i>World!</i>", {dpi = 300})
image:write_to_file("x.png")
