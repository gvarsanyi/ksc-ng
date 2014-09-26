
describe 'app.service', ->

  describe 'util', ->

    util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        util = $injector.get 'ksc.util'


    describe 'Method .empty()', ->
      describe 'Array', ->
        it 'Pops elements, but leaves properties', ->
          a = [1, 2, 3]
          a.x = 1
          util.empty a
          expect(a.length).toBe 0
          expect(a[0]).toBeUndefined()
          expect(a.x).toBe 1

      describe 'Object', ->
        it 'Deletes all owned elements', ->
          a = {a: 1, b: 2}
          b = Object.create a
          b.a = 3
          b.c = 4

          util.empty b

          expect(b.c).toBeUndefined()
          expect(b.a).toBe 1
          expect(b.hasOwnProperty 'a').toBeFalsy()

      it 'Error if non-object is passed', ->
        expect(-> util.empty {a: 1}, [1, 2], 'a').toThrow()

      it 'Error if no argument is passed', ->
        expect(-> util.empty()).toThrow()
