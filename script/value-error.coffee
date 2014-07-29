
app.factory 'ksc.ValueError', ->

  class ValueError extends Error

    constructor: (value, desc) ->
      super 'Value error' + @msg value, desc

    msg: (value, desc) ->
      msg = ''
      if value and desc
        msg += ': ' + typeof value + ' `' + value + '` - ' + desc
      else if value
        msg += ': ' + value
      msg
