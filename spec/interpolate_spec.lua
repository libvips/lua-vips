local vips = require "vips"

-- test image interpolation
describe("image interpolation", function()
    setup(function()
        -- vips.log.enable(true)
    end)

    it("can rotate an image using nearest interpolator", function()
        local interpolate = vips.Interpolate.new_from_name("nearest")
        local original = {
            { 1, 2, 3 },
            { 4, 5, 6 },
            { 7, 8, 9 },
        }
        local rotated = {
            { 0.0, 0.0, 1.0, 0.0 },
            { 0.0, 0.0, 1.0, 2.0 },
            { 0.0, 7.0, 5.0, 3.0 },
            { 0.0, 8.0, 9.0, 6.0 }
        }
        local im = vips.Image.new_from_array(original)
        local rot = im:rotate(45, { interpolate = interpolate })
        assert.are.equal(rot:width(), 4)
        assert.are.equal(rot:height(), 4)
        assert.are.equal(rot:bands(), 1)
        for x = 1, 4 do
            for y = 1, 4 do
                assert.are_equal(rot(x - 1, y - 1), rotated[y][x])
            end
        end
    end)
end)
