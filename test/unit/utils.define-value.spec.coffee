
describe 'app.service', ->

  describe 'utils', ->

    utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        utils = $injector.get 'ksc.utils'


    describe 'Method .defineValue()', ->

      it 'Set read-only invisible value', ->
        obj = {}
        utils.defineValue obj, 'a', 'x'

        found_keys = {}
        for own k of obj
          found_keys[k] = true

        expect(found_keys.a).toBeUndefined()
        expect(obj.a).toBe 'x'

        obj.a = 2

        found_keys = {}
        for own k of obj
          found_keys[k] = true

        expect(found_keys.a).toBeUndefined()
        expect(obj.a).toBe 'x'

      it 'Set r/w invisible value', ->
        obj = {}
        utils.defineValue obj, 'a', 'x', true

        found_keys = {}
        for own k of obj
          found_keys[k] = true

        expect(found_keys.a).toBeUndefined()
        expect(obj.a).toBe 'x'

        obj.a = 2

        found_keys = {}
        for own k of obj
          found_keys[k] = true

        expect(found_keys.a).toBeUndefined()
        expect(obj.a).toBe 2

      it 'Set r/w value', ->
        obj = {}
        utils.defineValue obj, 'a', 'x', true, true

        found_keys = {}
        for own k of obj
          found_keys[k] = true

        expect(found_keys.a).toBe true
        expect(obj.a).toBe 'x'

        obj.a = 2

        expect(obj.a).toBe 2

      it 'Reset to writable', ->
        obj = {}
        utils.defineValue obj, 'a', 'x'
        expect(obj.a).toBe 'x'
        obj.a = 2
        expect(obj.a).toBe 'x'
        expect(-> utils.defineValue obj, 'a', 'x', true).not.toThrow()
        obj.a = 2
        expect(obj.a).toBe 2
