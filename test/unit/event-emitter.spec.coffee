
describe 'app.factory', ->

  describe 'EventEmitter', ->

    $interval = $scope = $timeout = EventEmitter = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        $rootScope   = $injector.get '$rootScope'

        $interval    = $injector.get '$interval'
        $scope       = $rootScope.$new().$new()
        $timeout     = $injector.get '$timeout'
        EventEmitter = $injector.get 'ksc.EventEmitter'

    it 'Methods .emit(), .on(), unsubscribe()', ->
      event = new EventEmitter
      emits = []

      event.emit 'a'
      event.emit 'b'

      unsubscriber = event.on 'a', 'b', (args...) ->
        emits.push args

      expect(-> event.emit()).toThrow()

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

      event.emit 'a', 'xx'
      event.emit 'a'
      event.emit 'b', 'b'

      unsubscriber = event.if 'a', 'b', (args...) ->
        emits.push args

      event.emit 'a'
      event.emit 'a', 'x'
      event.emit 'a', 'y', 'y2'
      event.emit 'b', 'z'
      event.emit 'c', 'xxx'

      expect(emits.length).toBe 6
      expect(emits[0][0]).toBeUndefined()
      expect(emits[1][0]).toBe 'b'
      expect(emits[2][0]).toBeUndefined()
      expect(emits[3][0]).toBe 'x'
      expect(emits[3][1]).toBeUndefined()
      expect(emits[4][0]).toBe 'y'
      expect(emits[4][1]).toBe 'y2'
      expect(emits[5][0]).toBe 'z'
      expect(typeof unsubscriber).toBe 'function'
      unsubscriber()

      event.emit 'a'
      event.emit 'b', 'z'
      expect(emits.length).toBe 6

    it 'Method .if1()', ->
      event = new EventEmitter
      emits = []

      event.emit 'a', 'xx'
      event.emit 'a'

      unsubscriber = event.if1 'a', 'b', (args...) ->
        emits.push args

      event.emit 'a'
      event.emit 'a', 'x'
      event.emit 'a', 'y', 'y2'
      event.emit 'b', 'y', 'y2'
      event.emit 'b', 'y3'

      expect(emits.length).toBe 2
      expect(emits[0][0]).toBeUndefined()
      expect(emits[1][1]).toBe 'y2'

      expect(-> unsubscriber()).not.toThrow()

      event.emit 'a'
      expect(emits.length).toBe 2

    it 'Scope unsubscriber', ->
      event = new EventEmitter
      emits = []

      event.emit 'a', 'x'

      response = event.on 'a', 'b', $scope, (args...) ->
        emits.push args
      expect(response).toBe true

      event.emit 'a'
      event.emit 'b', 'y', 'y2'
      event.emit 'b', 'y3'

      expect(emits.length).toBe 3
      expect(emits[0][0]).toBeUndefined()
      expect(emits[1][1]).toBe 'y2'
      expect(emits[2][0]).toBe 'y3'

      $scope.$destroy()

      event.emit 'a'
      expect(emits.length).toBe 3

    it 'Subscription edge cases', ->
      event = new EventEmitter

      expect(-> event.emitted 'a').not.toThrow()

      expect(-> event.on 1, ->).toThrow()
      expect(-> event.on '', ->).toThrow()
      expect(-> event.on 'xx').toThrow()
      expect(-> event.on 'xx', 1).toThrow()
      expect(-> event.on 'xx', {}, (->)).toThrow()
      expect(-> event.on 'xx', null, (->)).toThrow()
      expect(-> event.on 'xx', (->), (->)).toThrow()

      expect(-> event.on()).toThrow()
      expect(-> event.on1()).toThrow()
      expect(-> event.if()).toThrow()
      expect(-> event.if1()).toThrow()

      expect(-> event.emit 1).toThrow()

      unsubscribe = event.on 'a', ->
      unsubscribe.add event.on 'a', ->
      unsubscribe()
      expect(-> unsubscribe()).not.toThrow()

    it 'Unsubscribe target argument', ->
      unsubscriber = EventEmitter::unsubscriber()

      event = new EventEmitter
      emits = []

      event.emit 'a', 'x'

      response = event.on 'a', 'b', unsubscriber, (args...) ->
        emits.push args

      expect(response).toBe true

      event.emit 'a'
      event.emit 'b', 'y', 'y2'
      event.emit 'b', 'y3'

      expect(emits.length).toBe 3
      expect(emits[0][0]).toBeUndefined()
      expect(emits[1][1]).toBe 'y2'
      expect(emits[2][0]).toBe 'y3'

      unsubscriber()

      event.emit 'a'
      expect(emits.length).toBe 3

    it 'Methods .halt() and .unhalt()', ->
      event = new EventEmitter
      response = null
      event.on 'a', (value) ->
        response = value

      event.emit 'a', 'x'
      expect(response).toBe 'x'

      event.halt()
      event.emit 'a', 'y'
      expect(response).toBe 'x'

      event.unhalt()
      event.emit 'a', 'z'
      expect(response).toBe 'z'

    it 'Method .emitted()', ->
      event = new EventEmitter

      event.emit 'a', 'x'

      expect(-> event.emitted()).toThrow()

      expect(event.emitted('a')[0]).toBe 'x'
      expect(event.emitted('b')).toBe false

    it 'Unsubscribes $timeout and $interval', ->
      unsubscriber = EventEmitter::unsubscriber()

      unsubscriber.add (to2 = $timeout (-> timeout_flushed += 1)), 1000
      unsubscriber()

      interval_flushed = 0
      timeout_flushed  = 0

      unsubscriber.add $interval (-> interval_flushed += 1), 1000
      unsubscriber.add (to1 = $timeout (-> timeout_flushed += 1)), 1000
      unsubscriber.add $timeout (-> timeout_flushed += 1), 1000

      $timeout.cancel to1

      $interval.flush 1001
      $timeout.flush 1001

      unsubscriber.add $timeout (-> timeout_flushed += 1), 1000

      $interval.flush 1001
      $timeout.flush 1001

      unsubscriber()

      $interval.flush 1001
      $timeout.flush 1001

      expect(interval_flushed).toBe 2
      expect(timeout_flushed).toBe 2

      expect(-> unsubscriber()).not.toThrow()

      expect(-> unsubscriber.add 1).toThrow()
      expect(-> unsubscriber.add ->).toThrow()
      expect(-> unsubscriber.add {}).toThrow()
