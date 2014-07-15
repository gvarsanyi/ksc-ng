
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

    $http.expectGET(expected_url).respond list_response

    response = null

    spyable = {callback: ->}
    spyOn spyable, 'callback'

    expected_raw_response.config.url = expected_url

    expected_changed_records = insert: list_response.elements

    promise = list.restLoad {x: 1, y: 2}, (err, changed_records, raw) ->
      insert = (rec._entity() for rec in changed_records.insert)
      spyable.callback err, {insert}, JSON.parse JSON.stringify raw

    promise.success (data) ->
      response = data

    $http.flush()

    expect(response.success).toBe true
    expect(response.elements.length).toBe 2
    expect(spyable.callback).toHaveBeenCalledWith null,
                                                  expected_changed_records,
                                                  expected_raw_response

  it 'Method .restSave(records..., callback)', ->
    list = new RestList list_cfg
    list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'}

    expect(-> list.restSave list[0]).toThrow() # not changed
    expect(-> list.restSave 43).toThrow() # not on the list

    list[0].x = 'b'
    expect(-> list.restSave list[0], list[0]).toThrow() # not unique

    expected_url = id_url.replace '<id>', '1'
    $http.expectPUT(expected_url).respond {id: 1, x: 'b', y: 'y'}

    list.restSave list[0]

    $http.flush()

    expect(list[0].y).toBe 'y'

