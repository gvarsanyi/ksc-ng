
describe 'app.factory', ->

  describe 'Utils', ->

    Utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        Utils = $injector.get 'ksc.Utils'


    it 'No instance use (no properties on instance)', ->
      obj = new Utils
      keys = (k for k of obj)
      expect(keys.length).toBe 0

    describe 'Method .defineGetSet()', ->

      it 'Set invisible getter', ->
        obj = {}
        getter = -> 1 + 1

        Utils.defineGetSet obj, 'a', getter

        found_keys = {}
        for own k of obj
          found_keys[k] = true

        obj.a = 3

        expect(found_keys.a).toBeUndefined()
        expect(obj.a).toBe 2
        expect(obj.x).toBeUndefined()

      it 'Set invisible getter/setter', ->
        obj = {}
        getter = -> 1 + 1
        setter = -> @x = 1

        Utils.defineGetSet obj, 'a', getter, setter

        found_keys = {}
        for own k of obj
          found_keys[k] = true

        obj.a = 3

        expect(found_keys.a).toBeUndefined()
        expect(obj.a).toBe 2
        expect(obj.x).toBe 1

      it 'Set visible getter/setter', ->
        obj = {}
        Utils.defineGetSet obj, 'a', (->), true

        found_keys = {}
        for k of obj
          found_keys[k] = true

        expect(found_keys.a).toBe true

    describe 'Method .defineGetSet()', ->

