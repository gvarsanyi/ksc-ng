
describe 'app.factory', ->

  describe 'Utils', ->

    Utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        Utils = $injector.get 'ksc.Utils'


    describe 'Method .isEnumerable()', ->

      it 'Identifies properties', ->
        obj = {}
        Object.defineProperty obj, 'a', {enumerable: true, value: 1}
        Object.defineProperty obj, 'b', {enumerable: false, value: 1}

        expect(Utils.isEnumerable obj, 'a').toBe true
        expect(Utils.isEnumerable obj, 'b').toBe false

      it 'Returns false on edge cases', ->
        expect(Utils.isEnumerable {}, true).toBe false
        expect(Utils.isEnumerable {}).toBe false
        expect(Utils.isEnumerable null, 'a').toBe false
        expect(Utils.isEnumerable()).toBe false
