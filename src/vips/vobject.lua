-- manage VipsObject
-- abstract base class for voperation and vimage

local ffi = require "ffi"

local verror = require "vips.verror"
local log = require "vips.log"
local gvalue = require "vips.gvalue"

local print = print
local error = error
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

-- types to get ref back from vips_object_get_argument()
vobject.typeof = ffi.typeof("VipsObject*")
vobject.pspec_typeof = ffi.typeof("GParamSpec*[1]")
vobject.argument_class_typeof = ffi.typeof("VipsArgumentClass*[1]")
vobject.argument_instance_typeof = ffi.typeof("VipsArgumentInstance*[1]")

vobject.print_all = function(msg)
    collectgarbage()
    print(msg)
    vips_lib.vips_object_print_all()
    print()
end

vobject.new = function(pt)
    return ffi.gc(pt, gobject_lib.g_object_unref)
end

-- return 0 for not found and leave the error in the error log
vobject.get_typeof = function(self, name)
    local pspec = vobject.pspec_typeof()
    local argument_class = vobject.argument_class_typeof()
    local argument_instance = vobject.argument_instance_typeof()
    local result = vips_lib.vips_object_get_argument(self, name,
            pspec, argument_class, argument_instance)

    if result ~= 0 then
        return 0
    end

    return pspec[0].value_type
end

vobject.get_type = function(self, name, gtype)
    log.msg("vobject.get_type")
    log.msg("  name =", name)

    if gtype == 0 then
        return false
    end

    local pgv = gvalue(true)
    pgv[0]:init(gtype)

    -- this will add a ref for GObject properties, that ref will be
    -- unreffed when the gvalue is finalized
    gobject_lib.g_object_get_property(self, name, pgv)

    local result = pgv[0]:get()
    gobject_lib.g_value_unset(pgv[0])

    return result
end

vobject.set_type = function(self, name, value, gtype)
    log.msg("vobject.set_type")
    log.msg("  name =", name)
    log.msg("  value =", value)

    if gtype == 0 then
        return false
    end

    local pgv = gvalue(true)
    pgv[0]:init(gtype)
    pgv[0]:set(value)
    gobject_lib.g_object_set_property(self, name, pgv)
    gobject_lib.g_value_unset(pgv[0])

    return true
end

vobject.get = function(self, name)
    log.msg("vobject.get")
    log.msg("  name =", name)

    local gtype = self:get_typeof(name)
    if gtype == 0 then
        error(verror.get())
    end

    return vobject.get_type(self, name, gtype)
end

vobject.set = function(self, name, value)
    log.msg("vobject.set")
    log.msg("  name =", name)
    log.msg("  value =", value)

    local gtype = self:get_typeof(name)
    if gtype == 0 then
        error(verror.get())
    end

    vobject.set_type(self, name, value, gtype)

    return true
end

return ffi.metatype("VipsObject", {

    -- no __gc method, we don't build these things ourselves, just wrap the
    -- pointer, so we use ffi.gc() instead

    __index = vobject
})
