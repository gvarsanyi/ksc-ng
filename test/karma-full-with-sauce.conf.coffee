
module.exports = (config) ->

  standard_conf = require './karma.conf'
  standard_conf config


  unless process.env.SAUCE_USERNAME
    credfile = __dirname + '/sauce.json'
    unless require('fs').existsSync credfile
      console.error 'Create ' + credfile + ' with your credentials based on ' +
                    'the sauce-sample.json file.'
      process.exit 1
    else
      process.env.SAUCE_USERNAME   = require('./sauce').username
      process.env.SAUCE_ACCESS_KEY = require('./sauce').accessKey


  custom_launchers =
    SL_IE9:
      base:        'SauceLabs'
      browserName: 'internet explorer'
      version:     '9'
    SL_IE10:
      base:        'SauceLabs'
      browserName: 'internet explorer'
      version:     '10'
    SL_IE11:
      base:        'SauceLabs'
      browserName: 'internet explorer'
      version:     '11'


  config.set
    browsers:        ['Chrome', 'Firefox'].concat Object.keys custom_launchers
    captureTimeout:  120000
    customLaunchers: custom_launchers
    reporters:       config.reporters.concat 'saucelabs'
