
app.factory 'ksc.KeyError', ->

  class KeyError extends Error

    constructor: (key, desc) ->
      super 'Key error' + @msg key, desc

    msg: (key, desc) ->
      msg = ''
      if key and desc
        msg += ': ' + key + ' - ' + desc
      else if key
        msg += ': ' + key
      msg
