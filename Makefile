DEV_ROCKS = "busted 2.2.0" "luacheck 1.1.2"
BUSTED_ARGS ?= -o gtest -v
TEST_CMD ?= busted $(BUSTED_ARGS)

.PHONY: dev ffi bit lint test

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

bit:
	@luarocks install luabitop

lint:
	@luacheck -q .

test:
	@$(TEST_CMD) spec/
