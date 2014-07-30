
describe 'app.service', ->

  describe 'errors', ->

    errors = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        errors = $injector.get 'ksc.errors'


    it 'Has error classes only', ->
      keys = (k for k, v of errors when not v instanceof Error)
      expect(keys.length).toBe 0


    describe 'Throw all registered error types', ->

      it 'with string message', ->
        for name, ErrorClassRef of errors
          expected = name + 'Error: XXX'
          try
            throw new ErrorClassRef 'XXX'
          catch err
            expect(String err).toBe expected

      it 'with dictionary message', ->
        for name, ErrorClassRef of errors
          expected = name + 'Error: \n  a: 1\n  b: 2'
          try
            throw new ErrorClassRef {a: 1, b: 2}
          catch err
            expect(String err).toBe expected

      it 'with dictionary message having no JSON.stringify', ->
        json_stringify = JSON.stringify
        JSON.stringify = -> throw new Error
        for name, ErrorClassRef of errors
          expected = name + 'Error: \n  a: 1\n  b: 2'
          try
            throw new ErrorClassRef {a: 1, b: 2}
          catch err
            expect(String err).toBe expected
        JSON.stringify = json_stringify

      it 'with no message', ->
        for name, ErrorClassRef of errors
          expected = name + 'Error: '
          try
            throw new ErrorClassRef
          catch err
            expect(String err).toBe expected
