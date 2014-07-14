
describe 'RestList', ->
  $http = List = RestList = null

  id_url = '/api/Test/<id>'
  url    = '/api/Test/'

  list_cfg =
    endpoint: {responseProperty: 'elements', url}
    record:   {endpoint: {url: id_url}}

  list_response =
    success: true
    elements: [{id: 43, x: 'a'}, {id: 24, x: 'b'}]

  beforeEach ->
    module 'app'
    inject ($injector) ->
      $http    = $injector.get '$httpBackend'
      List     = $injector.get 'ksc.List'
      RestList = $injector.get 'ksc.RestList'

  it 'Constructs a vanilla Array instance', ->
    list = new RestList

    expect(Array.isArray list).toBe true
    expect(list.length).toBe 0

  it 'option.class is ksc.RestList and inherited from ksc.List', ->
    list = new RestList

    expect(list.options.class instanceof List).toBe true
    expect(list.options.class).toBe RestList.prototype

  it 'Method .restGetRaw()', ->
    list = new RestList list_cfg

    $http.expectGET(url).respond list_response

    response = null

    promise = list.restGetRaw()
    promise.success (data) ->
      response = data

    $http.flush()

    expect(response.success).toBe true
    expect(response.elements.length).toBe 2

#   it 'Method .restGet()', ->
#     list = new RestList list_cfg
#
#     $http.expectGET(url).respond list_response
#
#     response = null
#     expect(list.map[43].x).toBe 'a'
#     expect(list.length).toBe 2
