DEV_ROCKS = "busted 2.2.0" "luacheck 1.1.2"

.PHONY: dev ffi

dev:
	@for rock in $(DEV_ROCKS) ; do \
	  if luarocks list --porcelain $$rock | grep -q "installed" ; then \
	    echo $$rock already installed, skipping ; \
	  else \
	    echo $$rock not found, installing via luarocks... ; \
	    luarocks install $$rock ; \
	  fi \
	done;

ffi:
	@luarocks install luaffi-tkl
