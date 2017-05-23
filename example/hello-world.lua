vips = require "vips"

-- uncomment for very chatty output
-- vips.log.enable(true)

image = vips.image.text("Hello <i>World!</i>", {dpi = 300})
image:write_to_file("x.png")
