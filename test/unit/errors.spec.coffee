
describe 'app.factory', ->

  describe 'Errors', ->

    Errors = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        Errors = $injector.get 'ksc.Errors'


    it 'No instance use (no properties on instance)', ->
      obj = new Errors
      keys = (k for k of obj)
      expect(keys.length).toBe 0

    it 'Class instance has error classes and debug property only', ->
      keys = (k for k, v of Errors when not v instanceof Error)
      expect(keys.length).toBe 0

    describe 'Throw all registered error types', ->

      it 'with string message', ->
        for name, ErrorClassRef of Errors
          expected = name + 'Error: XXX'
          try
            throw new ErrorClassRef 'XXX'
          catch err
            expect(String err).toBe expected

      it 'with dictionary message', ->
        for name, ErrorClassRef of Errors
          expected = name + 'Error: \n  a: 1\n  b: 2'
          try
            throw new ErrorClassRef {a: 1, b: 2}
          catch err
            expect(String err).toBe expected

      it 'with dictionary message having no JSON.stringify', ->
        json_stringify = JSON.stringify
        JSON.stringify = -> throw new Error
        for name, ErrorClassRef of Errors
          expected = name + 'Error: \n  a: 1\n  b: 2'
          try
            throw new ErrorClassRef {a: 1, b: 2}
          catch err
            expect(String err).toBe expected
        JSON.stringify = json_stringify

      it 'with no message', ->
        for name, ErrorClassRef of Errors
          expected = name + 'Error: '
          try
            throw new ErrorClassRef
          catch err
            expect(String err).toBe expected
