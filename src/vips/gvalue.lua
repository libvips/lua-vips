-- manipulate GValue objects from lua
-- pull in gobject via the vips library

local ffi = require "ffi" 

local log = require "vips/log"

local verror = require "vips/verror"
local version = require "vips/version"
local Image = require "vips/Image"

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

-- GType is an int the size of a pointer ... I don't think we can just use
-- size_t, sadly
if ffi.arch == "x64" then
    ffi.cdef[[
        typedef uint64_t GType;
    ]]
else
    ffi.cdef[[
        typedef uint32_t GType;
    ]]
end

ffi.cdef[[
    typedef struct _GValue {
        GType gtype;
        uint64_t data[2]; 
    } GValue;

    typedef struct _VipsImage VipsImage;

    void* g_malloc(size_t size);
    void g_free(void* data);

    void g_object_ref (void* object);
    void g_object_unref (void* object);

    void g_value_init (GValue* value, GType gtype);
    void g_value_unset (GValue* value);
    const char* g_type_name (GType gtype);
    GType g_type_from_name (const char* name);
    GType g_type_fundamental (GType gtype);

    GType vips_blend_mode_get_type (void);
    GType vips_band_format_get_type (void);

    int vips_enum_from_nick (const char* domain, 
        GType gtype, const char* str);
    const char *vips_enum_nick (GType gtype, int value);

    void g_value_set_boolean (GValue* value, int v_boolean);
    void g_value_set_int (GValue* value, int i);
    void g_value_set_double (GValue* value, double d);
    void g_value_set_enum (GValue* value, int e);
    void g_value_set_flags (GValue* value, unsigned int f);
    void g_value_set_string (GValue* value, const char *str);
    void g_value_set_object (GValue* value, void* object);
    void vips_value_set_array_double (GValue* value, 
        const double* array, int n );
    void vips_value_set_array_int (GValue* value, 
        const int* array, int n );
    void vips_value_set_array_image (GValue *value, int n);
    void vips_value_set_blob (GValue* value,
            void (*free_fn)(void* data), void* data, size_t length);

    int g_value_get_boolean (const GValue* value);
    int g_value_get_int (GValue* value);
    double g_value_get_double (GValue* value);
    int g_value_get_enum (GValue* value);
    unsigned int g_value_get_flags (GValue* value);
    const char* g_value_get_string (GValue* value);
    const char* vips_value_get_ref_string (const GValue* value, size_t* length);
    void* g_value_get_object (GValue* value);
    double* vips_value_get_array_double (const GValue* value, int* n);
    int* vips_value_get_array_int (const GValue* value, int* n);
    VipsImage** vips_value_get_array_image (const GValue* value, int* n);
    void* vips_value_get_blob (const GValue* value, size_t* length);

    void vips_object_print_all (void);

]]

if version.at_least(8, 6) then
    vips_lib.vips_blend_mode_get_type()
end
vips_lib.vips_band_format_get_type()

local function print_all(msg)
    collectgarbage()
    print(msg)
    vips_lib.vips_object_print_all()
    print()
end

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
        pimage_typeof = ffi.typeof("VipsImage*[?]"),
        pint_typeof = ffi.typeof("int[?]"),
        pdouble_typeof = ffi.typeof("double[?]"),
        psize_typeof = ffi.typeof("size_t[?]"),
        pstr_typeof = ffi.typeof("char*[?]"),
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
            return(ffi.string(gobject_lib.g_type_name(gtype)))
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
            elseif gtype == gvalue.gstr_type or gtype == gvalue.refstr_type then
                gobject_lib.g_value_set_string(gv, value)
            elseif gtype == gvalue.image_type then
                gobject_lib.g_value_set_object(gv, value.vimage)
            elseif gtype == gvalue.array_int_type then
                if type(value) == "number" then
                    value = {value}
                end

                local n = #value
                local a = ffi.new(gvalue.pint_typeof, n, value)

                vips_lib.vips_value_set_array_int(gv, a, n)

            elseif gtype == gvalue.array_double_type then
                if type(value) == "number" then
                    value = {value}
                end

                local n = #value
                local a = ffi.new(gvalue.pdouble_typeof, n, value)

                vips_lib.vips_value_set_array_double(gv, a, n)

            elseif gtype == gvalue.array_image_type then
                if Image.is_Image(value) then
                    value = {value}
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
                vips_lib.vips_value_set_blob(gv, glib_lib.g_free, buf, n)
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
                    vobject.new(vimage)

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
        end,

    }
}

gvalue = ffi.metatype("GValue", gvalue_mt)
return gvalue
