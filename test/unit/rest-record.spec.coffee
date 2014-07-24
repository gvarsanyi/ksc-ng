
describe 'app.factory', ->

  describe 'RestRecord', ->

    $httpBackend = RestRecord = Record = url = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        $httpBackend = $injector.get '$httpBackend'
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
