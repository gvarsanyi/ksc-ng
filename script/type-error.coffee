
app.factory 'ksc.TypeError', ->

  class TypeError extends Error

    constructor: (value, acceptable_types...) ->
      super 'Type error' + @msg value, acceptable_types...

    msg: (value, acceptable_types...) ->
      msg = ''
      if arguments.length > 0
        msg += ' for value `' + value + '`'
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
