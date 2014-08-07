
describe 'app.service', ->

  describe 'error', ->

    error = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        error = $injector.get 'ksc.error'


    it 'Has error classes only', ->
      keys = (k for k, v of error when not v instanceof Error)
      expect(keys.length).toBe 0

    it 'Access to types', ->
      for name, class_ref of error.type
        expected = name + 'Error: \n  a: 1\n  b: 2'
        try
          throw new class_ref {a: 1, b: 2}
        catch err
          expect(String err).toBe expected


    describe 'Throw all registered error types', ->

      it 'with string message', ->
        for name, error_ref of error
          expected = name + 'Error: XXX'
          try
            error_ref 'XXX'
          catch err
            expect(String err).toBe expected

      it 'with dictionary message', ->
        for name, error_ref of error
          expected = name + 'Error: \n  a: 1\n  b: 2'
          try
            error_ref {a: 1, b: 2}
          catch err
            expect(String err).toBe expected

      it 'with dictionary message having no JSON.stringify', ->
        json_stringify = JSON.stringify
        JSON.stringify = -> throw new Error
        for name, error_ref of error
          expected = name + 'Error: \n  a: 1\n  b: 2'
          try
            error_ref {a: 1, b: 2}
          catch err
            expect(String err).toBe expected
        JSON.stringify = json_stringify

      it 'with no message', ->
        for name, error_ref of error
          expected = name + 'Error: '
          try
            error_ref()
          catch err
            expect(String err).toBe expected
