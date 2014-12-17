.PHONY: all clean dist doc lint test

all: test lint doc dist

dependencies:
	@if [ ! -d "node_modules" ]; then \
		echo "installing npm dev dependencies"; \
		npm install; \
	fi

clean:
	-@rm -rf dist
	@mkdir -p dist

tmpcompile:
	-@rm -rf .tmp
	@mkdir -p .tmp/coffee
	@cd script; \
		for COFFEE in *.coffee ; do \
			cat $$COFFEE | grep -v "#DOC-ONLY#" > ../.tmp/coffee/$$COFFEE; \
		done
	@node_modules/.bin/coffee --no-header -b -o .tmp/pre-js .tmp/coffee/
	@mkdir -p .tmp/js
	@cd .tmp/pre-js; \
		for JS in *.js ; do \
			cat $$JS | grep -v " __hasProp = " | grep -v " __extends = " | grep -v " __slice = " | grep -v " __indexOf = " | grep -v " __bind = " > ../js/$$JS; \
		done

dist: clean dependencies tmpcompile
	@cat test/dep/test/coffeescript-helpers.js test/dep/test/module-init.js .tmp/js/*.js > dist/ksc.js
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

test: dependencies tmpcompile
	-node_modules/karma/bin/karma start test/karma.conf.coffee $(file)

full-test: dependencies tmpcompile
	-node_modules/karma/bin/karma start test/karma-full-with-sauce.conf.coffee $(file)
