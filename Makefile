.PHONY: all test clean

test:
	coffee -o test/tmp script/
	karma start test/karma.conf.coffee
	rm -rf test/tmp
