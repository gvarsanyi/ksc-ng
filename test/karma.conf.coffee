
module.exports = (config) ->

  files     = []
  reporters = []

  if process.argv.length > 4
    for file in process.argv[4 ...]
      if file.substr(file.length - 8) isnt '.spec.js' and
      file.substr(file.length - 12) isnt '.spec.coffee'
        file += '.spec.coffee'
      files.push 'unit/' + file
    preprocessors =
      'unit/**/*.coffee': 'coffee'
  else
    files.push 'unit/**/*.coffee'
    reporters.push 'coverage'
    preprocessors =
      'tmp/**/*.js':      'coverage'
      'unit/**/*.coffee': 'coffee'


  config.set
    autoWatch:        false
    browsers:         ['Chrome']
    coverageReporter:
      instrumenter:
        '**/*.coffee': 'istanbul'
      reporters:      [{type: 'text'}
                       {type: 'html', dir: 'coverage/'}]
    files:            ['dep/angular.js'
                       'dep/angular-*.js'
                       'dep/test/**/*.js'
                       'tmp/**/*.js'].concat files
    frameworks:       ['jasmine']
    logLevel:         'WARN'
    preprocessors:    preprocessors
    reporters:        ['spec'].concat reporters
    singleRun:        true
