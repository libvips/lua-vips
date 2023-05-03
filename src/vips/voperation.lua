-- manage VipsOperation
-- lookup and call operations

local ffi = require "ffi"
local bit = require "bit"

local verror = require "vips.verror"
local version = require "vips.version"
local log = require "vips.log"
local gvalue = require "vips.gvalue"
local vobject = require "vips.vobject"
local Image = require "vips.Image"

local band = bit.band
local type = type
local error = error
local pairs = pairs
local unpack = unpack or table.unpack
local tonumber = tonumber
local str_gsub = string.gsub

local vips_lib = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

local REQUIRED = 1
local CONSTRUCT = 2 -- luacheck: ignore
local SET_ONCE = 4 -- luacheck: ignore
local SET_ALWAYS = 8 -- luacheck: ignore
local INPUT = 16
local OUTPUT = 32
local DEPRECATED = 64
local MODIFY = 128

-- find the first image, and recurse
local function find_first_image(array, length)
    length = length or #array

    for i = 1, length do
        if Image.is_Image(array[i]) then
            return array[i]
        elseif type(array[i]) == "table" then
            local result = find_first_image(array[i])

            if result then
                return result
            end
        end
    end

    return nil
end

local voperation = {}

voperation.argumentmap_typeof = ffi.typeof("VipsArgumentMapFn")
voperation.pstring_array_typeof = ffi.typeof("const char**[1]")
voperation.pint_array_typeof = ffi.typeof("int*[1]")
voperation.pint_typeof = ffi.typeof("int[1]")

-- cast to a vobject ... this will create a new cdata object, but won't
-- change any VipsObject reference counts, nor add a finalizer
-- TODO: Could we use `self.parent_instance` here?
voperation.vobject = function(self)
    return ffi.cast(vobject.typeof, self)
end

-- but for new() we can't do self:vobject():new() since that would
-- attach the unref callback to the cdata object made by the vobject()
-- cast, not to this voperation
voperation.new = function(self)
    return vobject.new(self)
end

voperation.set = function(self, name, flags, match_image, value)
    local vob = self:vobject()
    local gtype = vob:get_typeof(name)

    -- if the object wants an image and we have a constant, imageize it
    --
    -- if the object wants an image array, imageize any constants in the
    -- array
    if match_image then
        if gtype == gvalue.image_type then
            value = match_image:imageize(value)
        elseif gtype == gvalue.array_image_type then
            for i = 1, #value do
                value[i] = match_image:imageize(value[i])
            end
        end
    end

    -- MODIFY args need to be copied before they are set
    if band(flags, MODIFY) ~= 0 then
        log.msg("copying MODIFY arg", name)
        -- make sure we have a unique copy
        value = value:copy():copy_memory()
    end

    return vob:set_type(name, value, gtype)
end

-- this is slow ... call as little as possible
voperation.getargs = function(self)
    local names = {}
    local flags = {}
    local n_args = 0

    if version.at_least(8, 7) then
        local p_names = ffi.new(voperation.pstring_array_typeof)
        local p_flags = ffi.new(voperation.pint_array_typeof)
        local p_n_args = ffi.new(voperation.pint_typeof)

        vips_lib.vips_object_get_args(self, p_names, p_flags, p_n_args)

        p_names = p_names[0]
        p_flags = p_flags[0]
        n_args = p_n_args[0]

        -- C-array is numbered from zero
        for i = 0, n_args - 1 do
            names[i + 1] = str_gsub(ffi.string(p_names[i]), "-", "_")
            flags[i + 1] = p_flags[i]
        end
    else
        local cb = ffi.cast(voperation.argumentmap_typeof,
                function(_, pspec, argument_class, _, _, _)
                    n_args = n_args + 1

                    -- libvips uses "-" to separate parts of arg names, but we
                    -- need "_" for lua
                    names[n_args] = str_gsub(ffi.string(pspec.name), "-", "_")
                    flags[n_args] = tonumber(argument_class.flags)
                end)
        vips_lib.vips_argument_map(self, cb, nil, nil)
        cb:free()
    end

    return names, flags, n_args
end

