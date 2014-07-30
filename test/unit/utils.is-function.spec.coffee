
describe 'app.service', ->

  describe 'utils', ->

    utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        utils = $injector.get 'ksc.utils'


    describe 'Method .isFunction()', ->

      it 'Matches a function', ->
        expect(utils.isFunction (->)).toBe true
        expect(utils.isFunction 1).toBe false

      it 'Matches multiple functions', ->
        expect(utils.isFunction (->), (->), (->)).toBe true
        expect(utils.isFunction (->), null, (->)).toBe false
        expect(utils.isFunction 1, (->)).toBe false

      it 'Requires 1+ arguments', ->
        expect(-> utils.isFunction()).toThrow()
