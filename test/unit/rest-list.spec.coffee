
describe 'RestList', ->
  $http = List = RestList = null
  expected_raw_response = list_cfg = list_response = null

  id_url = '/api/Test/<id>'
  url    = '/api/Test/'

  beforeEach ->
    module 'app'
    inject ($injector) ->
      $http    = $injector.get '$httpBackend'
      List     = $injector.get 'ksc.List'
      RestList = $injector.get 'ksc.RestList'

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

  it 'Method .restGetRaw(callback)', ->
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

  it 'Method .restGetRaw(query_params, callback)', ->
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

  it 'Method .restLoad(query_params, callback)', ->
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

  it 'Method .restSave(records..., callback)', ->
    list = new RestList
    list.push {id: 1, x: 'a'}
    list[0].x = 'b'
    expect(-> list.restSave list[0]).toThrow() # options.record.endpoint.url req

    list = new RestList list_cfg
    list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'}

    expect(-> list.restSave()).toThrow() # no records passed in

    expect(-> list.restSave list[0]).toThrow() # not changed
    expect(-> list.restSave 43).toThrow() # not on the list

    list[0].x = 'b'
    expect(-> list.restSave list[0], list[0]).toThrow() # not unique

    expected_url = id_url.replace '<id>', '1'
    $http.expectPUT(expected_url).respond {id: 1, x: 'b', y: 'y'}

    list.restSave list[0]

    $http.flush()

    expect(list[0].y).toBe 'y'

  it 'Method .restSave(records..., callback) with bulkSave', ->
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

  it 'Method .restDelete(records..., callback) with bulkDelete', ->
    list = new RestList endpoint: {url, bulkDelete: true}

    list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'}
    list[0].x = 'x'

    $http.expectDELETE(url).respond {x: 'ee'}

    list.restDelete list[2], list[1]

#     $http.flush()
#
#     expect(list.length).toBe 1
#     expect(list.map[2]).toBeUndefined()
#     expect(list.map[3]).toBeUndefined()
#     expect(list.map[1].x).toBe 'x'
#     expect(list.map[1]._changes).toBe 1
