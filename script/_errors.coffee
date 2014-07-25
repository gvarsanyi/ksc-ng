
app.factory 'ksc.TypeError', ->

  class TypeError extends Error

    constructor: (value, acceptable_types...) ->
      super 'Type error' + @msg value, acceptable_types...

    msg: (value, acceptable_types...) ->
      msg = ''
      if arguments.length > 0
        msg += ' for value <' + typeof value + '> `' + value + '`'
        if typeof acceptable_types[acceptable_types.length - 1] is 'boolean'
          unacceptable = acceptable_types.pop()
        if acceptable_types.length
          if unacceptable
            msg += ' vs required type'
          else
            msg += ' vs unacceptable type'
          if acceptable_types.length > 1
            msg += 's'
          msg += ': ' + acceptable_types.join ', '
      msg

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

app.factory 'ksc.ArgumentTypeError', [
  'ksc.ArgumentError', 'ksc.TypeError',
  (ArgumentError, TypeError) ->

    class ArgumentTypeError extends ArgumentError

      constructor: (name, n, value, acceptable_types...) ->
        msg = 'Argument type error'
        msg += @msg name, n
        msg += TypeError::msg value, acceptable_types...
        super msg
]

app.factory 'ksc.MissingArgumentError', [
  'ksc.ArgumentError',
  (ArgumentError) ->

    class MissingArgumentError extends ArgumentError

      constructor: (name, n) ->
        super @msg 'Missing argument' + name, n
]

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
