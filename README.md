ksc-ng
======

A series of angular factories and services revolving around models, async data
binding, sharing and segmenting.

# Using as a dependency
1. Install
    bower install ksc-ng
2. Link it in your app
    <script src='ksc-ng/dist/ksc.min.js'></script>
3. Use components as dependency
    example ?= angular.module 'example', ['ksc']
    example.factory 'namespace.endpointArchetypeFactory', [
      'ksc.RestList',
      (RestList) ->
        # ...

Tip: check out the example implementations in folder archetypes/

# Developing

## Quick installation usage manual
### Requirements
- npm (comes with nodejs)
- make

### Download and check out tools
    git clone https://github.com/gvarsanyi/ksc-ng.git
    cd ksc-ng

### One-time install dependencies
    npm update
#### If you have problems with npm, try:
    npm cache clean
    npm update

### Create JavaScript distributables
    make dist

Creates dist/ folder with the following files:
- ksc.js
- ksc-sans-comments.js
- ksc.min.js
- ksc.min.js.gz

Minifier also checks for unused chunks of code.

### Create docs off of codo inline documentation
    make doc
See generated docs at <project_dir>/doc/index.html

### Run tests with Chrome
    make test
See test coverage details at <project_dir>/test/coverage/Chrome<version>/index.html

### Run tests with Chrome, Firefox and IE9-10-11 (via saucelabs)
    make full-test
Be sure to configure `test/sauce.json` or your bash environment for your sauce account.
See test coverage details at <project_dir>/test/coverage/<browsers>/index.html

### Lint check
    make lint

### All tasks combined: test, lint, doc, dist
    make all
Does not do full-test (Chrome-test only)
