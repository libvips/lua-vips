local vips = require "vips"
local ffi = require "ffi"

local UHDR_FILE = "./spec/images/uhdr.jpg"
-- test metadata read/write
describe("metadata", function()
    local array, im
    local tmp_vips_filename = ffi.os == "Windows" and os.getenv("TMP") .. "\\x.v" or "/tmp/x.v"

    setup(function()
        array = { 1, 2, 3, 4 }
        im = vips.Image.new_from_array(array)
        -- vips.log.enable(true)
    end)

    teardown(function()
        os.remove(tmp_vips_filename)
    end)

    it("can set/get int", function()
        local im2 = im:copy()

        im2:set_type(vips.gvalue.gint_type, "banana", 12)
        assert.are.equal(im2:get("banana"), 12)
    end)

    it("can remove metadata", function()
        local im2 = im:copy()

        im2:set_type(vips.gvalue.gint_type, "banana", 12)
        im2:remove("banana")
        assert.are.equal(im2:get_typeof("banana"), 0)
    end)

    it("can set/get double", function()
        local im2 = im:copy()

        im2:set_type(vips.gvalue.gdouble_type, "banana", 3.1415)
        assert.are.equal(im2:get("banana"), 3.1415)
    end)

    it("can set/get string", function()
        local im2 = im:copy()

        im2:set_type(vips.gvalue.gstr_type, "banana", "tasty one")
        assert.are.same(im2:get("banana"), "tasty one")
    end)

    it("can set/get through vips file save/load", function()
        local im2 = im:copy()

        im2:set_type(vips.gvalue.gint_type, "banana", 12)
        im2:write_to_file(tmp_vips_filename)
        local im3 = vips.Image.new_from_file(tmp_vips_filename)
        assert.are.same(im3:get("banana"), im2:get("banana"))
    end)

    it("can get property enums as strings", function()
        local im2 = im:copy()

        assert.are.same(im2:format(), "double")
    end)

    it("can set gainmap", function()
        if vips.version.at_least(8, 18) and vips.has("uhdrload") then
            local function crop_gainmap(image)
                local gainmap = image:get_gainmap()

                if gainmap then
                    local new_gainmap = gainmap:crop(0, 0, 10, 10)
                    image = image:copy()
                    image:set_type(vips.gvalue.image_type, "gainmap", new_gainmap)
                end

                return image
            end

            local image = vips.Image.new_from_file(UHDR_FILE)
            image = crop_gainmap(image)
            local buf = image:write_to_buffer(".jpg")
            local new_image = vips.Image.new_from_buffer(buf, "")
            local new_gainmap = new_image:get_gainmap()

            assert.are.same(new_gainmap:width(), 10)
        end
    end)
end)
