vips = require "vips"

-- uncomment for very chatty output
-- vips.log.enable(true)

image = vips.Image.text("Hello <i>World!</i>", {dpi = 300})
image = image:invert()
image:write_to_file("x.png")
