vips = require "vips"

-- uncomment for very chatty output
-- vips.log.enable(true)

image1 = vips.Image.text("Hello <i>World!</i>", {dpi = 300})
print("writing to x.png ...")
image1:write_to_file("x.png")

