
describe 'app.factory', ->

  describe 'BatchLoader', ->

    $httpBackend = BatchLoader = RestRecord = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        $httpBackend = $injector.get '$httpBackend'
        BatchLoader  = $injector.get 'ksc.BatchLoader'
        RestRecord   = $injector.get 'ksc.RestRecord'


    it 'Generic scenario: mixed responses', ->
      bootstrap = new BatchLoader '/api/Bootstrap',
        Test:  '/api/Test'
        Other: '/api/Other'

      record1 = new RestRecord null, endpoint: url: '/api/Test'
      record2 = new RestRecord null, endpoint: url: '/api/Other'

      err1 = raw1 = err2 = raw2 = response1 = response2 = null

      promise1 = record1._restLoad (err, raw) ->
        err1 = err
        raw1 = raw

      promise2 = record2._restLoad (err, raw) ->
        err2 = err
        raw2 = raw

      promise1.then (raw) ->
        response1 = raw

      promise2.then null, (raw) ->
        response2 = raw

      expect(record1._restPending).toBe 1
      expect(record2._restPending).toBe 1

      response = [{status: 200, body: {hello: 1}}
                  {status: 500, body: {hello: 2}}]

      $httpBackend.expectPUT('/api/Bootstrap').respond response

      bootstrap.open = false # this also triggers bootstrap.flush()
      bootstrap.open = false # won't flush twice, just testing the gate

      $httpBackend.flush()

      expect(err1).toBe null
      expect(err2 instanceof Error).toBe true
      expect(response1.data).toEqual {hello: 1}
      expect(response2.data).toEqual {hello: 2}
      expect(record1._restPending).toBe 0
      expect(record2._restPending).toBe 0
      expect(record1.hello).toBe 1
      expect(record2.hello).toBeUndefined()

    it 'Method .get() is dependent on .open state', ->
      loader = new BatchLoader 'x', x: 'x'
      expect(typeof loader.get 'x').toBe 'object'
      loader.open = false
      expect(loader.get 'x').toBe false

    it 'Method .get() returns false if no url matched', ->
      loader = new BatchLoader 'x', x: 'x'
      expect(loader.get 'y').toBe false

    it 'Property .open is always boolean', ->
      loader = new BatchLoader 'x', x: 'x'
      expect(loader.open).toBe true
      loader.open = 0
      expect(loader.open).toBe false
      loader.open = 1
      expect(loader.open).toBe true
      loader.open = {}
      expect(loader.open).toBe true
      loader.open = ''
      expect(loader.open).toBe false
      loader.open = null
      expect(loader.open).toBe false

    describe 'Error handling', ->

      it 'Constructor arguments', ->
        expect(-> new BatchLoader).toThrow()
        expect(-> new BatchLoader '', {a: 'x'}).toThrow()
        expect(-> new BatchLoader 1, {a: 'x'}).toThrow()
        expect(-> new BatchLoader {}, {a: 'x'}).toThrow()
        expect(-> new BatchLoader '/api/dsd').toThrow()
        expect(-> new BatchLoader '/api/dsd', true).toThrow()
        expect(-> new BatchLoader '/api/dsd', {'': 'x'}).toThrow()
        expect(-> new BatchLoader '/api/dsd', {'a': 1}).toThrow()
        expect(-> new BatchLoader '/api/dsd', {'a': {}}).toThrow()

      it 'Method .get() arguments', ->
        loader = new BatchLoader 'x', x: 'x'

        expect(-> loader.get()).toThrow()
        expect(-> loader.get '').toThrow()
        expect(-> loader.get true).toThrow()
        expect(-> loader.get {}).toThrow()
        expect(-> loader.get 'x', true).toThrow()
        expect(-> loader.get 'x', '').toThrow()
        expect(-> loader.get 'x', 'dsd').toThrow()
        expect(-> loader.get 'x', false).toThrow()
        expect(-> loader.get 'x', {x: 'a'}).not.toThrow()

      it 'Incoherent response', ->
        bootstrap = new BatchLoader '/api/Bootstrap', {Test: '/api/Test'}

        record = new RestRecord null, endpoint: url: '/api/Test'

        response = null

        promise = record._restLoad()
        promise.then null, (raw) ->
          response = raw

        $httpBackend.expectPUT('/api/Bootstrap').respond {}

        bootstrap.flush()

        $httpBackend.flush()

        expect(response.data).toEqual {}

      it 'Response error', ->
        bootstrap = new BatchLoader '/api/Bootstrap',
          Test:  '/api/Test'
          Other: '/api/Other'

        record1 = new RestRecord null, endpoint: url: '/api/Test'
        record2 = new RestRecord null, endpoint: url: '/api/Other'

        err1 = raw1 = err2 = raw2 = response1 = response2 = null

        promise1 = record1._restLoad (err, raw) ->
          err1 = err
          raw1 = raw

        promise2 = record2._restLoad (err, raw) ->
          err2 = err
          raw2 = raw

        promise1.then null, (raw) ->
          response1 = raw

        promise2.then null, (raw) ->
          response2 = raw

        $httpBackend.expectPUT('/api/Bootstrap').respond 500, {}

        bootstrap.flush()

        $httpBackend.flush()

        expect(err1 instanceof Error).toBe true
        expect(err2 instanceof Error).toBe true
        expect(response1.data).toEqual {}
        expect(response2.data).toEqual {}
