all: compile_rtl regression

compile_%:
	$(MAKE) -C $* compile

build:
	$(MAKE) -C build

regression:
	cd tests/regression && make

clean:
	$(MAKE) -C rtl clean

.PHONY: build
