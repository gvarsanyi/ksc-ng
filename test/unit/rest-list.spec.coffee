
describe 'RestList', ->
  $http = EditableRecord = List = RestList = null
  expected_raw_response = list_cfg = list_response = null

  id_url = '/api/Test/<id>'
  url    = '/api/Test/'

  beforeEach ->
    module 'app'
    inject ($injector) ->
      $http          = $injector.get '$httpBackend'
      EditableRecord = $injector.get 'ksc.EditableRecord'
      List           = $injector.get 'ksc.List'
      RestList       = $injector.get 'ksc.RestList'

      list_cfg =
        endpoint: {responseProperty: 'elements', url}
        record:   {endpoint: {url: id_url}}

      list_response =
        success: true
        elements: [{id: 43, x: 'a'}, {id: 24, x: 'b'}]

      # this is the layout after JSON.parse(JSON.stringify(data)) wrapping that
      # is in place for stripping functions (or turning them to nulls in arrays)
      expected_raw_response =
        data: list_response
        status: 200
        config:
          method: 'GET'
          transformRequest: [null]
          transformResponse: [null]
          url: url
          headers:
            Accept: 'application/json, text/plain, */*'


  it 'Constructs a vanilla Array instance', ->
    list = new RestList

    expect(Array.isArray list).toBe true
    expect(list.length).toBe 0

  it 'option.class is ksc.RestList and inherited from ksc.List', ->
    list = new RestList

    expect(list.options.class instanceof List).toBe true
    expect(list.options.class).toBe RestList.prototype

  it 'Method .restGetRaw() with query params', ->
    list = new RestList list_cfg

    $http.expectGET(url).respond list_response

    response = null

    spyable = {callback: ->}
    spyOn spyable, 'callback'

    promise = list.restGetRaw (err, data) ->
      spyable.callback err, JSON.parse JSON.stringify data

    promise.success (data) ->
      response = data

    $http.flush()

    expect(response.success).toBe true
    expect(response.elements.length).toBe 2
    expect(spyable.callback).toHaveBeenCalledWith null, expected_raw_response

    # prep with url that already has query str
    list_cfg.endpoint.url            = '/api/Test?pre=1&pre2=2'
    expected_raw_response.config.url = '/api/Test?pre=1&pre2=2&ext=1'

    list = new RestList list_cfg

    $http.expectGET(expected_raw_response.config.url).respond list_response

    spyable = {callback: ->}
    spyOn spyable, 'callback'

    list.restGetRaw {ext: 1}, (err, data) ->
      spyable.callback err, JSON.parse JSON.stringify data

    $http.flush()

    expect(spyable.callback).toHaveBeenCalledWith null, expected_raw_response

    # prep url without query string url
    list_cfg.endpoint.url            = url
    expected_raw_response.config.url = url

    list = new RestList list_cfg

    $http.expectGET(url).respond list_response

    spyable = {callback: ->}
    spyOn spyable, 'callback'

    list.restGetRaw {}, (err, data) ->
      spyable.callback err, JSON.parse JSON.stringify data

    $http.flush()

    expect(spyable.callback).toHaveBeenCalledWith null, expected_raw_response

  it 'Method .restGetRaw() with query params and callback', ->
    list = new RestList
    expect(-> list.restGetRaw()).toThrow() # options.endpoint.url required

    list = new RestList list_cfg

    expected_url = url + '?x=1&y=2'

    $http.expectGET(expected_url).respond list_response

    response = null

    spyable = {callback: ->}
    spyOn spyable, 'callback'

    expected_raw_response.config.url = expected_url

    promise = list.restGetRaw {x: 1, y: 2}, (err, data) ->
      spyable.callback err, JSON.parse JSON.stringify data

    promise.success (data) ->
      response = data

    $http.flush()

    expect(response.success).toBe true
    expect(response.elements.length).toBe 2
    expect(spyable.callback).toHaveBeenCalledWith null, expected_raw_response

  it 'Method .restLoad()', ->
    list = new RestList list_cfg

    expected_url = url + '?x=1&y=2'
    expected_url2 = url + '?x=2&y=3'
    expected_url3 = url

    $http.expectGET(expected_url).respond list_response
    $http.expectGET(expected_url2).respond list_response
    $http.expectGET(expected_url3).respond list_response
    $http.expectGET(expected_url3).respond list_response

    response = null

    spyable = {callback: ->}
    spyOn spyable, 'callback'

    spyable2 = {callback: ->}
    spyOn spyable2, 'callback'

    expected_raw_response.config.url = expected_url

    expected_changed_records = insert: list_response.elements

    promise = list.restLoad {x: 1, y: 2}, (err, changed_records, raw) ->
      insert = (rec._entity() for rec in changed_records.insert)
      spyable.callback err, {insert}, JSON.parse JSON.stringify raw

    promise.success (data) ->
      response = data

    list.restLoad {x: 2, y: 3}
    list.restLoad spyable2.callback
    list.restLoad()

    $http.flush()

    expect(response.success).toBe true
    expect(response.elements.length).toBe 2
    expect(spyable.callback).toHaveBeenCalledWith null,
                                                  expected_changed_records,
                                                  expected_raw_response
    expect(spyable2.callback).toHaveBeenCalled()

  it 'Method .restLoad() auto identifying array in response', ->
    delete list_cfg.endpoint.responseProperty

    # array is one of the top-level properties
    list = new RestList list_cfg
    $http.expectGET(url).respond list_response
    list.restLoad()
    $http.flush()
    expect(list.length).toBe 2

    # response is just the array
    list = new RestList list_cfg
    $http.expectGET(url).respond list_response.elements
    list.restLoad()
    $http.flush()
    expect(list.length).toBe 2

    # no array in response - fail
    list = new RestList list_cfg
    expected_err = null
    $http.expectGET(url).respond {x: {a: 2}}
    list.restLoad (err) ->
      expected_err = err
    $http.flush()
    expect(expected_err instanceof Error).toBe true

  it 'Method .restSave()', ->
    list = new RestList
    list.push {id: 1, x: 'a'}
    expect(-> list.restSave list[0]).toThrow() # options.record.endpoint.url req

    list = new RestList record: {}
    list.push {id: 1, x: 'a'}
    expect(-> list.restSave list[0]).toThrow() # options.record.endpoint.url req

    list = new RestList list_cfg
    list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'}

    expect(-> list.restSave()).toThrow() # no records passed in

    expect(-> list.restSave 43).toThrow() # not on the list

    list[0].x = 'b'
    list[1].x = 'c'
    expect(-> list.restSave list[0], list[0]).toThrow() # not unique

    expected_url1 = id_url.replace '<id>', '1'
    expected_url2 = id_url.replace '<id>', '2'
    $http.expectPUT(expected_url1).respond {id: 1, x: 'b', y: 'y'}
    $http.expectPUT(expected_url2).respond {id: 2, x: 'c', z: 'z'}

    list.restSave list[0], list[1]

    $http.flush()
    expect(list[0].y).toBe 'y'
    expect(list[1].z).toBe 'z'

  it 'Method .restSave() with bulkSave', ->
    list = new RestList endpoint: {bulkSave: 'POST'}
    list.push {id: 1, x: 'a'}
    list[0].x = 'b'
    expect(-> list.restSave list[0]).toThrow() # options.endpoint.url required

    list = new RestList endpoint: {url, bulkSave: 'POST'}

    list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'}
    list[0].x = 'x'
    list[1].x = 'x'

    $http.expectPOST(url).respond [{id: 1, x: 'x'}, {id: 2, x: 'y', ext: 1}]

    list.restSave list[1], list[0], ->

    $http.flush()

    expect(list.length).toBe 3
    expect(list.map[2].ext).toBe 1
    expect(list.map[1].x).toBe 'x'
    expect(list.map[2].x).toBe 'y'
    expect(list.map[1]._changes).toBe 0
    expect(list.map[2]._changes).toBe 0

    list.options.endpoint.bulkSave = true # should be PUT not POST
    list[0].x = 'a'
    list[1].x = 'a'

    $http.expectPUT(url).respond [{id: 1, x: 'a'}, {id: 2, x: 'a'}]

    list.restSave list[1], list[0], ->

    $http.flush()

    expect(list.length).toBe 3
    expect(list.map[2].ext).toBeUndefined()
    expect(list.map[1].x).toBe 'a'
    expect(list.map[2].x).toBe 'a'
    expect(list.map[1]._changes).toBe 0
    expect(list.map[2]._changes).toBe 0
    expect(list.map[3]._changes).toBe 0

  it 'Method .restSave() with composite IDs', ->
    list = new RestList
      endpoint: {url}
      record:
        idProperty: ['id1', 'id2']
        endpoint: url: id_url

    list.push {id1: 1, id2: 2, x: 'a'}
    list[0].x = 'b'

    expect(list[0]._id).toBe '1-2'
    expect(list[0]._primaryId).toBe 1

    expected_url = id_url.replace '<id>', '1'
    $http.expectPUT(expected_url).respond {id1: 1, id2: 2, x: 'b'}

    list.restSave list[0], ->

    $http.flush()

    expect(list[0]._saved.x).toBe 'b'

  it 'Method .restDelete()', ->
    list = new RestList
      endpoint: {url}
      record: endpoint: url: id_url

    list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'}
    list[0].x = 'x'

    expect(-> list.restDelete()).toThrow() # no record passed in

    $http.expectDELETE(id_url.replace '<id>', '1').respond {a: 1}
    $http.expectDELETE(id_url.replace '<id>', '2').respond {b: 1}

    responses = null

    spyable = {callback: ->}
    spyOn spyable, 'callback'

    promise = list.restDelete list.map[1], list.map[2], spyable.callback
    promise.then (_responses) -> # success path
      responses = _responses

    $http.flush()

    expect(list.length).toBe 1
    expect(responses.length).toBe 2
    expect(responses[0].data).toEqual {a: 1}
    expect(responses[0].config.url).toBe id_url.replace '<id>', '1'
    expect(responses[1].data).toEqual {b: 1}
    expect(responses[1].config.url).toBe id_url.replace '<id>', '2'
    expect(promise.success).toBeUndefined() # chained promises don't have
                                            # HttpPromise specific stuff
    expect(spyable.callback).toHaveBeenCalled()

  it 'Method .restDelete() with bulkDelete', ->
    list = new RestList endpoint: {url, bulkDelete: true}

    list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'}
    list[0].x = 'x'

    $http.expectDELETE(url).respond {x: 'ee'}

    spyable = {callback: ->}
    spyOn spyable, 'callback'

    list.restDelete list[2], list[1], spyable.callback

    $http.flush()

    expect(list.length).toBe 1
    expect(list.map[2]).toBeUndefined()
    expect(list.map[3]).toBeUndefined()
    expect(list.map[1].x).toBe 'x'
    expect(list.map[1]._changes).toBe 1
    expect(spyable.callback).toHaveBeenCalled()

  it 'Method .restDelete() with bulkDelete and composite IDs', ->
    list = new RestList
      endpoint: {url, bulkDelete: 1}
      record: idProperty: ['id1', 'id2']

    list.push {id1: 1, id2: 2, x: 'a'}, {id1: 2, id2: 3, x: 'a'}

    expect(list[0]._id).toBe '1-2'
    expect(list[0]._primaryId).toBe 1

    $http.expectDELETE(url).respond {yo: 1}

    list.restDelete list[0]

    $http.flush()

    expect(list.length).toBe 1

  it 'Save error', ->
    list = new RestList
      endpoint: {url}
      record: endpoint: url: id_url

    list.push new EditableRecord {id: 1, a: 2}

    list.map[1].a = 3
    expect(list.map[1]._changes).toBe 1

    response = {error: 1}

    $http.expectPUT(id_url.replace '<id>', '1').respond 500, response

    cb_response = promise_response = null

    promise = list.restSave 1, (err, changed_records, raw_response) ->
      cb_response = [err, raw_response.data]

    promise.then (->), (response) ->
      promise_response = ['error', response.data]

    $http.flush()

    expect(list.length).toBe 1
    expect(list.map[1].a).toBe 3
    expect(list.map[1]._changes).toBe 1
    expect(list.map[1]._changedKeys.a).toBe true
    expect(cb_response[0] instanceof Error).toBe true
    expect(cb_response[1]).toEqual response
    expect(promise_response[0]).toBe 'error'
    expect(promise_response[1]).toEqual response

  it 'Bulk save error', ->
    list = new RestList
      endpoint: {url, bulkSave: true}

    list.push new EditableRecord {id: 1, a: 2}

    list.map[1].a = 3
    expect(list.map[1]._changes).toBe 1

    response = {error: 1}

    $http.expectPUT(url).respond 500, response

    cb_response = promise_response = null

    promise = list.restSave 1, (err, changed_records, raw_response) ->
      cb_response = [err, raw_response.data]

    promise.then (->), (response) ->
      promise_response = ['error', response.data]

    $http.flush()

    expect(list.length).toBe 1
    expect(list.map[1].a).toBe 3
    expect(list.map[1]._changes).toBe 1
    expect(list.map[1]._changedKeys.a).toBe true
    expect(cb_response[0] instanceof Error).toBe true
    expect(cb_response[1]).toEqual response
    expect(promise_response[0]).toBe 'error'
    expect(promise_response[1]).toEqual response

  it 'Method .restLoad() error', ->
    list = new RestList list_cfg

    response = {error: 1}

    $http.expectGET(url).respond 500, response

    cb_response = promise_response = null

    promise = list.restLoad (err, changed_records, raw_response) ->
      cb_response = [err, raw_response.data]

    promise.then (->), (response) ->
      promise_response = ['error', response.data]

    $http.flush()

    expect(cb_response[0] instanceof Error).toBe true
    expect(cb_response[1]).toEqual response
    expect(promise_response[0]).toBe 'error'
    expect(promise_response[1]).toEqual response
