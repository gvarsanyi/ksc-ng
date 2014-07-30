
describe 'app.factory', ->

  describe 'Utils', ->

    Utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        Utils = $injector.get 'ksc.Utils'


    describe 'Method .isFunction()', ->

      it 'Matches a function', ->
        expect(Utils.isFunction (->)).toBe true
        expect(Utils.isFunction 1).toBe false

      it 'Matches multiple functions', ->
        expect(Utils.isFunction (->), (->), (->)).toBe true
        expect(Utils.isFunction (->), null, (->)).toBe false
        expect(Utils.isFunction 1, (->)).toBe false

      it 'Requires 1+ arguments', ->
        expect(-> Utils.isFunction()).toThrow()
