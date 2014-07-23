
describe 'RestRecord', ->
  $http = RestRecord = Record = url = null

  beforeEach ->
    module 'app'
    inject ($injector) ->
      $http      = $injector.get '$httpBackend'
      RestRecord = $injector.get 'ksc.RestRecord'
      Record     = $injector.get 'ksc.Record'

      url = '/api/Test'


  it 'Instace of Record', ->
    record = new RestRecord
    expect(record instanceof Record).toBe true

  it 'Load', ->
    expect(-> (new RestRecord)._restLoad()).toThrow() # missing endpoint

    record = new RestRecord null, endpoint: {url}

    response = {x: 1, y: 2}

    $http.expectGET(url).respond response

    cb_response = promise_response = null

    promise = record._restLoad (err, response) ->
      cb_response = response.data

    promise.then (response) ->
      promise_response = response.data

    $http.flush()

    expect(record.x).toBe 1
    expect(record.y).toBe 2
    expect(cb_response).toEqual response
    expect(promise_response).toEqual response


    record = new RestRecord null, endpoint: {url}

    response = {x: 1, y: 2}

    $http.expectGET(url).respond response

    record._restLoad()

    $http.flush()

    expect(record.x).toBe 1
    expect(record.y).toBe 2

  it 'Load error', ->
    record = new RestRecord null, endpoint: {url}

    response = {error: 1}

    $http.expectGET(url).respond 500, response

    cb_response = promise_response = null

    promise = record._restLoad (err, response) ->
      cb_response = [err, response.data]

    promise.then (->), (response) ->
      promise_response = ['error', response.data]

    $http.flush()

    expect(record.x).toBeUndefined()
    expect(record.error).toBeUndefined()
    expect(cb_response[0] instanceof Error).toBe true
    expect(cb_response[1]).toEqual response
    expect(promise_response[0]).toBe 'error'
    expect(promise_response[1]).toEqual response
