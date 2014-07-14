
module.exports = (config) ->
  config.set
    autoWatch:        false
    browsers:         ['PhantomJS']
    coverageReporter:
      instrumenter:
        '**/*.coffee': 'istanbul'
      reporters:      [{type: 'text'}
                       {type: 'html', dir: 'coverage/'}]
    files:            ['dep/angular.js'
                       'dep/angular-*.js'
                       'dep/test/**/*.js'
                       'tmp/**/*.js'
                       'unit/**/*.coffee']
    frameworks:       ['jasmine']
    logLevel:         'WARN'
    preprocessors:
      'tmp/**/*.js':      'coverage'
      'unit/**/*.coffee': 'coffee'
    reporters:        ['spec', 'coverage']
    singleRun:        true
