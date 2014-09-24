
describe 'app.service', ->

  describe 'util', ->

    util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        util = $injector.get 'ksc.util'


    describe 'Method .isFunction()', ->

      it 'Matches a function', ->
        expect(util.isFunction (->)).toBe true
        expect(util.isFunction 1).toBe false

      it 'Matches multiple functions', ->
        expect(util.isFunction (->), (->), (->)).toBe true
        expect(util.isFunction (->), null, (->)).toBe false
        expect(util.isFunction 1, (->)).toBe false

      it 'Requires 1+ arguments', ->
        expect(-> util.isFunction()).toThrow()
