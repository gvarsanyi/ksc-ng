
describe 'app.service', ->

  describe 'util', ->

    util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        util = $injector.get 'ksc.util'


    describe 'Method .defineValue()', ->

      it 'Set read-only invisible value', ->
        obj = {}
        util.defineValue obj, 'a', 'x'

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
        util.defineValue obj, 'a', 'x', true

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
        util.defineValue obj, 'a', 'x', true, true

        found_keys = {}
        for own k of obj
          found_keys[k] = true

        expect(found_keys.a).toBe true
        expect(obj.a).toBe 'x'

        obj.a = 2

        expect(obj.a).toBe 2

      it 'Reset to writable', ->
        obj = {}
        util.defineValue obj, 'a', 'x'
        expect(obj.a).toBe 'x'
        obj.a = 2
        expect(obj.a).toBe 'x'
        expect(-> util.defineValue obj, 'a', 'x', true).not.toThrow()
        obj.a = 2
        expect(obj.a).toBe 2
