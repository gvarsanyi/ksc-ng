
describe 'EditableRestRecord', ->
  $http = EditableRestRecord = Record = url = null

  beforeEach ->
    module 'app'
    inject ($injector) ->
      $http              = $injector.get '$httpBackend'
      EditableRestRecord = $injector.get 'ksc.EditableRestRecord'
      Record             = $injector.get 'ksc.Record'

      url = '/api/Test'


  it 'Instace of Record', ->
    record = new EditableRestRecord
    expect(record instanceof Record).toBe true

  it 'Save', ->
    expect(-> (new EditableRestRecord)._restSave()).toThrow() # missing endpoint

    record = new EditableRestRecord {x: 1, y: 2}, endpoint: {url}

    record.y = 3

    expect(record.y).toBe 3
    expect(record._changes).toBe 1
    expect(record._changedKeys.y).toBe true

    response = {x: 1, y: 3}

    $http.expectPUT(url).respond response

    cb_response = promise_response = null

    promise = record._restSave (err, response) ->
      cb_response = response.data

    promise.then (response) ->
      promise_response = response.data

    $http.flush()

    expect(record.x).toBe 1
    expect(record.y).toBe 3
    expect(record._changes).toBe 0
    expect(cb_response).toEqual response
    expect(promise_response).toEqual response
