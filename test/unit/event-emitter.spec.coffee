
describe 'EventEmitter', ->
  $scope = EventEmitter = null

  beforeEach ->
    module 'app'
    inject ($injector) ->
      $rootScope = $injector.get '$rootScope'
      $scope = $rootScope.$new().$new()
      EventEmitter = $injector.get 'ksc.EventEmitter'

  it 'Methods .emit(), .on(), unsubscribe()', ->
    event = new EventEmitter
    emits = []

    event.emit 'a'
    event.emit 'b'

    unsubscriber = event.on 'a', 'b', (args...) ->
      emits.push args

    event.emit 'a'
    event.emit 'a', 'x'
    event.emit 'a', 'y', 'y2'
    event.emit 'b', 'z'
    event.emit 'c', 'xxx'

    expect(emits.length).toBe 4
    expect(emits[0][0]).toBeUndefined()
    expect(emits[1][0]).toBe 'x'
    expect(emits[1][1]).toBeUndefined()
    expect(emits[2][0]).toBe 'y'
    expect(emits[2][1]).toBe 'y2'
    expect(emits[3][0]).toBe 'z'
    expect(typeof unsubscriber).toBe 'function'

    unsubscriber()
    event.emit 'a'
    event.emit 'b', 'z'
    expect(emits.length).toBe 4

  it 'Method .on1()', ->
    event = new EventEmitter
    emits = []

    event.emit 'a'
    event.emit 'b'

    unsubscriber = event.on1 'a', 'b', (args...) ->
      emits.push args

    event.emit 'a'
    event.emit 'a', 'x'
    event.emit 'a', 'y', 'y2'

    expect(emits.length).toBe 1
    expect(emits[0][0]).toBeUndefined()

    expect(-> unsubscriber()).not.toThrow()

    event.emit 'a'
    expect(emits.length).toBe 1

  it 'Method .if()', ->
    event = new EventEmitter
    emits = []

    event.emit 'a'
    event.emit 'b', 'b'

    unsubscriber = event.if 'a', 'b', (args...) ->
      emits.push args

    event.emit 'a'
    event.emit 'a', 'x'
    event.emit 'a', 'y', 'y2'
    event.emit 'b', 'z'
    event.emit 'c', 'xxx'

    expect(emits.length).toBe 5
    expect(emits[0][0]).toBe 'b'
    expect(emits[1][0]).toBeUndefined()
    expect(emits[2][0]).toBe 'x'
    expect(emits[2][1]).toBeUndefined()
    expect(emits[3][0]).toBe 'y'
    expect(emits[3][1]).toBe 'y2'
    expect(emits[4][0]).toBe 'z'
    expect(typeof unsubscriber).toBe 'function'
    unsubscriber()

    event.emit 'a'
    event.emit 'b', 'z'
    expect(emits.length).toBe 5
