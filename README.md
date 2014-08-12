rx-list-record
==============

A series of angular factories and services revolving around models, async data
binding, sharing and segmenting.

## Quick installation usage manual
### Requirements
- git client
- npm (comes with nodejs)
- make

### Download and check out tools
    git clone https://github.com/gvarsanyi/rx-list-record.git
    cd rx-list-record

### One-time install dependencies
    npm update
#### If you have problems with npm, try:
    npm cache clean
    npm update

### Create JavaScript package
#### Non-minified JavaScript version only (creates: libs.js)
    make js
#### Non-minified and minified versions (creates: libs.js, lis.min.js, lis.min.js.gz)
    make jsmin
Minifier also checks for unused chunks of code

### Create docs off of codo inline documentation
    make test
See generated docs at <project_dir>/doc/index.html

### Run tests
    make test
See test coverage details at <project_dir>/test/coverage/PhantomJS<version>/index.html

### Lint check
    make lint

### All checks combined: test, lint, doc, jsmin
    make check
