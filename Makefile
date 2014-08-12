.PHONY: all test clean doc

test:
	@node_modules/.bin/coffee --no-header -b -o test/tmp/pre script/
	@cd test/tmp/pre; \
		for JS in *.js ; do \
			cat $$JS | grep -v " __hasProp = " | grep -v " __extends = " | grep -v " __slice = " | grep -v " __indexOf = " | grep -v " __bind = " > ../$$JS; \
		done
	@rm -rf test/tmp/pre
	-node_modules/karma/bin/karma start test/karma.conf.coffee
	@rm -rf test/tmp

js:
	@node_modules/.bin/coffee --no-header -b -o test/tmp/pre script/
	@cd test/tmp/pre; \
		for JS in *.js ; do \
			cat $$JS | grep -v " __hasProp = " | grep -v " __extends = " | grep -v " __slice = " | grep -v " __indexOf = " | grep -v " __bind = " > ../$$JS; \
		done
	@rm -rf test/tmp/pre
	@cat test/dep/test/coffeescript-helpers.js test/tmp/*.js > libs.js
	@rm -rf test/tmp
	@ls -la libs.js

jsmin: js
	@node_modules/.bin/uglifyjs libs.js -c -m -o libs.min.js
	@ls -la libs.min.js
	@gzip < libs.min.js > libs.min.js.gz
	@ls -la libs.min.js.gz

doc:
	@rm -rf doc/
	@node_modules/.bin/codo --undocumented script/
	@node_modules/.bin/codo script/

lint:
	@node_modules/.bin/coffeelint script/ test/unit/

check: test lint doc jsmin
