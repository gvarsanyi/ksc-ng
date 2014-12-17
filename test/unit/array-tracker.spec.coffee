
describe 'app.service', ->

  ArrayTracker = arr = getter = setter = store = tracker = util = null

  beforeEach ->
    module 'app'
    inject ($injector) ->
      ArrayTracker = $injector.get 'ksc.ArrayTracker'
      util = $injector.get 'ksc.util'

      arr = [1, 2, 3]
      store = {}

      setter = (index, value, next_fn, setter_type) ->
        # console.log 'set:', index, value, next_fn, setter_type
        next_fn String value

      getter = (index, value) ->
        # console.log 'get:', index, value
        value * -1

      tracker = new ArrayTracker arr,
        get:   getter
        set:   setter
        store: store


  describe 'ArrayTracker', ->

    it 'Construction', ->
      expect(arr._tracker instanceof ArrayTracker).toBe true
      expect(arr._tracker).toBe tracker
      expect(tracker.store).toBe store
      expect(tracker.list).toBe arr
      expect(typeof Object.getOwnPropertyDescriptor(arr, 0).get).toBe 'function'
      expect(store[0]).toBe '1'
      expect(arr[0]).toBe -1
      expect(arr.length).toBe 3
      expect(Array.isArray arr).toBe true
      expect(Array.isArray store).toBe false

    it 'Retains store values', ->
      store = {a: 1, b: 2, 0: 99, 1: 1000}
      arr = [1]
      tracker = new ArrayTracker arr, {store}
      expect(arr).toEqual [1]
      expect(store).toEqual {a: 1, b: 2, 0: 1, 1: 1000}
      arr.push 2, 3
      expect(store).toEqual {a: 1, b: 2, 0: 1, 1: 2, 2: 3}

    it 'Creates store object if not provided', ->
      tracker = new ArrayTracker [1]
      expect(tracker.list[0]).toBe 1
      expect(tracker.store[0]).toBe 1

    it 'Enumerable properties match with regular arrays', ->
      x = [-1, -2, -3]
      count = 0
      diff  = 0
      for k of x
        count += 1
      for k, v of arr
        if v isnt x[k]
          diff += 1
        count -= 1
      expect(count).toBe 0
      expect(diff).toBe 0

    it 'util.empty() compliance', ->
      util.empty arr
      expect(arr.length).toBe 0

      count = 0
      for k of store
        count += 1
      expect(count).toBe 0

    it 'Class methods .plainify() and .process()', ->
      expect(ArrayTracker.plainify tracker).toBeUndefined()
      expect(arr.length).toBe 3
      expect(arr[0]).toBe '1'
      expect(Object.getOwnPropertyDescriptor(arr, 0).value).toBe '1'

      expect(ArrayTracker.process tracker).toBeUndefined()
      expect(arr[0]).toBe -1
      obj_setter = typeof Object.getOwnPropertyDescriptor(arr, 0).set
      expect(obj_setter).toBe 'function'

    it 'Method .unload() restores original functions/properties', ->
      arr = [1, 2, 3]
      pop = arr.pop
      tracker = new ArrayTracker arr

      expect(arr.length).toBe 3
      expect(arr[0]).toBe 1
      expect(arr.pop).not.toBe pop

      expect(tracker.unload()).toBeUndefined()
      expect(arr.length).toBe 3
      expect(arr[0]).toBe 1
      expect(arr._tracker).toBeUndefined()
      expect(arr.pop).toBe pop

      expect((key for key of tracker.store).length).toBe 0

      # won't restore properties that were deleted originally
      arr = [1, 2, 3]
      delete arr.pop # isn't supposed to do anything, pop() lives on prototype
      arr.push = 1
      arr.shift = undefined
      tracker = new ArrayTracker arr
      tracker.unload()
      expect(arr.pop).toBe pop
      expect(arr.push).toBe 1
      expect(arr.shift).toBeUndefined()

    it 'Method .unload(true) keeps store object values', ->
      arr = [1, 2, 3]
      tracker = new ArrayTracker arr, store: store = {}
      expect(arr._tracker).toBe tracker
      expect(store[0]).toBe 1
      tracker.unload true
      expect(arr._tracker).toBeUndefined()
      expect(store[0]).toBe 1

    it 'Update element', ->
      expect(arr[1] = 50).toBe 50
      expect(arr[1]).toBe -50

    describe 'Overridden Array methods', ->

      it '.pop()', ->
        expect(arr.pop()).toBe -3
        expect(arr.length).toBe 2
        expect(store[2]).toBeUndefined()

        expect(arr.pop()).toBe -2
        expect(arr.pop()).toBe -1
        expect(arr.length).toBe 0
        expect(arr.pop()).toBeUndefined()
        expect(arr.length).toBe 0

      it '.shift()', ->
        expect(arr.shift()).toBe -1
        expect(arr.length).toBe 2
        expect(store[2]).toBeUndefined()
        expect(store[0]).toBe '2'

        expect(arr.shift()).toBe -2
        expect(arr.shift()).toBe -3
        expect(arr.length).toBe 0
        expect(arr.shift()).toBeUndefined()
        expect(arr.length).toBe 0

      it '.push()', ->
        expect(arr.push()).toBe 3
        expect(arr.length).toBe 3

        arr.pop() while arr.length # empty

        expect(arr.push()).toBe 0

        expect(arr.push(11)).toBe 1
        expect(arr.length).toBe 1
        expect(arr[0]).toBe -11
        expect(store[0]).toBe '11'

        expect(arr.push(12, 13)).toBe 3
        expect(arr.length).toBe 3
        expect(arr[2]).toBe -13
        expect(store[2]).toBe '13'

      it '.unshift()', ->
        expect(arr.unshift()).toBe 3
        expect(arr.length).toBe 3

        arr.shift() while arr.length # empty

        expect(arr.unshift()).toBe 0

        expect(arr.unshift(11)).toBe 1
        expect(arr.length).toBe 1
        expect(arr[0]).toBe -11
        expect(store[0]).toBe '11'

        expect(arr.unshift(12, 13)).toBe 3
        expect(arr.length).toBe 3
        expect(arr[0]).toBe -12
        expect(store[0]).toBe '12'
        expect(arr[1]).toBe -13
        expect(store[1]).toBe '13'
        expect(arr[2]).toBe -11

      it '.slice()', ->
        expect(arr.slice 1, 5).toEqual [-2, -3]
        expect(arr.slice 1, 2).toEqual [-2]
        expect(arr.slice 1, -1).toEqual [-2]
        expect(arr.slice 5).toEqual []
        expect(arr.slice 1).toEqual [-2, -3]
        expect(arr.slice -2).toEqual [-2, -3]

      it '.splice()', ->
        arr.push 4, 5, 6, 7, 8, 9, 10

        expect(arr.splice 1, 2, 12).toEqual [-2, -3]
        expect(arr[0]).toBe -1
        expect(arr[1]).toBe -12
        expect(arr[2]).toBe -4
        expect(arr.length).toBe 9
        expect(arr[8]).toBe -10

        expect(arr.splice 0.1, -1.1, 11).toEqual []
        expect(arr[0]).toBe -11
        expect(arr.length).toBe 10

        expect(arr.splice -100, 0, 10).toEqual []
        expect(arr[0]).toBe -10
        expect(arr.length).toBe 11

        expect(arr.splice -1, 20).toEqual [-10]
        expect(arr.length).toBe 10

      it '.sort()', ->
        arr.push 2
        arr.sort()
        expect(arr[0]).toBe -1
        expect(arr[1]).toBe -2
        expect(arr[2]).toBe -2
        expect(arr[3]).toBe -3

      it '.sort(fn)', ->
        arr.push 2
        count = 0
        arr.sort (a, b) ->
          count += 1
          if a > b then 1 else if a is b then 0 else -1
        expect(arr[0]).toBe -1
        expect(arr[1]).toBe -2
        expect(arr[2]).toBe -2
        expect(arr[3]).toBe -3

      it '.reverse()', ->
        arr.push 2
        arr.reverse()
        expect(arr[0]).toBe -2
        expect(arr[1]).toBe -3
        expect(arr[2]).toBe -2
        expect(arr[3]).toBe -1

    describe 'Event functions', ->

      it 'get', ->
        tracker.get = (index, value) ->
          expect(index).toBe 1
          expect(value).toBe '2'
          'yo'
        expect(arr[1]).toBe 'yo'

      describe 'set', ->
        it 'Using callback argument', ->
          tracker.set = (index, value, worker_fn, setter_type) ->
            expect(index).toBe 1
            expect(value).toBe 'yo'
            expect(setter_type).toBe 'external'
            worker_fn '10'
          expect(arr[1] = 'yo').toBe 'yo'
          expect(arr[1]).toBe -10

        it 'Not using callback argument', ->
          tracker.set = (index, value, worker_fn) ->
            expect(index).toBe 2
            expect(value).toBe 'yo'
            worker_fn()
          expect(arr[2] = 'yo').toBe 'yo'
          expect(arr[2]).toBeNaN()

          tracker.set = null

        describe 'setter_type accuracy and expected event counts', ->
          count = last_index = last_value = type_count = null
          beforeEach ->
            arr.push 30, 31, 32, 33, 34

            count = 0
            last_index = last_value = null
            type_count = {external: 0, move: 0, reload: 0}

            tracker.set = (index, value, worker_fn, setter_type) ->
              count += 1
              last_index = index
              last_value = value
              type_count[setter_type] += 1
              worker_fn()

          it 'With .push()', ->
            arr.push 99
            expect(last_index).toBe 8
            expect(last_value).toBe 99
            expect(count).toBe 1
            expect(type_count.external).toBe 1
            expect(type_count.move).toBe 0
            expect(type_count.reload).toBe 0

          it 'With .unshift()', ->
            arr.unshift 98
            expect(last_index).toBe 0
            expect(last_value).toBe 98
            expect(count).toBe 9
            expect(type_count.external).toBe 1
            expect(type_count.move).toBe 8
            expect(type_count.reload).toBe 0

          it 'With .splice()', ->
            arr.splice 2, 3, 97, 96
            expect(last_index).toBe 3
            expect(last_value).toBe 96
            expect(count).toBe 5
            expect(type_count.external).toBe 2
            expect(type_count.move).toBe 3
            expect(type_count.reload).toBe 0

          it 'With .sort()', ->
            arr.sort()
            expect(last_index).toBe 7
            expect(last_value).toBe '34'
            expect(count).toBe 8
            expect(type_count.external).toBe 0
            expect(type_count.move).toBe 0
            expect(type_count.reload).toBe 8

          it 'With .reverse()', ->
            arr.reverse()
            expect(last_index).toBe 7
            expect(last_value).toBe '1'
            expect(count).toBe 8
            expect(type_count.external).toBe 0
            expect(type_count.move).toBe 0
            expect(type_count.reload).toBe 8

      describe 'del', ->

        count = last_index = last_value = null
        beforeEach ->
          arr.push 4, 5, 6, 7, 8, 9, 10
          count = 0
          last_index = last_value = null
          tracker.del = (index, value) ->
            count += 1
            last_index = index
            last_value = value

        it 'Basic scenario', ->
          expect(arr.pop()).toBe -10
          expect(store[9]).toBeUndefined()
          expect(last_index).toBe 9
          expect(last_value).toBe '10'
          expect(count).toBe 1

        it 'Always deletes the last', ->
          expect(arr.shift()).toBe -1
          expect(last_index).toBe 9
          expect(last_value).toBe '10'
          expect(count).toBe 1

        it 'Should not delete any (inserted.length == cut_count)', ->
          arr.splice 2, 2, 97, 96
          expect(last_index).toBe null
          expect(last_value).toBe null
          expect(count).toBe 0

        it 'Deletes only 1 (del_count = cut_count - inserted.length)', ->
          arr.splice 2, 2, 96
          expect(last_index).toBe 9
          expect(last_value).toBe '10'
          expect(count).toBe 1

        it 'Deletes many', ->
          arr.splice 1, 2
          expect(last_index).toBe 8
          expect(last_value).toBe '9'
          expect(count).toBe 2

        it 'Does not delete from store if del function returns false', ->
          tracker.del = (index, value) ->
            false # should prevent updating store

          expect(arr.pop()).toBe -10
          expect(store[9]).toBe '10'


    describe 'Exception handling', ->

      it 'Constructor requires array as first argument', ->
        expect(-> new ArrayTracker).toThrow()
        expect(-> new ArrayTracker 1).toThrow()
        expect(-> new ArrayTracker 're').toThrow()
        expect(-> new ArrayTracker {}).toThrow()
        expect(-> new ArrayTracker true).toThrow()
        expect(-> new ArrayTracker null).toThrow()

      it 'Options must be an object', ->
        expect(-> new ArrayTracker [], 1).toThrow()
        expect(-> new ArrayTracker [], false).toThrow()
        expect(-> new ArrayTracker [], 'ds').toThrow()

      it 'Double tracking not allowed', ->
        expect(-> new ArrayTracker arr).toThrow()

      it 'Store must be object type', ->
        expect(-> new ArrayTracker [], store: false).toThrow()
        expect(-> new ArrayTracker [], store: 'fdsfs').toThrow()
        expect(-> new ArrayTracker [], store: true).toThrow()
        expect(-> new ArrayTracker [], store: null).toThrow()

      it 'Get/set/del/move functions def', ->
        expect(-> new ArrayTracker [], {get: []}).toThrow()
        expect(-> new ArrayTracker [], {set: 'x'}).toThrow()
        expect(-> new ArrayTracker [], {del: 1}).toThrow()
        expect(-> tracker.get = true).toThrow()
        expect(-> tracker.set = false).toThrow()
        expect(-> tracker.del = {}).toThrow()###
