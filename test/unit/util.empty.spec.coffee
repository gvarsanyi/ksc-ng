
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

      describe 'Array method look-up order', ->
        it 'List\'s own .pop() method', ->
          list = [1]
          spyOn list, 'pop'
          util.empty list
          expect(list.pop).toHaveBeenCalled()

        it 'List\'s ._origFn.pop() method', ->
          list = [1]
          list.pop = undefined
          list._origFn = pop: ->
          spyOn list._origFn, 'pop'
          util.empty list
          expect(list._origFn.pop).toHaveBeenCalled()

        it 'Native Array::pop() method (no ._origFn available)', ->
          list = [1]
          list.pop = undefined
          spyOn Array.prototype, 'pop'
          util.empty list
          expect(Array.prototype.pop).toHaveBeenCalled()

        it 'Native Array::pop() method (._origFn available)', ->
          list = [1]
          list.pop = undefined
          list._origFn = {}
          spyOn Array.prototype, 'pop'
          util.empty list
          expect(Array.prototype.pop).toHaveBeenCalled()

      it 'Error if non-object is passed', ->
        expect(-> util.empty {a: 1}, [1, 2], 'a').toThrow()

      it 'Error if no argument is passed', ->
        expect(-> util.empty()).toThrow()
