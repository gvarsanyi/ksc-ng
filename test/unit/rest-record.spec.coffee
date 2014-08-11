
describe 'app.factory', ->

  describe 'RestRecord', ->

    $httpBackend = $rootScope = BatchLoader = RestRecord = Record = url = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        $httpBackend = $injector.get '$httpBackend'
        $rootScope   = $injector.get '$rootScope'
        BatchLoader  = $injector.get 'ksc.BatchLoader'
        RestRecord   = $injector.get 'ksc.RestRecord'
        Record       = $injector.get 'ksc.Record'

        url = '/api/Test'


    it 'Instace of Record', ->
      record = new RestRecord
      expect(record instanceof Record).toBe true

    it 'Load', ->
      expect(-> (new RestRecord)._restLoad()).toThrow() # missing endpoint

      record = new RestRecord null, endpoint: {url}

      response = {x: 1, y: 2}

      $httpBackend.expectGET(url).respond response

      cb_response = promise_response = null

      expect(record._restPending).toBe 0

      promise = record._restLoad (err, response) ->
        cb_response = response.data

      promise.then (response) ->
        promise_response = response.data

      expect(record._restPending).toBe 1

      $httpBackend.flush()

      expect(record.x).toBe 1
      expect(record.y).toBe 2
      expect(cb_response).toEqual response
      expect(promise_response).toEqual response
      expect(record._restPending).toBe 0

      record = new RestRecord null, endpoint: {url}

      response = {x: 1, y: 2}

      $httpBackend.expectGET(url).respond response

      record._restLoad()

      $httpBackend.flush()

      expect(record.x).toBe 1
      expect(record.y).toBe 2

    it 'With batch loader', ->
      bootstrap = new BatchLoader '/api/Bootstrap', {Test: '/api/Test'}

      record = new RestRecord null, endpoint: url: '/api/Test'

      record._restLoad()

      expect(record._restPending).toBe 1

      response = [{status: 200, body: {hello: 1}}]

      $httpBackend.expectPUT('/api/Bootstrap').respond response

      bootstrap.open = false # this also triggers bootstrap.flush()

      $httpBackend.flush()

      expect(record._restPending).toBe 0
      expect(record.hello).toBe 1

    it 'Error handling for _option.endpoint.url', ->
      record = new RestRecord null
      expect(-> record._restLoad()).toThrow() # missing endpoint

      record = new RestRecord null, endpoint: {}
      expect(-> record._restLoad()).toThrow() # missing url

      record = new RestRecord null, endpoint: url: {}
      expect(-> record._restLoad()).toThrow() # url is not string

    it 'Load error', ->
      record = new RestRecord null, endpoint: {url}

      response = {error: 1}

      $httpBackend.expectGET(url).respond 500, response

      cb_response = promise_response = null

      promise = record._restLoad (err, response) ->
        cb_response = [err, response.data]

      promise.then (->), (response) ->
        promise_response = ['error', response.data]

      $httpBackend.flush()

      expect(record.x).toBeUndefined()
      expect(record.error).toBeUndefined()
      expect(cb_response[0] instanceof Error).toBe true
      expect(cb_response[1]).toEqual response
      expect(promise_response[0]).toBe 'error'
      expect(promise_response[1]).toEqual response

    it 'Cached - load twice', ->
      record = new RestRecord null, {cache: 1, endpoint: {url}}

      response = {x: 1}

      $httpBackend.expectGET(url).respond response

      raw_data1cb = raw_data2cb = raw_data1p = raw_data2p = raw_data3p = null

      expect(record.x).toBeUndefined()

      promise1 = record._restLoad (err, raw) ->
        raw_data1cb = raw.data
      promise1.then (raw) ->
        raw_data1p = raw.data

      $httpBackend.flush()

      expect(record.x).toBe 1

      promise2 = record._restLoad (err, raw) ->
        raw_data2cb = raw.data
      promise2.then (raw) ->
        raw_data2p = raw.data

      promise3 = record._restLoad()
      promise3.then (raw) ->
        raw_data3p = raw.data

      $rootScope.$apply() # fake promises .flush()

      expect(promise1).toBe promise2
      expect(raw_data1cb).toEqual raw_data2cb
      expect(raw_data1p).toEqual raw_data1cb
      expect(raw_data2p).toEqual raw_data1p
      expect(raw_data2p).toEqual raw_data3p

    it 'Cached - force load', ->
      record = new RestRecord null, {cache: 1, endpoint: {url}}

      response = {x: 1}

      $httpBackend.expectGET(url).respond response

      raw_data1cb = raw_data1p = raw_data2p = null

      expect(record.x).toBeUndefined()

      promise1 = record._restLoad (err, raw) ->
        raw_data1cb = raw.data
      promise1.then (raw) ->
        raw_data1p = raw.data

      $httpBackend.flush()

      expect(record.x).toBe 1

      $httpBackend.expectGET(url).respond response

      promise2 = record._restLoad true
      promise2.then (raw) ->
        raw_data2p = raw.data

      expect(record.x).toBe 1

      $httpBackend.flush()

      expect(promise1).not.toBe promise2
      expect(raw_data1cb).toEqual raw_data1p
      expect(raw_data1p).toEqual raw_data2p