-- string_options is any optional args coded as a string, perhaps
-- "[strip,tile=true]"
voperation.call = function(name, string_options, ...)
    local call_args = { ... }

    local vop = vips_lib.vips_operation_new(name)
    if vop == nil then
        error("no such operation\n" .. verror.get())
    end
    vop = vop:new()

    local names, flags, arguments_length = vop:getargs()

    -- cache the call args length
    local call_args_length = #call_args

    log.msg("calling operation:", name)
    log.msg("passed:")
    log.msg_r(call_args)

    -- make a thing to quickly get flags from an arg name
    local flags_from_name = {}

    -- count required input args
    local n_required = 0
    for i = 1, arguments_length do
        local flag = flags[i]
        flags_from_name[names[i]] = flag

        if band(flag, INPUT) ~= 0 and
                band(flag, REQUIRED) ~= 0 and
                band(flag, DEPRECATED) == 0 then
            n_required = n_required + 1
        end
    end

    -- so we should have been passed n_required, or n_required + 1 if
    -- there's a table of options at the end
    local last_arg
    if call_args_length == n_required then
        last_arg = nil
    elseif call_args_length == n_required + 1 then
        last_arg = call_args[#call_args]
        if type(last_arg) ~= "table" then
            error("unable to call " .. name .. ": " .. call_args_length ..
                    " arguments given, " .. n_required ..
                    ", but final argument is not a table")
        end
    else
        error("unable to call " .. name .. ": " .. call_args_length ..
                " arguments given, but " .. n_required .. " required")
    end

    -- the first image argument is the thing we expand constants to
    -- match ... look inside tables for images, since we may be passing
    -- an array of image as a single param
    local match_image = find_first_image(call_args, call_args_length)

    -- set any string options before any args so they can't be
    -- overridden
    if vips_lib.vips_object_set_from_string(vop:vobject(),
            string_options) ~= 0 then
        error("unable to call " .. name .. "\n" .. verror.get())
    end

    local n = 0
    for i = 1, arguments_length do
        local flag = flags[i]

        if band(flag, INPUT) ~= 0 and
                band(flag, REQUIRED) ~= 0 and
                band(flag, DEPRECATED) == 0 then
            n = n + 1

            if not vop:set(names[i], flag,
                    match_image, call_args[n]) then
                error("unable to call " .. name .. "\n" .. verror.get())
            end
        end
    end

    if last_arg then
        for k, v in pairs(last_arg) do
            local flag = flags_from_name[k]
            if not flag then
                error("unable to call " .. name .. ": invalid flag '" ..
                        tostring(k) .. "'")
            end

            if not vop:set(k, flag, match_image, v) then
                error("unable to call " .. name .. "\n" .. verror.get())
            end
        end
    end

    local vop2 = vips_lib.vips_cache_operation_build(vop)
    if vop2 == nil then
        error("unable to call " .. name .. "\n" .. verror.get())
    end
    vop = vop2:new()

    local result = {}
    local vob = vop:vobject()

    -- fetch required output args, plus modified input images
    n = 1
    for i = 1, arguments_length do
        local flag = flags[i]

        if band(flag, OUTPUT) ~= 0 and
                band(flag, REQUIRED) ~= 0 and
                band(flag, DEPRECATED) == 0 then
            result[n] = vob:get(names[i])
            n = n + 1
        end

        -- MODIFY input args are returned .. this will get the copy we
        -- made above
        if band(flag, INPUT) ~= 0 and
                band(flag, MODIFY) ~= 0 then
            result[n] = vob:get(names[i])
            n = n + 1
        end
    end

    --  fetch optional output args
    for i = 1, arguments_length do
        local flag = flags[i]

        if band(flag, OUTPUT) ~= 0 and
                band(flag, REQUIRED) == 0 and
                band(flag, DEPRECATED) == 0 then
            result[n] = vob:get(names[i])
            n = n + 1
        end
    end

    vips_lib.vips_object_unref_outputs(vop)

    -- this strange if expression is because unpack
    -- has not yet been implemented in the JIT compiler
    -- of LuaJIT, see: http://wiki.luajit.org/NYI.
    if n == 1 then
        return nil
    elseif n == 2 then
        return result[1]
    else
        -- we could extend this if expression even more,
        -- but usually one item is returned.
        return unpack(result)
    end
end

return ffi.metatype("VipsOperation", {
    __index = voperation
})
