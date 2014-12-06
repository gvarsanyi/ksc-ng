
describe 'app.service', ->

  describe 'util', ->

    error = util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        error = $injector.get 'ksc.error'
        util  = $injector.get 'ksc.util'


    describe 'Method .isKeyConform()', ->

      it 'Basic scenarios', ->
        expect(util.isKeyConform (->)).toBe false
        expect(util.isKeyConform {}).toBe false
        expect(util.isKeyConform true).toBe false
        expect(util.isKeyConform false).toBe false
        expect(util.isKeyConform null).toBe false
        expect(util.isKeyConform()).toBe false
        expect(util.isKeyConform NaN).toBe false
        expect(util.isKeyConform '').toBe false
        expect(util.isKeyConform 'x').toBe true
        expect(util.isKeyConform 0).toBe true
        expect(util.isKeyConform 1).toBe true
        expect(util.isKeyConform -1).toBe true
        expect(util.isKeyConform 1.23).toBe true

      it 'Throws error when requested', ->
        try
          error.Key 'xkey'
        catch _err
          KeyError = _err.constructor

        try
          error.ArgumentType 'xkey'
        catch _err
          ArgumentTypeError = _err.constructor

        try
          util.isKeyConform null, true
        catch _err
          err = _err
        expect(err instanceof KeyError).toBe true

        try
          util.isKeyConform null, 'xxx'
        catch _err
          err = _err
        expect(err instanceof KeyError).toBe true
        expect(err.message.indexOf('description: "xxx"') > -1).toBe true

        try
          util.isKeyConform null, 'yyy', 4
        catch _err
          err = _err
        expect(err instanceof ArgumentTypeError).toBe true
        expect(err.message.indexOf('description: "yyy"') > -1).toBe true
        expect(err.message.indexOf('argument: 4') > -1).toBe true

