-- manipulate GValue objects from lua
-- pull in gobject via the vips library

local ffi = require "ffi" 

local log = require "vips/log"

-- we need to be able to wrap and unwrap Image tables
local Image = require "vips/Image"

local vips = ffi.load("vips")

ffi.cdef[[
    typedef struct _GValue {
        unsigned long int type;
        uint64_t data[2]; 
    } GValue;

    typedef struct _VipsImage VipsImage;

    void* g_malloc(size_t size);
    void g_free(void* data);

    void g_object_ref (void* object);
    void g_object_unref (void* object);

    void g_value_init (GValue* value, unsigned long int type);
    void g_value_unset (GValue* value);
    const char* g_type_name (unsigned long int type);
    unsigned long int g_type_from_name (const char* name);
    unsigned long int g_type_fundamental (unsigned long int gtype);

    int vips_enum_from_nick (const char* domain, 
        unsigned long int gtype, const char* str);
    const char *vips_enum_nick (unsigned long int gtype, int value);

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

local function print_all(msg)
    collectgarbage()
    print(msg)
    vips.vips_object_print_all()
    print()
end

local gvalue = {}
local gvalue_mt = {
    __gc = function(gv)
        log.msg("freeing gvalue ", gv)
        log.msg("  type name =", ffi.string(vips.g_type_name(gv.type)))

        vips.g_value_unset(gv)
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

        -- look up some common gtypes at init for speed
        gint_type = vips.g_type_from_name("gint"),
        gdouble_type = vips.g_type_from_name("gdouble"),
        gstr_type = vips.g_type_from_name("gchararray"),
        genum_type = vips.g_type_from_name("GEnum"),
        gflags_type = vips.g_type_from_name("GFlags"),
        image_type = vips.g_type_from_name("VipsImage"),
        array_int_type = vips.g_type_from_name("VipsArrayInt"),
        array_double_type = vips.g_type_from_name("VipsArrayDouble"),
        array_image_type = vips.g_type_from_name("VipsArrayImage"),
        refstr_type = vips.g_type_from_name("VipsRefString"),
        blob_type = vips.g_type_from_name("VipsBlob"),

        new = function()
            -- with no init, this will initialize with 0, which is what we need
            -- for a blank GValue
            local gv = ffi.new(gvalue.gv_typeof)
            log.msg("allocating gvalue", gv)
            return gv
        end,

        -- this won't be unset() automatically! you need to
        -- g_value_unset() yourself after calling
        newp = function()
            local pgv = ffi.new(gvalue.pgv_typeof)
            log.msg("allocating one-element array of gvalue", pgv)
            return pgv
        end,

        type_name = function(gtype)
            return(ffi.string(vips.g_type_name(gtype)))
        end,

        init = function(gv, gtype)
            log.msg("starting init")
            log.msg("  gv =", gv)
            log.msg("  type name =", gvalue.type_name(gtype))
            vips.g_value_init(gv, gtype)
        end,

        set = function(gv, value)
            log.msg("set() value =")
            log.msg_r(value)

            local gtype = gv.type
            local fundamental = vips.g_type_fundamental(gtype)

            if gtype == gvalue.gint_type then
                vips.g_value_set_int(gv, value)
            elseif gtype == gvalue.gdouble_type then
                vips.g_value_set_double(gv, value)
            elseif fundamental == gvalue.genum_type then
                local enum_value 
                if type(value) == "string" then
                    enum_value = 
                        vips.vips_enum_from_nick("lua-vips", gtype, value)

                    if enum_value < 0 then
                        error("no such enum " .. value .. "\n" .. 
                            object.get_error())
                    end
                else
                    enum_value = value
                end

                vips.g_value_set_enum(gv, enum_value)
            elseif fundamental == gvalue.gflags_type then
                vips.g_value_set_flags(gv, value)
            elseif gtype == gvalue.gstr_type or gtype == gvalue.refstr_type then
                vips.g_value_set_string(gv, value)
            elseif gtype == gvalue.image_type then
                vips.g_value_set_object(gv, value.vimage)
            elseif gtype == gvalue.array_int_type then
                local n = #value
                local a = ffi.new(gvalue.pint_typeof, n, value)

                vips.vips_value_set_array_int(gv, a, n)

            elseif gtype == gvalue.array_double_type then
                local n = #value
                local a = ffi.new(gvalue.pdouble_typeof, n, value)

                vips.vips_value_set_array_double(gv, a, n)

            elseif gtype == gvalue.array_image_type then
                local n = #value

                vips.vips_value_set_array_image(gv, n)

                local a = vips_value_get_array_image(gv, nil)
                for i = 0, n - 1 do
                    a[i] = value[i + 1].vimage
                end

            elseif gtype == gvalue.blob_type then
                -- we need to set the blob to a copy of the lua string that vips
                -- can own
                local n = #value

                local buf = vips.g_malloc(n)
                ffi.copy(buf, value, n)

                vips.vips_value_set_blob(gv, 
                    function(p) vips.g_free(p) end, 
                    buf, n)

            else
                 error("unsupported gtype for set " .. gvalue.type_name(gtype))
            end
        end,

        get = function(gv)
            local gtype = gv.type
            local fundamental = vips.g_type_fundamental(gtype)

            local result

            if gtype == gvalue.gint_type then
                result = vips.g_value_get_int(gv)
            elseif gtype == gvalue.gdouble_type then
                result = vips.g_value_get_double(gv)
            elseif fundamental == gvalue.genum_type then
                local enum_value = vips.g_value_get_enum(gv)

                local cstr = vips.vips_enum_nick(gtype, enum_value)

                if cstr == nil then
                    error("value not in enum")
                end

                result = ffi.string(cstr)
            elseif fundamental == gvalue.gflags_type then
                result = vips.g_value_get_flags(gv)
            elseif gtype == gvalue.gstr_type then
                local cstr = vips.g_value_get_string(gv)

                if cstr ~= nil then
                    result = ffi.string(cstr)
                else
                    result = nil
                end
            elseif gtype == gvalue.refstr_type then
                local psize = ffi.new(gvalue.psize_typeof, 1)

                local cstr = vips.vips_value_get_ref_string(gv, psize)

                result = ffi.string(cstr, psize[0])
            elseif gtype == gvalue.image_type then
                -- g_value_get_object() will not add a ref ... that is
                -- held by the gvalue
                local vo = vips.g_value_get_object(gv)
                local vimage = ffi.cast(gvalue.image_typeof, vo)

                -- we want a ref that will last with the life of the vimage: 
                -- this ref is matched by the unref that's attached to finalize
                -- by Image.new() 
                vips.g_object_ref(vimage)

                result = Image.new(vimage)

            elseif gtype == gvalue.array_int_type then
                local pint = ffi.new(gvalue.pint_typeof, 1)

                local array = vips.vips_value_get_array_int(gv, pint)
                result = {}
                for i = 0, pint[0] - 1 do
                    result[i + 1] = array[i]
                end

            elseif gtype == gvalue.array_double_type then
                local pint = ffi.new(gvalue.pint_typeof, 1)

                local array = vips.vips_value_get_array_double(gv, pint)
                result = {}
                for i = 0, pint[0] - 1 do
                    result[i + 1] = array[i]
                end

            elseif gtype == gvalue.array_image_type then
                local pint = ffi.new(gvalue.pint_typeof, 1)

                local array = vips.vips_value_get_array_image(gv, pint)
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

                local array = vips.vips_value_get_blob(gv, psize)

                result = ffi.string(array, psize[0])
            else
                 error("unsupported gtype for get " .. gvalue.type_name(gtype))
            end

            log.msg("get() result =")
            log.msg_r(result)

            return result
        end,

    }
}

gvalue = ffi.metatype("GValue", gvalue_mt)
return gvalue
