vips = require "vips"

-- uncomment for very chatty output
-- vips.log.enable(true)

--image1 = vips.Image.text("Hello <i>World!</i>", {dpi = 300})
--print()
--image2 = vips.Image.text("Hello <i>World!</i>", {dpi = 300})
--print()

image1 = vips.Image.new_from_array({1, 2, 3, 4}, 8, 9)

print("about to copy")
image1 = image1:copy()
-- image1 = image1:invert()
print("copy done!")


print("writing to x.png ...")
--image1 = image1 + 12
--image1:write_to_file("x.png")

image1 = nil
image2 = nil
collectgarbage()
print("all done!")


