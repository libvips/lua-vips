local vips = require "vips"

-- test gvalue
describe("test gvalue", function()
    local im, values

    setup(function()
        im = vips.Image.new_from_file("./spec/images/Gugg_coloured.jpg")
        values = im:bandsplit()
        -- vips.log.enable(true)
    end)

    it("can set/get an int-valued gvalue", function()
        local value = vips.gvalue()
        value:init(vips.gvalue.gint_type)
        value:set(12)
        assert.are.equal(12, value:get())
    end)

    it("can set/get a string-valued gvalue", function()
        local value = vips.gvalue()
        value:init(vips.gvalue.gstr_type)
        value:set("banana")
        assert.are.equal("banana", value:get())
    end)

    it("can set/get a bool-valued gvalue", function()
        local value = vips.gvalue()
        value:init(vips.gvalue.gbool_type)
        value:set(true)
        assert.are.equal(1, value:get())
    end)

    it("can set/get a double-valued gvalue", function()
        local value = vips.gvalue()
        value:init(vips.gvalue.gdouble_type)
        value:set(3.1415)
        assert.are.equal(3.1415, value:get())
    end)

    it("can set/get a enum-valued gvalue", function()
        if vips.version.at_least(8, 6) then
            local value = vips.gvalue()
            value:init(vips.gvalue.blend_mode_type)
            -- need to map str -> int by hand, since the mode arg is actually
            -- arrayint
            value:set(vips.gvalue.to_enum(vips.gvalue.blend_mode_type, 'over'))
            assert.are.equal('over', value:get())
        end
    end)

    it("can set/get a array-int-valued gvalue", function()
        local value = vips.gvalue()
        value:init(vips.gvalue.array_int_type)
        value:set({ 1, 2, 3 })
        assert.are.same({ 1, 2, 3 }, value:get())
    end)

    it("can set/get a array-double-valued gvalue", function()
        local value = vips.gvalue()
        value:init(vips.gvalue.array_double_type)
        value:set({ 1.1, 2.1, 3.1 })
        assert.are.same({ 1.1, 2.1, 3.1 }, value:get())
    end)

    it("can set/get a image-valued gvalue", function()
        local value = vips.gvalue()
        value:init(vips.gvalue.image_type)
        value:set(im)
        assert.are.same(im, value:get())
    end)

    it("can set/get a array-image-valued gvalue", function()
        local value = vips.gvalue()
        value:init(vips.gvalue.array_image_type)
        value:set(values)
        assert.are.same(values, value:get())
    end)
end)
