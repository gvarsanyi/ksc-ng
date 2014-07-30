
describe 'app.service', ->

  describe 'utils', ->

    utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        utils = $injector.get 'ksc.utils'


    describe 'Method .defineGetSet()', ->

      it 'Set invisible getter', ->
        obj = {}
        getter = -> 1 + 1

        utils.defineGetSet obj, 'a', getter

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

        utils.defineGetSet obj, 'a', getter, setter

        found_keys = {}
        for own k of obj
          found_keys[k] = true

        obj.a = 3

        expect(found_keys.a).toBeUndefined()
        expect(obj.a).toBe 2
        expect(obj.x).toBe 1

      it 'Set visible getter/setter', ->
        obj = {}
        utils.defineGetSet obj, 'a', (->), true

        found_keys = {}
        for k of obj
          found_keys[k] = true

        expect(found_keys.a).toBe true
