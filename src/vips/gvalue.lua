-- manipulate GValue objects from lua
-- pull in gobject via the vips library

local ffi = require("ffi")
local vips = ffi.load("vips")

ffi.cdef[[
    typedef struct _GValue {
        unsigned long int type;
        uint64_t data[2]; 
    } GValue;

    typedef struct _VipsImage VipsImage;

    void vips_init (const char* argv0);

    void g_value_init (GValue* value, unsigned long int type);
    void g_value_unset (GValue* value);
    const char* g_type_name (unsigned long int type);
    unsigned long int g_type_from_name (const char* name);

    void g_value_set_string (GValue* value, const char *str);
    void g_value_set_int (GValue* value, int i);
    void g_value_set_double (GValue* value, double d);
    void g_value_set_object (GValue* value, void* object);
    void vips_value_set_array_double (GValue* value, 
        const double* array, int n );
    void vips_value_set_array_int (GValue* value, 
        const int* array, int n );

    const char* g_value_get_string (GValue* value);
    int g_value_get_int (GValue* value);
    double g_value_get_double (GValue* value);
    void* g_value_get_object (GValue* value);
    double* vips_value_get_array_double (const GValue* value, int* n);
    int* vips_value_get_array_int (const GValue* value, int* n);

]]

-- this will add the vips types as well
vips.vips_init("")

local gvalue
local gvalue_mt = {
    __gc = function(gv)
        print("freeing gvalue ", gv)
        print("  type name =", ffi.string(vips.g_type_name(gv.type)))

        vips.g_value_unset(gv)
    end,
    __index = {
        -- make ffi constructors we can reuse
        gv_typeof = ffi.typeof("GValue"),
        pgv_typeof = ffi.typeof("GValue[1]"),
        image_typeof = ffi.typeof("VipsImage*"),
        pint_typeof = ffi.typeof("int[?]"),
        pdouble_typeof = ffi.typeof("double[?]"),

        -- look up some common gtypes at init for speed
        gint_type = vips.g_type_from_name("gint"),
        gdouble_type = vips.g_type_from_name("gdouble"),
        gstr_type = vips.g_type_from_name("gchararray"),
        image_type = vips.g_type_from_name("VipsImage"),
        array_double_type = vips.g_type_from_name("VipsArrayDouble"),
        array_int_type = vips.g_type_from_name("VipsArrayInt"),

        new = function()
            -- with no init, this will initialize with 0, which is what we need
            -- for a blank GValue
            local gv = ffi.new(gvalue.gv_typeof)
            print("allocating gvalue", gv)
            return gv
        end,

        newp = function()
            local pgv = ffi.new(gvalue.pgv_typeof)
            print("allocating one-element array of gvalue", pgv)
            return pgv
        end,

        init = function(gv, type)
            print("starting init")
            print("  gv =", gv)
            print("  type name =", ffi.string(vips.g_type_name(type)))
            vips.g_value_init(gv, type)
        end,

        set = function(gv, value)
            print("set() value =")
            print_r(value)

            local gtype = gv.type

            if gtype == gvalue.gint_type then
                vips.g_value_set_int(gv, value)
            elseif gtype == gvalue.gdouble_type then
                vips.g_value_set_double(gv, value)
            elseif gtype == gvalue.gstr_type then
                vips.g_value_set_string(gv, value)
            elseif gtype == gvalue.image_type then
                vips.g_value_set_object(gv, value)
            elseif gtype == gvalue.array_double_type then
                local n = #value
                local a = ffi.new(gvalue.pdouble_typeof, n, value)

                vips.vips_value_set_array_double(gv, a, n)
            elseif gtype == gvalue.array_int_type then
                local n = #value
                local a = ffi.new(gvalue.pint_typeof, n, value)

                vips.vips_value_set_array_int(gv, a, n)
            else
                 print("unsupported gtype", gtype)
            end
        end,

        get = function(gv)
            local gtype = gv.type
            local result

            if gtype == gvalue.gint_type then
                result = vips.g_value_get_int(gv)
            elseif gtype == gvalue.gdouble_type then
                result = vips.g_value_get_double(gv)
            elseif gtype == gvalue.gstr_type then
                result = ffi.string(vips.g_value_get_string(gv))
            elseif gtype == gvalue.image_type then
                result = ffi.cast(gvalue.image_typeof, 
                    vips.g_value_get_object(gv))
            elseif gtype == gvalue.array_double_type then
                local pint = ffi.new(gvalue.pint_typeof, 1)

                array = vips.vips_value_get_array_double(gv, pint)
                result = {}
                for i = 0, pint[0] - 1 do
                    result[i + 1] = array[i]
                end
            elseif gtype == gvalue.array_int_type then
                local pint = ffi.new(gvalue.pint_typeof, 1)

                array = vips.vips_value_get_array_int(gv, pint)
                result = {}
                for i = 0, pint[0] - 1 do
                    result[i + 1] = array[i]
                end
            else
                 print("unsupported gtype", gtype)
            end

            print("get() result =")
            print_r(result)

            return result
        end,

    }
}

gvalue = ffi.metatype("GValue", gvalue_mt)
return gvalue
