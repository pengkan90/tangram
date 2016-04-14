# Binaries
UGLIFY = ./node_modules/.bin/uglifyjs
BROWSERIFY = ./node_modules/.bin/browserify
KARMA = ./node_modules/karma/bin/karma
JSHINT = ./node_modules/.bin/jshint
DEREQUIRE = ./node_modules/.bin/derequire

# Build debug and minified libraries
all: \
	dist/tangram.min.js \
	dist/tangram.debug.js

debug: dist/tangram.debug.js

dist/tangram.debug.js: .npm $(shell ./build_deps.sh)
	node build.js --debug=true --require './src/module.js' --runtime | $(DEREQUIRE) > dist/tangram.debug.js

dist/tangram.min.js: dist/tangram.debug.js
	$(UGLIFY) dist/tangram.debug.js -c warnings=false -m -o dist/tangram.min.js
	@gzip dist/tangram.min.js -c | wc -c | awk '{ printf "%.0fk minified+gzipped\n", $$1 / 1024 }'

### Tests

# Run lint
lint: .npm
	$(JSHINT) `find src/ -name '*.js'`
	$(JSHINT) `find test/ -name '*.js'`

# Test-specific builds of the library
build-testable: lint
	$(BROWSERIFY) src/module.js -o dist/tangram.test.js -t [ babelify --optional runtime ] -t brfs -s Tangram

# Do a single test run, locally (opens browser, runs test, closes browser)
test: build-testable
	$(KARMA) start --browsers Chrome --single-run

# Do a single test run, remotely (currently, Sauce Labs via CircleCI, w/custom Firefox on Windows profile)
test-ci: build-testable
	$(KARMA) start  --browsers SL_Firefox --single-run

# Start a karma browser and leave it open, useful for doing multiple test runs during development,
# without the browser setup/teardown time.
karma-start: .npm
	$(KARMA) start --browsers Chrome --no-watch

# Do a single test run for a karma browser already started with `make karma-start`
run-tests: build-testable
	$(KARMA) run --browsers Chrome

### Maintenance

# An attempt to get make to treat npm as a dependency
.npm: package.json
	npm install
	touch .npm

# Clean all artifacts
clean:
	rm -f dist/*

.PHONY : clean all test lint build-testable karma-start run-tests
