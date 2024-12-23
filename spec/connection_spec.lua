local vips = require "vips"
local ffi = require "ffi"

local JPEG_FILE = "./spec/images/Gugg_coloured.jpg"
local TMP_FILE = ffi.os == "Windows" and os.getenv("TMP") .. "\\x.png" or "/tmp/x.png"

describe("test connection", function()
    setup(function()
        -- vips.log.enable(true)
    end)

    describe("to file target", function()
        local target

        setup(function()
            target = vips.Target.new_to_file(TMP_FILE)
        end)

        it("can create image from file source", function()
            local source = vips.Source.new_from_file(JPEG_FILE)
            local image = vips.Image.new_from_source(source, '', { access = 'sequential' })
            image:write_to_target(target, '.png')

            local image1 = vips.Image.new_from_file(JPEG_FILE, { access = 'sequential' })
            local image2 = vips.Image.new_from_file(TMP_FILE, { access = 'sequential' })
            assert.is_true((image1 - image2):abs():max() < 10)
        end)

        it("can create image from memory source", function()
            local file = assert(io.open(JPEG_FILE, "rb"))
            local content = file:read("*a")
            file:close()
            local mem = ffi.new("unsigned char[?]", #content)
            ffi.copy(mem, content, #content)
            local source = vips.Source.new_from_memory(mem)
            local image = vips.Image.new_from_source(source, '', { access = 'sequential' })
            image:write_to_target(target, '.png')

            local image1 = vips.Image.new_from_file(JPEG_FILE, { access = 'sequential' })
            local image2 = vips.Image.new_from_file(TMP_FILE, { access = 'sequential' })
            assert.is_true((image1 - image2):abs():max() < 10)
        end)
    end)
end)
