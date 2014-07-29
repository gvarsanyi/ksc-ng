
app.factory 'ksc.ArgumentError', ->

  class ArgumentError extends Error

    constructor: (name, n) ->
      super 'Argument error' + @msg name, n

    msg: (name, n) ->
      msg = ''
      if n?
        msg += ' #' + n
      if name?
        msg += ': ' + name
      msg

