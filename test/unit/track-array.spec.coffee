
describe 'app.service', ->

  track_array = null

  beforeEach ->
    module 'app'
    inject ($injector) ->
      track_array = $injector.get 'ksc.trackArray'

  it 'Function .trackArray()', ->
    arr = [1, 2, 3]
    store = {}

    changed = 0

    setter = (index, value, setter_fn) ->
      if setter_fn String value
        changed += 1

    getter = (index, value) ->
      value * -1

    track_array arr, store, setter, getter

    expect(arr.length).toBe 3
    expect(arr[0]).toBe -1
    expect(arr._store[0]).toBe '1'

    console.log '-e1', arr.pop
    expect(arr.pop()).toBe -3
    console.log '-e2'
    expect(arr.length).toBe 2
    expect(arr.push 13).toBe 3
    expect(arr[2]).toBe -13

    arr[2] = 23
    expect(arr[2]).toBe -23
    expect(arr._store[2]).toBe '23'
