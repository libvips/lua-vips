local ffi = require("ffi")
ffi.cdef[[
void* malloc(size_t size);
void free(void *ptr);
]]
local vips = require "vips"

-- test image new/load/etc.
describe("test image creation", function()
    setup(function()
        -- vips.log.enable(true)
    end)

    describe("test image from array", function()
        it("can make an image from a 1D array", function()
            local array = { 1, 2, 3, 4 }
            local im = vips.Image.new_from_array(array)

            assert.are.equal(im:width(), 4)
            assert.are.equal(im:height(), 1)
            assert.are.equal(im:get("scale"), 1)
            assert.are.equal(im:get("offset"), 0)
            assert.are.equal(im:avg(), 2.5)
        end)

        it("can make an image from a 2D array", function()
            local array = { { 1, 2 }, { 3, 4 } }
            local im = vips.Image.new_from_array(array)

            assert.are.equal(im:width(), 2)
            assert.are.equal(im:height(), 2)
            assert.are.equal(im:get("scale"), 1)
            assert.are.equal(im:get("offset"), 0)
            assert.are.equal(im:avg(), 2.5)
        end)

        it("can set scale and offset on an array", function()
            local array = { { 1, 2 }, { 3, 4 } }
            local im = vips.Image.new_from_array(array, 12, 3)

            assert.are.equal(im:width(), 2)
            assert.are.equal(im:height(), 2)
            assert.are.equal(im:get("scale"), 12)
            assert.are.equal(im:get("offset"), 3)
            assert.are.equal(im:avg(), 2.5)
        end)
    end)

    describe("test image from file", function()
        it("can load a jpeg from a file", function()
            local im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg")

            assert.are.equal(im:width(), 972)
            assert.are.equal(im:height(), 1296)
            assert.are.almost_equal(im:avg(), 113.96)
        end)

        it("throws error when file does not exits", function()
            assert.has_error(function()
                vips.Image.new_from_file("/path/does/not/exist/unknown.jpg")
            end, "VipsForeignLoad: file \"/path/does/not/exist/unknown.jpg\" does not exist\n")
        end)

        it("can subsample a jpeg from a file", function()
            local im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg",
                { shrink = 2 })

            assert.are.equal(im:width(), 486)
            assert.are.equal(im:height(), 648)
            assert.are.almost_equal(im:avg(), 113.979)
        end)

        it("can subsample a jpeg from a file, shrink in filename", function()
            local im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg[shrink=2]")

            assert.are.equal(im:width(), 486)
            assert.are.equal(im:height(), 648)
            assert.are.almost_equal(im:avg(), 113.979)
        end)
    end)

    describe("test image from buffer", function()
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

        it("can load a jpeg from a buffer", function()
            local im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg")
            local f = io.open("./spec/images/Gugg_coloured.jpg", "rb")
            local buf = f:read("*all")
            f:close()
            local im2 = vips.Image.new_from_buffer(buf)

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.equal(im:format(), im2:format())
            assert.are.equal(im:xres(), im2:xres())
            assert.are.equal(im:yres(), im2:yres())
        end)

        it("throws error when loading from unknown buffer", function()
            local buf = "GIF89a"

            assert.error_matches(function()
                vips.Image.new_from_buffer(buf)
            end, "unable to call VipsForeignLoadGifBuffer\ngifload_buffer: .+")
        end)

        it("can load a jpeg from a buffer, options in a table", function()
            local im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg",
                { shrink = 2 })
            local f = io.open("./spec/images/Gugg_coloured.jpg", "rb")
            local buf = f:read("*all")
            f:close()
            local im2 = vips.Image.new_from_buffer(buf, "", { shrink = 2 })

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.equal(im:format(), im2:format())
            assert.are.equal(im:xres(), im2:xres())
            assert.are.equal(im:yres(), im2:yres())
        end)

        it("can load a jpeg from a buffer, options in a table", function()
            local im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg",
                { shrink = 2 })
            local f = io.open("./spec/images/Gugg_coloured.jpg", "rb")
            local buf = f:read("*all")
            f:close()
            local im2 = vips.Image.new_from_buffer(buf, "shrink=2")

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.equal(im:format(), im2:format())
            assert.are.equal(im:xres(), im2:xres())
            assert.are.equal(im:yres(), im2:yres())
        end)
    end)

    describe("test image from memory", function()
        it("can make an image from a memory area", function()
            local width = 64
            local height = 32
            local size = width * height
            local data = ffi.new("unsigned char[?]", size)

            for y = 0, height - 1 do
                for x = 0, width - 1 do
                    data[x + y * width] = x + y
                end
            end

            local im = vips.Image.new_from_memory(data,
                width, height, 1, "uchar")

            assert.are.equal(im:width(), width)
            assert.are.equal(im:height(), height)
            assert.are.equal(im:bands(), 1)
            assert.are.equal(im:format(), "uchar")
            assert.are.equal(im:avg(), 47)
        end)

        it("can make an image from a memory area (pointer)", function()
            local width = 64
            local height = 32
            local size = width * height
            local data = ffi.gc(ffi.cast("unsigned char*", ffi.C.malloc(size)), ffi.C.free)

            for y = 0, height - 1 do
                for x = 0, width - 1 do
                    data[x + y * width] = x + y
                end
            end

            local im = vips.Image.new_from_memory_ptr(data,
                size, width, height, 1, "uchar")

            assert.are.equal(im:width(), width)
            assert.are.equal(im:height(), height)
            assert.are.equal(im:bands(), 1)
            assert.are.equal(im:format(), "uchar")
            assert.are.equal(im:avg(), 47)
        end)
    end)

    describe("test vips creators", function()
        it("can call vips_black()", function()
            local im = vips.Image.black(1, 1)

            assert.are.equal(im:width(), 1)
            assert.are.equal(im:height(), 1)
            assert.are.equal(im:bands(), 1)
            assert.are.equal(im:avg(), 0)
        end)

        it("can call operations with - in option names", function()
            local im = vips.Image.perlin(100, 100, { cell_size = 10 })

            assert.are.equal(im:width(), 100)
            assert.are.equal(im:height(), 100)
            assert.are.equal(im:bands(), 1)
        end)
    end)

    describe("test image from image", function()
        local im

        setup(function()
            im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg")
        end)

        it("can make a one-band constant image", function()
            local im2 = im:new_from_image(12)

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.equal(im:format(), im2:format())
            assert.are.equal(im:interpretation(), im2:interpretation())
            assert.are.equal(im:xres(), im2:xres())
            assert.are.equal(im:yres(), im2:yres())
            assert.are.equal(im2:bands(), 1)
            assert.are.equal(im2:avg(), 12)
        end)

        it("can make a many-band constant image", function()
            local im2 = im:new_from_image({ 1, 2, 3, 4 })

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.equal(im:format(), im2:format())
            assert.are.equal(im:interpretation(), im2:interpretation())
            assert.are.equal(im:xres(), im2:xres())
            assert.are.equal(im:yres(), im2:yres())
            assert.are.equal(im2:bands(), 4)
            assert.are.equal(im2:avg(), 2.5)
        end)
    end)
end)
