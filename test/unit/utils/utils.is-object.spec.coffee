
describe 'app.factory', ->

  describe 'Utils', ->

    Utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        Utils = $injector.get 'ksc.Utils'


    describe 'Method .isObject()', ->

      it 'Matches an object', ->
        expect(Utils.isObject {}).toBe true
        expect(Utils.isObject (->)).toBe false

      it 'Matches multiple objects', ->
        expect(Utils.isObject {}, {a: 'x'}, [1, 2, 3]).toBe true
        expect(Utils.isObject [], null, {}).toBe false
        expect(Utils.isObject {}, (->)).toBe false

      it 'Requires 1+ arguments', ->
        expect(-> Utils.isObject()).toThrow()
