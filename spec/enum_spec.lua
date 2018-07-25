local vips = require "vips"

-- test metadata read/write
describe("enum expansions", function()
    local array, im

    setup(function()
        array = { 1, 2, 3, 4 }
        im = vips.Image.new_from_array(array)
        -- vips.log.enable(true)
    end)

    -- there are loads of expansions, just test one of each type

    it("can call pow() with a constant arg", function()
        local im2 = im:pow(2)

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 1)
        assert.are.equal(im2:avg(), (1 + 4 + 9 + 16) / 4)
    end)

    it("can call pow() with an image arg", function()
        local im2 = im:pow(im)

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 1)
        assert.are.equal(im2:avg(), (1 ^ 1 + 2 ^ 2 + 3 ^ 3 + 4 ^ 4) / 4)
    end)

    it("can call lshift()", function()
        local im2 = im:lshift(1)

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 1)
        assert.are.equal(im2:avg(), (2 + 4 + 6 + 8) / 4)
    end)

    it("can call less()", function()
        local im2 = im:less(2)

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 1)
        assert.are.equal(im2:avg(), (255 + 0 + 0 + 0) / 4)
    end)
end)
