.PHONY: all clean dist doc lint test

all: full-test lint doc dist

dependencies:
	@if [ ! -d "node_modules" ]; then \
		echo "installing npm dev dependencies"; \
		npm install; \
	fi

clean:
	-@rm -rf dist
	@mkdir -p dist

dist: clean dependencies
	@node_modules/.bin/coffee --no-header -b -o dist/tmp/pre script/
	@cd dist/tmp/pre; \
		for JS in *.js ; do \
			cat $$JS | grep -v " __hasProp = " | grep -v " __extends = " | grep -v " __slice = " | grep -v " __indexOf = " | grep -v " __bind = " > ../$$JS; \
		done
	@rm -rf dist/tmp/pre
	@cat test/dep/test/coffeescript-helpers.js test/dep/test/module-init.js dist/tmp/*.js > dist/ksc.js
	@rm -rf dist/tmp
	@ls -la dist/ksc.js
	@node_modules/.bin/uglifyjs dist/ksc.js -b -o dist/ksc.sans-comments.js
	@ls -la dist/ksc.sans-comments.js
	@node_modules/.bin/uglifyjs dist/ksc.js -c -m -o dist/ksc.min.js
	@ls -la dist/ksc.min.js
	@gzip < dist/ksc.min.js > dist/ksc.min.js.gz
	@ls -la dist/ksc.min.js.gz

doc: dependencies
	@rm -rf doc/
	@node_modules/.bin/codo --undocumented script/
	@node_modules/.bin/codo script/

lint: dependencies
	@node_modules/.bin/coffeelint script/ test/unit/

_cmptest: dependencies
	@node_modules/.bin/coffee --no-header -b -o test/tmp/pre script/
	@cd test/tmp/pre; \
		for JS in *.js ; do \
			cat $$JS | grep -v " __hasProp = " | grep -v " __extends = " | grep -v " __slice = " | grep -v " __indexOf = " | grep -v " __bind = " > ../$$JS; \
		done
	@rm -rf test/tmp/pre

test: dependencies _cmptest
	-node_modules/karma/bin/karma start test/karma.conf.coffee $(file)
	@rm -rf test/tmp

full-test: dependencies _cmptest
	-node_modules/karma/bin/karma start test/karma-full-with-sauce.conf.coffee $(file)
	@rm -rf test/tmp
