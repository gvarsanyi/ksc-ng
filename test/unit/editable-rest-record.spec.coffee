
describe 'app.factory', ->

  describe 'EditableRestRecord', ->

    $httpBackend = EditableRestRecord = Record = url = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        $httpBackend       = $injector.get '$httpBackend'
        EditableRestRecord = $injector.get 'ksc.EditableRestRecord'
        Record             = $injector.get 'ksc.Record'

        url = '/api/Test'


    it 'Instace of Record', ->
      record = new EditableRestRecord
      expect(record instanceof Record).toBe true

    it 'Save', ->
      expect(-> (new EditableRestRecord)._restSave()).toThrow() # missing endpnt

      record = new EditableRestRecord {x: 1, y: 2}, endpoint: {url}

      record.y = 3

      expect(record.y).toBe 3
      expect(record._changes).toBe 1
      expect(record._changedKeys.y).toBe true

      response = {x: 1, y: 3}

      $httpBackend.expectPUT(url).respond response

      cb_response = promise_response = null

      promise = record._restSave (err, response) ->
        cb_response = response.data

      promise.then (response) ->
        promise_response = response.data

      $httpBackend.flush()

      expect(record.x).toBe 1
      expect(record.y).toBe 3
      expect(record._changes).toBe 0
      expect(cb_response).toEqual response
      expect(promise_response).toEqual response

    it 'Save error', ->
      record = new EditableRestRecord {x: 1, y: 2}, endpoint: {url}

      record.y = 3

      response = {error: 1}

      $httpBackend.expectPUT(url).respond 500, response

      cb_response = promise_response = null

      promise = record._restSave (err, response, etc...) ->
        cb_response = [err, response.data]

      promise.then (->), (response) ->
        promise_response = ['error', response.data]

      $httpBackend.flush()

      expect(record.x).toBe 1
      expect(record.y).toBe 3
      expect(record._changes).toBe 1
      expect(record._changedKeys.y).toBe true
      expect(cb_response[0] instanceof Error).toBe true
      expect(cb_response[1]).toEqual response
      expect(promise_response[0]).toBe 'error'
      expect(promise_response[1]).toEqual response
