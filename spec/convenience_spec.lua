local vips = require "vips"

-- test convenience functions
describe("test convenience functions", function()
    local array, im

    setup(function()
        array = { 1, 2, 3, 4 }
        im = vips.Image.new_from_array(array)
        -- vips.log.enable(true)
    end)

    it("can join one image bandwise", function()
        local im2 = im:bandjoin(im)

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 2)
        assert.are.equal(im2:extract_band(0):avg(), 2.5)
        assert.are.equal(im2:extract_band(1):avg(), 2.5)
    end)

    it("can join images bandwise", function()
        local im2 = im:bandjoin { im + 1, im + 2 }

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 3)
        assert.are.equal(im2:extract_band(0):avg(), 2.5)
        assert.are.equal(im2:extract_band(1):avg(), 3.5)
        assert.are.equal(im2:extract_band(2):avg(), 4.5)
    end)

    it("can join constants to images bandwise", function()
        local im2 = im:bandjoin(255)

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 2)
        assert.are.equal(im2:extract_band(0):avg(), 2.5)
        assert.are.equal(im2:extract_band(1):avg(), 255)
    end)

    it("can join images and constants bandwise", function()
        local im2 = im:bandjoin { im + 1, 255, im + 2 }

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 4)
        assert.are.equal(im2:extract_band(0):avg(), 2.5)
        assert.are.equal(im2:extract_band(1):avg(), 3.5)
        assert.are.equal(im2:extract_band(2):avg(), 255)
        assert.are.equal(im2:extract_band(3):avg(), 4.5)
    end)

    it("can join images and array constants bandwise", function()
        local im2 = im:bandjoin { im + 1, { 255, 128 } }

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 4)
        assert.are.equal(im2:extract_band(0):avg(), 2.5)
        assert.are.equal(im2:extract_band(1):avg(), 3.5)
        assert.are.equal(im2:extract_band(2):avg(), 255)
        assert.are.equal(im2:extract_band(3):avg(), 128)
    end)

    it("can call composite", function()
        if vips.version.at_least(8, 6) then
            local base = (im + { 10, 11, 12 }):copy { interpretation = "srgb" }
            local overlay = (base + 10):bandjoin(128)
            local comp = base:composite(overlay, "over")
            local pixel = comp:getpoint(0, 0)

            assert.are.equal(comp:width(), 4)
            assert.are.equal(comp:height(), 1)
            assert.are.equal(comp:bands(), 4)
            assert.is_true(math.abs(pixel[1] - 16) < 0.1)
            assert.is_true(math.abs(pixel[2] - 17) < 0.1)
            assert.is_true(math.abs(pixel[3] - 18) < 0.1)
            assert.are.equal(pixel[4], 255)
        end
    end)

    it("can call bandrank", function()
        local im2 = im:bandrank(im + 1, { index = 0 })

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 1)
        assert.are.equal(im2:extract_band(0):avg(), 2.5)
    end)

    it("can call bandsplit", function()
        local bands = im:bandjoin { im + 1, { 255, 128 } }:bandsplit()

        assert.are.equal(#bands, 4)
        assert.are.equal(bands[1]:width(), 4)
        assert.are.equal(bands[1]:height(), 1)
        assert.are.equal(bands[1]:bands(), 1)
    end)

    it("can call ifthenelse with an image and two constants", function()
        local result = im:more(2):ifthenelse(1, 2)

        assert.are.equal(result:width(), 4)
        assert.are.equal(result:height(), 1)
        assert.are.equal(result:bands(), 1)
        assert.are.equal(result:avg(), 6 / 4)
    end)

    it("can call ifthenelse with two images and one constant", function()
        local result = im:more(2):ifthenelse(im + 3, 2)

        assert.are.equal(result:width(), 4)
        assert.are.equal(result:height(), 1)
        assert.are.equal(result:bands(), 1)
        assert.are.equal(result:avg(), 17 / 4)
    end)

    it("can call hasalpha", function()
        local im1 = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg")
        local im2 = vips.Image.new_from_file("./spec/images/watermark.png")

        assert.is_false(im1:hasalpha())
        assert.is_true(im2:hasalpha())
    end)

    it("can call addalpha", function ()
        assert.are.equal(im:addalpha():avg(), 128.75)
    end)
end)
