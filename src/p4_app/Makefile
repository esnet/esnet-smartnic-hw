all: compile_rtl regression

compile_%:
	$(MAKE) -C $* compile

regression:
	cd tests/regression && make

clean:
	$(MAKE) -C rtl clean
