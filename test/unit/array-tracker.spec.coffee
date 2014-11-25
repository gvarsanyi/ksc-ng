
describe 'app.service', ->

  ArrayTracker = arr = getter = setter = store = tracker = null

  beforeEach ->
    module 'app'
    inject ($injector) ->
      ArrayTracker = $injector.get 'ksc.ArrayTracker'

      arr = [1, 2, 3]
      store = {}

      setter = (index, value, setter_fn) ->
        # console.log 'set:', index, value
        setter_fn String value

      getter = (index, value) ->
        # console.log 'get:', index, value
        value * -1

      tracker = new ArrayTracker arr, store, setter, getter


  describe 'ArrayTracker', ->

    it 'Construction', ->
      expect(arr._tracker instanceof ArrayTracker).toBe true
      expect(arr._tracker).toBe tracker
      expect(typeof Object.getOwnPropertyDescriptor(arr, 0).get).toBe 'function'
      expect(store[0]).toBe '1'
      expect(arr[0]).toBe -1
      expect(arr.length).toBe 3

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
        expect(arr[1]).toBe -12
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

      it '.reverse()', ->
        arr.push 2
        arr.reverse()
        expect(arr[0]).toBe -2
        expect(arr[1]).toBe -3
        expect(arr[2]).toBe -2
        expect(arr[3]).toBe -1
