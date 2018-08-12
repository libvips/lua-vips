DEV_ROCKS = "busted 2.0.rc12" "luacheck 0.22.1"
BUSTED_ARGS ?= -o gtest -v
TEST_CMD ?= busted $(BUSTED_ARGS)

.PHONY: dev lint test

dev:
	@for rock in $(DEV_ROCKS) ; do \
	  if luarocks list --porcelain $$rock | grep -q "installed" ; then \
	    echo $$rock already installed, skipping ; \
	  else \
	    echo $$rock not found, installing via luarocks... ; \
	    luarocks install $$rock ; \
	  fi \
	done;

lint:
	@luacheck -q .

test:
	@$(TEST_CMD) spec/
