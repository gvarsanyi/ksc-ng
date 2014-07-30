
describe 'app.service', ->

  describe 'utils', ->

    utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        utils = $injector.get 'ksc.utils'


    describe 'Method .isObject()', ->

      it 'Matches an object', ->
        expect(utils.isObject {}).toBe true
        expect(utils.isObject (->)).toBe false

      it 'Matches multiple objects', ->
        expect(utils.isObject {}, {a: 'x'}, [1, 2, 3]).toBe true
        expect(utils.isObject [], null, {}).toBe false
        expect(utils.isObject {}, (->)).toBe false

      it 'Requires 1+ arguments', ->
        expect(-> utils.isObject()).toThrow()
