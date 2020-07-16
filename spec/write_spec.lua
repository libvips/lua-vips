local ffi = require("ffi")
local vips = require "vips"

-- test image writers
describe("test image write", function()

    setup(function()
        -- vips.log.enable(true)
    end)

    describe("to file", function()
        local array = { 1, 2, 3, 4 }
        local im = vips.Image.new_from_array(array)
        local tmp_png_filename = "/tmp/x.png"
        local tmp_jpg_filename = "/tmp/x.jpg"

        teardown(function()
            os.remove(tmp_png_filename)
            os.remove(tmp_jpg_filename)
        end)

        it("can save and then load a png", function()
            im:write_to_file(tmp_png_filename)
            local im2 = vips.Image.new_from_file(tmp_png_filename)

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.equal(im:avg(), im2:avg())
        end)

        it("can save and then load a jpg with an option", function()
            im:write_to_file(tmp_jpg_filename, { Q = 90 })
            local im2 = vips.Image.new_from_file(tmp_jpg_filename)

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.almost_equal(im:avg(), im2:avg())
        end)
    end)

    describe("to buffer", function()
        it("can write a jpeg to buffer", function()
            local im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg")
            local buf = im:write_to_buffer(".jpg")
            local f = io.open("x.jpg", "w+b")
            f:write(buf)
            f:close()
            local im2 = vips.Image.new_from_file("x.jpg")

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.equal(im:format(), im2:format())
            assert.are.equal(im:xres(), im2:xres())
            assert.are.equal(im:yres(), im2:yres())
            -- remove test file
            os.remove("x.jpg")
        end)

        it("can write a jpeg to buffer with an option", function()
            local im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg")
            local buf = im:write_to_buffer(".jpg")
            local buf2 = im:write_to_buffer(".jpg", { Q = 100 })

            assert.is.True(#buf2 > #buf)
        end)

        it("can write an image to a memory area", function()
            local im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg")
            local mem = im:write_to_memory()

            assert.are.equal(im:width() * im:height() * 3, ffi.sizeof(mem))
        end)

        it("can read an image back from a memory area", function()
            local im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg")
            local mem = im:write_to_memory()
            assert.are.equal(im:width() * im:height() * 3, ffi.sizeof(mem))
            local im2 = vips.Image.new_from_memory(mem,
                im:width(), im:height(), im:bands(), im:format())

            assert.are.equal(im:avg(), im2:avg())
        end)

        it("can write an image to a memory area (no copy)", function()
            local im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg")
            local ptr, size = im:write_to_memory_ptr()

            assert.are.equal(im:width() * im:height() * 3, size)
        end)

        it("can read an image back from a memory area (no copy)", function()
            local im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg")
            local ptr, size = im:write_to_memory_ptr()
            assert.are.equal(im:width() * im:height() * 3, size)
            local im2 = vips.Image.new_from_memory_ptr(ptr,
                size, im:width(), im:height(), im:bands(), im:format())

            assert.are.equal(im:avg(), im2:avg())
        end)
    end)

    describe("MODIFY args", function()
        it("can draw a circle on an image", function()
            local im = vips.Image.black(101, 101)
            local im2 = im:draw_circle(255, 50, 50, 50, { fill = true })

            assert.are.equal(im2:width(), 101)
            assert.are.equal(im2:height(), 101)
            assert.are.almost_equal(im2:avg(), 255 * 3.1415927 / 4, 0.2)
        end)

        it("each draw op makes a new image", function()
            local im = vips.Image.black(101, 101)
            local im2 = im:draw_circle(255, 50, 50, 50, { fill = true })
            local im3 = im2:draw_circle(0, 50, 50, 40, { fill = true })

            assert.are.equal(im2:width(), 101)
            assert.are.equal(im2:height(), 101)
            assert.are.almost_equal(im2:avg(), 255 * 3.1415927 / 4, 0.2)
            assert.is.True(im3:avg() < im2:avg())
        end)
    end)
end)
