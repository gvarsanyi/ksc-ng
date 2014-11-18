
describe 'app.service', ->

  describe 'util', ->

    util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        util = $injector.get 'ksc.util'


    describe 'Method .defineGetSet()', ->

      it 'Set invisible getter', ->
        obj = {}
        getter = -> 1 + 1

        util.defineGetSet obj, 'a', getter

        found_keys = {}
        for own k of obj
          found_keys[k] = true

        expect(-> obj.a = 3).toThrow()

        expect(found_keys.a).toBeUndefined()
        expect(obj.a).toBe 2
        expect(obj.x).toBeUndefined()

      it 'Set invisible getter/setter', ->
        obj = {}
        getter = -> 1 + 1
        setter = -> @x = 1

        util.defineGetSet obj, 'a', getter, setter

        found_keys = {}
        for own k of obj
          found_keys[k] = true

        obj.a = 3

        expect(found_keys.a).toBeUndefined()
        expect(obj.a).toBe 2
        expect(obj.x).toBe 1

      it 'Set visible getter/setter', ->
        obj = {}
        util.defineGetSet obj, 'a', (->), true

        found_keys = {}
        for k of obj
          found_keys[k] = true

        expect(found_keys.a).toBe true
