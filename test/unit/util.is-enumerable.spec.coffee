
describe 'app.service', ->

  describe 'util', ->

    util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        util = $injector.get 'ksc.util'


    describe 'Method .isEnumerable()', ->

      it 'Identifies properties', ->
        obj = {}
        Object.defineProperty obj, 'a', {enumerable: true, value: 1}
        Object.defineProperty obj, 'b', {enumerable: false, value: 1}

        expect(util.isEnumerable obj, 'a').toBe true
        expect(util.isEnumerable obj, 'b').toBe false

      it 'Returns false on edge cases', ->
        expect(util.isEnumerable {}, true).toBe false
        expect(util.isEnumerable {}).toBe false
        expect(util.isEnumerable null, 'a').toBe false
        expect(util.isEnumerable()).toBe false
