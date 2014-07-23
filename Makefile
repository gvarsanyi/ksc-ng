.PHONY: all test clean doc

test:
	@coffee --no-header -b -o test/tmp/pre script/
	@cd test/tmp/pre; \
		for JS in *.js ; do \
			cat $$JS | grep -v " __hasProp = " | grep -v " __extends = " | grep -v " __slice = " | grep -v " __indexOf = " | grep -v " __bind = " > ../$$JS; \
		done
	@rm -rf test/tmp/pre
	-karma start test/karma.conf.coffee
	@rm -rf test/tmp

doc:
	@rm -rf doc/
	@codo script/
