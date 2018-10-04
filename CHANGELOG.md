# Changelog

All notable changes to `lua-vips` will be documented in this file.

# 1.1-9 - 2018-08-03

- add `vips.leak_set()` [jcupitt]
- add `soak.lua` example [jcupitt]
- fix five minor memleaks [kleisauke]
- update links for new home [jcupitt]

# 1.1-8 - 2018-07-25

- cleanups and some reorganisation [kleisauke]
- fix regressions from 1.1-7 [kleisauke]
- add `find_load` [kleisauke]
- add `find_load_buffer` [kleisauke]

# 1.1-7 - 2018-03-23

- cleanups and some reorganisation
- renamed cache control funcs, the names were missing the `cache_` prefix
- fix `image:remove()` [kleisauke]

# 1.1-6 - 2018-03-23

- add operation cache control

# 1.1-5 - 2017-10-09

- add verror: handle libvips error buffer
- add version: handle libvips version numbers
- add `gvalue.to_enum`: wrap up enum encoding
- add `composite`
- add `new_from_memory`
- add `write_to_memory`
- remove `[]` and `#` overloads -- too confusing, and they broke debuggers

# 1.1-4 - 2017-08-30

- small doc fixes
- fix get() on gobject enum properties with older libvips
- test for gobject enum properties as strings

# 1.1-3 - 2017-08-08

- more Windows fixes 
- fix a callback leak with buffers, thanks wuyachao

# 1.1-2 - 2017-07-21

- fix "-" characters in arg names

# 1.1-1 - 2017-06-19

- tweaks to help LuaJIT on Windows

# 1.0-1 - 2017-06-04

- first API stable release

