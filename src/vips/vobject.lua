-- manage VipsObject
-- abstract base class for voperation and vimage

local ffi = require "ffi"

local log = require "vips.log"
local gvalue = require "vips.gvalue"

local print = print
local collectgarbage = collectgarbage

local vips_lib
local gobject_lib
if ffi.os == "Windows" then
    vips_lib = ffi.load("libvips-42.dll")
    gobject_lib = ffi.load("libgobject-2.0-0.dll")
else
    vips_lib = ffi.load("vips")
    gobject_lib = vips_lib
end

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
        print_all = function(msg)
            collectgarbage()
            print(msg)
            vips_lib.vips_object_print_all()
            print()
        end,

        new = function(self)
            return ffi.gc(self, gobject_lib.g_object_unref)
        end,

        -- return 0 for not found and leave the error in the error log
        get_typeof = function(self, name)
            local pspec = vobject.pspec_typeof()
            local argument_class = vobject.argument_class_typeof()
            local argument_instance = vobject.argument_instance_typeof()
            local result = vips_lib.vips_object_get_argument(self, name,
                pspec, argument_class, argument_instance)

            if result ~= 0 then
                return 0
            end

            return pspec[0].value_type
        end,

        get = function(self, name)
            log.msg("vobject.get")
            log.msg("  name =", name)

            local gtype = self:get_typeof(name)
            if gtype == 0 then
                return false
            end

            local pgv = gvalue.newp()
            pgv[0]:init(gtype)
            -- this will add a ref for GObject properties, that ref will be
            -- unreffed when the gvalue is finalized
            gobject_lib.g_object_get_property(self, name, pgv)

            local result = pgv[0]:get()
            gobject_lib.g_value_unset(pgv[0])

            return result
        end,

        set = function(self, name, value)
            log.msg("vobject.set")
            log.msg("  name =", name)
            log.msg("  value =", value)

            local gtype = self:get_typeof(name)
            if gtype == 0 then
                return false
            end

            local gv = gvalue.new()
            gv:init(gtype)
            gv:set(value)
            gobject_lib.g_object_set_property(self, name, gv)

            return true
        end
    }
}

vobject = ffi.metatype("VipsObject", vobject_mt)
return vobject
