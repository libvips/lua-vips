local vips = require "vips"

image = vips.image.new_from_file("images/Gugg_coloured.jpg")

vips.log.enable(true)

buffer = image:write_to_buffer(".jpg")

