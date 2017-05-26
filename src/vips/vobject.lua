-- manage VipsObject
-- abstract base class for voperation and vimage

local ffi = require "ffi"

local log = require "vips/log"
local gvalue = require "vips/gvalue"

local vips = ffi.load("vips")

ffi.cdef[[
    typedef struct _GObject {
        int g_type_instance;
        unsigned ref_count;
        void *qdata;
    } GObject;

    typedef struct _VipsObject {
        GObject parent_object;
        bool constructed;
        bool static_object;
        void *argument_table;
        char *nickname;
        char *description;
        bool preclose;
        bool close;
        bool postclose;
        size_t local_memory;
    } VipsObject;

    typedef struct _VipsObjectClass {
        // opaque
    } VipsObjectClass;

    typedef struct _GParamSpec {
        void* g_type_instance;

        const char* name;     
        unsigned int flags;
        unsigned long int value_type;
        unsigned long int owner_type;

        // rest opaque
    } GParamSpec;

    typedef struct _VipsArgument {
        GParamSpec *pspec;
    } VipsArgument;

    typedef struct _VipsArgumentInstance {
        VipsArgument parent;

        // opaque
    } VipsArgumentInstance;

    typedef enum _VipsArgumentFlags {
        VIPS_ARGUMENT_NONE = 0,
        VIPS_ARGUMENT_REQUIRED = 1,
        VIPS_ARGUMENT_CONSTRUCT = 2,
        VIPS_ARGUMENT_SET_ONCE = 4,
        VIPS_ARGUMENT_SET_ALWAYS = 8,
        VIPS_ARGUMENT_INPUT = 16,
        VIPS_ARGUMENT_OUTPUT = 32,
        VIPS_ARGUMENT_DEPRECATED = 64,
        VIPS_ARGUMENT_MODIFY = 128
    } VipsArgumentFlags;

    typedef struct _VipsArgumentClass {
        VipsArgument parent;

        VipsObjectClass *object_class;
        VipsArgumentFlags flags;
        int priority;
        unsigned long int offset;
    } VipsArgumentClass;

    void g_object_unref (void* object);

    int vips_object_get_argument (VipsObject* object, 
        const char *name, GParamSpec** pspec, 
        VipsArgumentClass** argument_class,
        VipsArgumentInstance** argument_instance);

    void g_object_set_property (VipsObject* object, 
        const char *name, GValue* value);
    void g_object_get_property (VipsObject* object, 
        const char* name, GValue* value);

    const char* vips_error_buffer (void);
    void vips_error_clear (void);

]]

local vobject = {}
local vobject_mt = {
    -- no __gc method, we don't build these things ourselves, just wrap the
    -- pointer, so we use ffi.gc() instead
    __index = {
        -- types to get ref back from vips_object_get_argument()
        typeof = ffi.typeof("VipsObject*"),
        pspec_typeof = ffi.typeof("GParamSpec*[1]"),
        argument_class_typeof = ffi.typeof("VipsArgumentClass*[1]"),
        argument_instance_typeof = ffi.typeof("VipsArgumentInstance*[1]"),

        new = function(self)
            log.msg("vobject.new")
            log.msg("  ptr =", self)
            ffi.gc(self, 
                function(x) 
                    log.msg("unreffing", x)
                    vips.g_object_unref(x)
                end
            )
            return self
        end,

        get_typeof = function(self, name)
            local pspec = vobject.pspec_typeof()
            local argument_class = vobject.argument_class_typeof()
            local argument_instance = vobject.argument_instance_typeof()
            local result = vips.vips_object_get_argument(self, name,
                pspec, argument_class, argument_instance)

            if result ~= 0 then
                -- so 0 means does not exist
                return 0
            end

            return pspec[0].value_type
        end,

        get = function(self, name)
            log.msg("vobject.get")
            log.msg("  self =", self)
            log.msg("  name =", name)

            local type = self:get_typeof(name)
            if not type then
                error("field " .. name ..  " does not exist")
            end

            local gva = gvalue.newp()
            gva[0]:init(self:get_typeof(name))
            vips.g_object_get_property(self, name, gva)

            return gva[0]:get()
        end,

        set = function(self, name, value)
            log.msg("vobject.set")
            log.msg("  self =", self)
            log.msg("  name =", name)
            log.msg("  value =", value)

            local gtype = self:get_typeof(name)
            if gtype == 0 then
                error("field " .. name ..  " does not exist")
            end

            local gv = gvalue.new()
            gv:init(gtype)
            gv:set(value)
            vips.g_object_set_property(self, name, gv)

            return true
        end,

        get_error = function ()
            local errstr = ffi.string(vips.vips_error_buffer())
            vips.vips_error_clear()

            return errstr
        end,

    }
}

vobject = ffi.metatype("VipsObject", vobject_mt)
return vobject

