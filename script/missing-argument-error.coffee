
app.factory 'ksc.MissingArgumentError', [
  'ksc.ArgumentError',
  (ArgumentError) ->

    class MissingArgumentError extends ArgumentError

      constructor: (name, n) ->
        super 'Missing argument' + @msg name, n
]
