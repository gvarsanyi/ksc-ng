
describe 'app.service', ->

  describe 'utils', ->

    utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        utils = $injector.get 'ksc.utils'


    describe 'Method .isEnumerable()', ->

      it 'Identifies properties', ->
        obj = {}
        Object.defineProperty obj, 'a', {enumerable: true, value: 1}
        Object.defineProperty obj, 'b', {enumerable: false, value: 1}

        expect(utils.isEnumerable obj, 'a').toBe true
        expect(utils.isEnumerable obj, 'b').toBe false

      it 'Returns false on edge cases', ->
        expect(utils.isEnumerable {}, true).toBe false
        expect(utils.isEnumerable {}).toBe false
        expect(utils.isEnumerable null, 'a').toBe false
        expect(utils.isEnumerable()).toBe false
