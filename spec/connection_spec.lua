local vips = require "vips"
local ffi = require "ffi"

local JPEG_FILE = "./spec/images/Gugg_coloured.jpg"
-- test gvalue
describe("test connection", function()

    setup(function()
        -- vips.log.enable(true)
    end)

    describe("to file target", function()
        it("can create image from file source and write to file target", function()
            local source = vips.Source.new_from_file(JPEG_FILE)
            local image = vips.Image.new_from_source(source, '', { access = 'sequential' })
            local filename = ffi.os == "Windows" and os.getenv("TMP") .. "\\x.png" or "/tmp/x.png"
            local target = vips.Target.new_to_file(filename)
            image:write_to_target(target, '.png')

            local image1 = vips.Image.new_from_file(JPEG_FILE, { access = 'sequential' })
            local image2 = vips.Image.new_from_file(filename, { access = 'sequential' })
            assert.is_true((image1 - image2):abs():max() < 10)
        end)
    end)
end)
