
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
