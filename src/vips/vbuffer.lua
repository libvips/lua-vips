local ffi = require "ffi"

ffi.cdef([[
    typedef int pid_t;

    void *malloc(size_t sz);
    void *realloc(void*ptr, size_t size);
    void free(void *ptr);

    struct vbuffer{
        char *ptr;
        size_t mem;
        size_t size;
        size_t init_size;
    };
]])

local vbuffer = {}
vbuffer.__index = vbuffer

setmetatable(vbuffer, {
    __call = function (cls, ...)
        local self = setmetatable({}, cls)
        self:new(...)
        return self
    end,})

local function _vbuffer_free(ptr)
    ptr = ffi.cast("struct vbuffer *",  ptr)
    ffi.C.free(ptr.ptr)
    ffi.C.free(ptr)
end

--- init buffer
-- @param init_size set initial size of buffer
-- @return buffer
function vbuffer.new(init_size)
    local self = setmetatable({}, vbuffer)
    init_size = init_size or 1024
    local ptr = ffi.C.malloc(ffi.sizeof("struct vbuffer"))
    if ptr == nil then
        error("memory error")
    end
    self.vbuffer = ffi.cast("struct vbuffer *",  ptr)
    ffi.gc(self.vbuffer, _vbuffer_free)
    ptr = ffi.C.malloc(init_size)
    if ptr == nil then
        error("memory error")
    end
    self.vbuffer.mem = init_size
    self.vbuffer.size = 0
    self.vbuffer.ptr = ptr
    self.vbuffer.init_size = init_size
    return self
end

--- clear buffer
-- @param wipe overwrite allocated memory with zero
function vbuffer:clear(wipe)
    if wipe then
        ffi.fill(self.vbuffer.ptr, self.vbuffer.mem, 0)
    end
    self.vbuffer.size = 0
    return self
end

--- append lua string to buffer
-- @param str lua string
function vbuffer:append_luastr_right(str)
    if not str then
        error("empty string")
    end
    local len = str:len()
    if self.vbuffer.mem - self.vbuffer.size >= len then
        ffi.copy(self.vbuffer.ptr + self.vbuffer.size, str, len)
        self.vbuffer.size = self.vbuffer.size + len
    else
        -- Realloc and double required memory size.
        local new_size = self.vbuffer.size + len
        local new_mem  = new_size * 2
        local ptr = ffi.C.realloc(self.vbuffer.ptr, new_mem)
        if ptr == nil then
            error("memory error")
        end
        self.vbuffer.ptr = ptr
        ffi.copy(self.vbuffer.ptr + self.vbuffer.size, str, len)
        self.vbuffer.mem = new_mem
        self.vbuffer.size = new_size
    end
    return self
end


--- get buffer size
-- @return size of buffer in bytes.
function vbuffer:len() return self.vbuffer.size end

--- get total number of bytes allocated to buffer
-- @return number of bytes allocated.
function vbuffer:mem() return self.vbuffer.mem end

--- get internal buffer pointer.
-- @return char * to data.
-- @return size of buffer in bytes.
function vbuffer:get() return self.vbuffer.ptr, self.vbuffer.size end

--- convert to lua type string
-- @return lua string
function vbuffer:toString() return ffi.string(self.vbuffer.ptr, self.vbuffer.size) end

return vbuffer
