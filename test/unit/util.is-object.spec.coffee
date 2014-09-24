
describe 'app.service', ->

  describe 'util', ->

    util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        util = $injector.get 'ksc.util'


    describe 'Method .isObject()', ->

      it 'Matches an object', ->
        expect(util.isObject {}).toBe true
        expect(util.isObject (->)).toBe false

      it 'Matches multiple objects', ->
        expect(util.isObject {}, {a: 'x'}, [1, 2, 3]).toBe true
        expect(util.isObject [], null, {}).toBe false
        expect(util.isObject {}, (->)).toBe false

      it 'Requires 1+ arguments', ->
        expect(-> util.isObject()).toThrow()
