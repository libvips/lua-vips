-- test image new/load/etc.

require 'busted.runner'()

describe("test overloads", function()
    vips = require("vips")
    -- vips.log.enable(true)

    local array = {1, 2, 3, 4}
    local im = vips.Image.new_from_array(array)

    describe("test add", function()

        it("can add an image and a single constant", function()
            local im2 = im + 12

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 1)
            assert.are.equal(im2:avg(), 12 + im:avg())
        end)

        it("can add a reversed image and a single constant", function()
            local im2 = 12 + im

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 1)
            assert.are.equal(im2:avg(), 12 + im:avg())
        end)

        it("can add an image and an array constant", function()
            local im2 = im + {12, 13, 14}

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 3)
            assert.are.equal(im2:avg(), 13 + im:avg())
        end)

        it("can add two images", function()
            local im2 = im + im

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 1)
            assert.are.equal(im2:avg(), 2 * im:avg())
        end)

    end)

end)
