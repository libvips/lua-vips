-- manipulate GValue objects from lua
-- pull in gobject via the vips library

local ffi = require "ffi"

local verror = require "vips.verror"
local version = require "vips.version"
local Image = require "vips.Image"

local vips_lib
local gobject_lib
local glib_lib
if ffi.os == "Windows" then
    vips_lib = ffi.load("libvips-42.dll")
    gobject_lib = ffi.load("libgobject-2.0-0.dll")
    glib_lib = ffi.load("libglib-2.0-0.dll")
else
    vips_lib = ffi.load("vips")
    gobject_lib = vips_lib
    glib_lib = vips_lib
end

if version.at_least(8, 6) then
    vips_lib.vips_blend_mode_get_type()
end
vips_lib.vips_band_format_get_type()

local gvalue = {}
local gvalue_mt = {
    __gc = function(gv)
        gobject_lib.g_value_unset(gv)
    end,

    __index = {
        -- make ffi constructors we can reuse
        gv_typeof = ffi.typeof("GValue"),
        pgv_typeof = ffi.typeof("GValue[1]"),
        image_typeof = ffi.typeof("VipsImage*"),
        pint_typeof = ffi.typeof("int[?]"),
        pdouble_typeof = ffi.typeof("double[?]"),
        psize_typeof = ffi.typeof("size_t[?]"),
        mem_typeof = ffi.typeof("unsigned char[?]"),

        -- look up some common gtypes at init for speed
        gbool_type = gobject_lib.g_type_from_name("gboolean"),
        gint_type = gobject_lib.g_type_from_name("gint"),
        gdouble_type = gobject_lib.g_type_from_name("gdouble"),
        gstr_type = gobject_lib.g_type_from_name("gchararray"),
        genum_type = gobject_lib.g_type_from_name("GEnum"),
        gflags_type = gobject_lib.g_type_from_name("GFlags"),
        image_type = gobject_lib.g_type_from_name("VipsImage"),
        array_int_type = gobject_lib.g_type_from_name("VipsArrayInt"),
        array_double_type = gobject_lib.g_type_from_name("VipsArrayDouble"),
        array_image_type = gobject_lib.g_type_from_name("VipsArrayImage"),
        refstr_type = gobject_lib.g_type_from_name("VipsRefString"),
        blob_type = gobject_lib.g_type_from_name("VipsBlob"),
        band_format_type = gobject_lib.g_type_from_name("VipsBandFormat"),
        blend_mode_type = version.at_least(8, 6) and
                gobject_lib.g_type_from_name("VipsBlendMode") or 0,

        new = function()
            -- with no init, this will initialize with 0, which is what we need
            -- for a blank GValue
            return ffi.new(gvalue.gv_typeof)
        end,

        to_enum = function(gtype, value)
            -- turn a string into an int, ready to be passed into libvips
            local enum_value

            if type(value) == "string" then
                enum_value = vips_lib.vips_enum_from_nick("lua-vips",
                    gtype, value)

                if enum_value < 0 then
                    error("no such enum " .. value .. "\n" .. verror.get())
                end
            else
                enum_value = value
            end

            return enum_value
        end,

        -- this won't be unset() automatically! you need to
        -- g_value_unset() yourself after calling
        newp = function()
            return ffi.new(gvalue.pgv_typeof)
        end,

        type_name = function(gtype)
            return ffi.string(gobject_lib.g_type_name(gtype))
        end,

        init = function(gv, gtype)
            gobject_lib.g_value_init(gv, gtype)
        end,

        set = function(gv, value)
            local gtype = gv.gtype
            local fundamental = gobject_lib.g_type_fundamental(gtype)

            if gtype == gvalue.gbool_type then
                gobject_lib.g_value_set_boolean(gv, value)
            elseif gtype == gvalue.gint_type then
                gobject_lib.g_value_set_int(gv, value)
            elseif gtype == gvalue.gdouble_type then
                gobject_lib.g_value_set_double(gv, value)
            elseif fundamental == gvalue.genum_type then
                gobject_lib.g_value_set_enum(gv, gvalue.to_enum(gtype, value))
            elseif fundamental == gvalue.gflags_type then
                gobject_lib.g_value_set_flags(gv, value)
            elseif gtype == gvalue.gstr_type then
                gobject_lib.g_value_set_string(gv, value)
            elseif gtype == gvalue.refstr_type then
                gobject_lib.vips_value_set_ref_string(gv, value)
            elseif gtype == gvalue.image_type then
                gobject_lib.g_value_set_object(gv, value.vimage)
            elseif gtype == gvalue.array_int_type then
                if type(value) == "number" then
                    value = { value }
                end

                local n = #value
                local a = ffi.new(gvalue.pint_typeof, n, value)

                vips_lib.vips_value_set_array_int(gv, a, n)
            elseif gtype == gvalue.array_double_type then
                if type(value) == "number" then
                    value = { value }
                end

                local n = #value
                local a = ffi.new(gvalue.pdouble_typeof, n, value)

                vips_lib.vips_value_set_array_double(gv, a, n)
            elseif gtype == gvalue.array_image_type then
                if Image.is_Image(value) then
                    value = { value }
                end

                local n = #value

                vips_lib.vips_value_set_array_image(gv, n)
                local a = vips_lib.vips_value_get_array_image(gv, nil)

                for i = 0, n - 1 do
                    a[i] = value[i + 1].vimage
                    -- the gvalue needs a set of refs to own
                    gobject_lib.g_object_ref(a[i])
                end
            elseif gtype == gvalue.blob_type then
                -- we need to set the blob to a copy of the lua string that vips
                -- can own
                local n = #value

                local buf = glib_lib.g_malloc(n)
                ffi.copy(buf, value, n)

                if version.at_least(8, 6) then
                    vips_lib.vips_value_set_blob_free(gv, buf, n)
                else
                    vips_lib.vips_value_set_blob(gv, glib_lib.g_free, buf, n)
                end
            else
                error("unsupported gtype for set " .. gvalue.type_name(gtype))
            end
        end,

        get = function(gv)
            local gtype = gv.gtype
            local fundamental = gobject_lib.g_type_fundamental(gtype)

            local result

            if gtype == gvalue.gbool_type then
                result = gobject_lib.g_value_get_boolean(gv)
            elseif gtype == gvalue.gint_type then
                result = gobject_lib.g_value_get_int(gv)
            elseif gtype == gvalue.gdouble_type then
                result = gobject_lib.g_value_get_double(gv)
            elseif fundamental == gvalue.genum_type then
                local enum_value = gobject_lib.g_value_get_enum(gv)

                local cstr = vips_lib.vips_enum_nick(gtype, enum_value)

                if cstr == nil then
                    error("value not in enum")
                end

                result = ffi.string(cstr)
            elseif fundamental == gvalue.gflags_type then
                result = gobject_lib.g_value_get_flags(gv)
            elseif gtype == gvalue.gstr_type then
                local cstr = gobject_lib.g_value_get_string(gv)

                if cstr ~= nil then
                    result = ffi.string(cstr)
                else
                    result = nil
                end
            elseif gtype == gvalue.refstr_type then
                local psize = ffi.new(gvalue.psize_typeof, 1)

                local cstr = vips_lib.vips_value_get_ref_string(gv, psize)

                result = ffi.string(cstr, psize[0])
            elseif gtype == gvalue.image_type then
                -- g_value_get_object() will not add a ref ... that is
                -- held by the gvalue
                local vo = gobject_lib.g_value_get_object(gv)
                local vimage = ffi.cast(gvalue.image_typeof, vo)

                -- we want a ref that will last with the life of the vimage:
                -- this ref is matched by the unref that's attached to finalize
                -- by Image.new()
                gobject_lib.g_object_ref(vimage)

                result = Image.new(vimage)
            elseif gtype == gvalue.array_int_type then
                local pint = ffi.new(gvalue.pint_typeof, 1)

                local array = vips_lib.vips_value_get_array_int(gv, pint)
                result = {}
                for i = 0, pint[0] - 1 do
                    result[i + 1] = array[i]
                end

            elseif gtype == gvalue.array_double_type then
                local pint = ffi.new(gvalue.pint_typeof, 1)

                local array = vips_lib.vips_value_get_array_double(gv, pint)
                result = {}
                for i = 0, pint[0] - 1 do
                    result[i + 1] = array[i]
                end
            elseif gtype == gvalue.array_image_type then
                local pint = ffi.new(gvalue.pint_typeof, 1)

                local array = vips_lib.vips_value_get_array_image(gv, pint)
                result = {}
                for i = 0, pint[0] - 1 do
                    -- this will make a new cdata object
                    local vimage = array[i]

                    -- vips_value_get_array_image() adds a ref for each image in
                    -- the array ... we must remember to drop them
                    gobject_lib.g_object_ref(vimage)

                    result[i + 1] = Image.new(vimage)
                end
            elseif gtype == gvalue.blob_type then
                local psize = ffi.new(gvalue.psize_typeof, 1)

                local array = vips_lib.vips_value_get_blob(gv, psize)

                result = ffi.string(array, psize[0])
            else
                error("unsupported gtype for get " .. gvalue.type_name(gtype))
            end

            return result
        end
    }
}

gvalue = ffi.metatype("GValue", gvalue_mt)
return gvalue
