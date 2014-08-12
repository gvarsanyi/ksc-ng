
describe 'app.factory', ->

  describe 'RestList', ->

    $httpBackend = BatchLoader = EditableRecord = List = RestList = null
    expected_raw_response = list_cfg = list_response = null

    id_url = '/api/Test/<id>'
    url    = '/api/Test/'

    beforeEach ->
      module 'app'
      inject ($injector) ->
        $httpBackend   = $injector.get '$httpBackend'
        BatchLoader    = $injector.get 'ksc.BatchLoader'
        EditableRecord = $injector.get 'ksc.EditableRecord'
        List           = $injector.get 'ksc.List'
        RestList       = $injector.get 'ksc.RestList'

        list_cfg =
          endpoint: {responseProperty: 'elements', url}
          record:   {endpoint: {url: id_url}}

        list_response =
          success: true
          elements: [{id: 43, x: 'a'}, {id: 24, x: 'b'}]

        # this is the layout after JSON.parse(JSON.stringify(data)) wrapping
        #  - this is in place to strip functions (or turning them to nulls in
        #    arrays)
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

    it 'Method .restGetRaw() with query params', ->
      list = new RestList list_cfg

      $httpBackend.expectGET(url).respond list_response

      response = null

      spyable = {callback: ->}
      spyOn spyable, 'callback'

      promise = list.restGetRaw (err, data) ->
        spyable.callback err, JSON.parse JSON.stringify data

      promise.success (data) ->
        response = data

      $httpBackend.flush()

      expect(response.success).toBe true
      expect(response.elements.length).toBe 2
      expect(spyable.callback).toHaveBeenCalledWith null, expected_raw_response

      # prep with url that already has query str
      list_cfg.endpoint.url            = '/api/Test?pre=1&pre2=2'
      expected_raw_response.config.url = '/api/Test?pre=1&pre2=2&ext=1'

      list = new RestList list_cfg

      target_url = expected_raw_response.config.url
      $httpBackend.expectGET(target_url).respond list_response

      spyable = {callback: ->}
      spyOn spyable, 'callback'

      list.restGetRaw {ext: 1}, (err, data) ->
        spyable.callback err, JSON.parse JSON.stringify data

      $httpBackend.flush()

      expect(spyable.callback).toHaveBeenCalledWith null, expected_raw_response

      # prep url without query string url
      list_cfg.endpoint.url            = url
      expected_raw_response.config.url = url

      list = new RestList list_cfg

      $httpBackend.expectGET(url).respond list_response

      spyable = {callback: ->}
      spyOn spyable, 'callback'

      list.restGetRaw {}, (err, data) ->
        spyable.callback err, JSON.parse JSON.stringify data

      $httpBackend.flush()

      expect(spyable.callback).toHaveBeenCalledWith null, expected_raw_response

    it 'Method .restGetRaw() with query params and callback', ->
      list = new RestList
      expect(-> list.restGetRaw()).toThrow() # options.endpoint.url required

      list = new RestList endpoint: url: 1
      expect(-> list.restGetRaw()).toThrow() # options.endpoint.url to be string

      list = new RestList list_cfg

      expected_url = url + '?x=1&y=2'

      $httpBackend.expectGET(expected_url).respond list_response

      response = null

      spyable = {callback: ->}
      spyOn spyable, 'callback'

      expected_raw_response.config.url = expected_url

      promise = list.restGetRaw {x: 1, y: 2}, (err, data) ->
        spyable.callback err, JSON.parse JSON.stringify data

      promise.success (data) ->
        response = data

      $httpBackend.flush()

      expect(response.success).toBe true
      expect(response.elements.length).toBe 2
      expect(spyable.callback).toHaveBeenCalledWith null, expected_raw_response

    it 'Method .restGetRaw() with batch loader', ->
      bootstrap = new BatchLoader '/api/Bootstrap', {Test: '/api/Test/'}

      list = new RestList list_cfg

      list.restLoad()

      expect(list.restPending).toBe 1

      response = [{status: 200, body: list_response}]

      $httpBackend.expectPUT('/api/Bootstrap').respond response

      bootstrap.open = false # this also triggers bootstrap.flush()

      $httpBackend.flush()

      expect(list.restPending).toBe 0
      expect(list.length).toBe 2
      expect(list[0].x).toBe 'a'

    it 'Method .restLoad()', ->
      list = new RestList list_cfg

      expected_url = url + '?x=1&y=2'
      expected_url2 = url + '?x=2&y=3'
      expected_url3 = url

      $httpBackend.expectGET(expected_url).respond list_response
      $httpBackend.expectGET(expected_url2).respond list_response
      $httpBackend.expectGET(expected_url3).respond list_response
      $httpBackend.expectGET(expected_url3).respond list_response

      expect(list.restPending).toBe 0

      response = null

      spyable = {callback: ->}
      spyOn spyable, 'callback'

      spyable2 = {callback: ->}
      spyOn spyable2, 'callback'

      expected_raw_response.config.url = expected_url

      expected_changed_records = insert: list_response.elements

      promise = list.restLoad {x: 1, y: 2}, (err, changed_records, raw) ->
        insert = (rec._entity() for rec in changed_records.add)
        spyable.callback err, {insert}, JSON.parse JSON.stringify raw

      promise.success (data) ->
        response = data

      expect(list.restPending).toBe 1

      list.restLoad {x: 2, y: 3}
      list.restLoad spyable2.callback
      list.restLoad()

      expect(list.restPending).toBe 4

      $httpBackend.flush()

      expect(response.success).toBe true
      expect(response.elements.length).toBe 2
      expect(spyable.callback).toHaveBeenCalledWith null,
                                                    expected_changed_records,
                                                    expected_raw_response
      expect(spyable2.callback).toHaveBeenCalled()
      expect(list.restPending).toBe 0

    it 'Method .restLoad() auto identifying array in response', ->
      delete list_cfg.endpoint.responseProperty

      # array is one of the top-level properties
      list = new RestList list_cfg
      $httpBackend.expectGET(url).respond list_response
      list.restLoad()
      $httpBackend.flush()
      expect(list.length).toBe 2

      # response is just the array
      list = new RestList list_cfg
      $httpBackend.expectGET(url).respond list_response.elements
      list.restLoad()
      $httpBackend.flush()
      expect(list.length).toBe 2

      # no array in response - fail
      list = new RestList list_cfg
      expected_err = null
      $httpBackend.expectGET(url).respond {x: {a: 2}}
      list.restLoad (err) ->
        expected_err = err
      $httpBackend.flush()
      expect(expected_err instanceof Error).toBe true

    describe 'Method .restSave()', ->

      it 'PUT and POST (update and new)', ->
        list = new RestList
        list.push {id: 1, x: 'a'}, {id: null, x: 'a'}
        expect(-> list.restSave list[0]).toThrow() # options.record.endpoint.url
        expect(-> list.restSave list[1]).toThrow() # options.record.endpoint.url

        list = new RestList record: endpoint: url: 1
        list.push {id: 1, x: 'a'}
        # options.record.endpoint.url to be string
        expect(-> list.restSave list[0]).toThrow()


        list = new RestList record: {}
        list.push {id: 1, x: 'a'}
        expect(-> list.restSave list[0]).toThrow() # options.record.endpoint.url

        list = new RestList list_cfg
        list.push {id: 1, x: 'a'}, {id: null, x: 'b'}, {id: 3, x: 'c'}

        expect(-> list.restSave()).toThrow() # no records passed in

        expect(-> list.restSave 43).toThrow() # not on the list

        list[0].x = 'b'
        list[1].x = 'c'
        expect(-> list.restSave list[0], list[0]).toThrow() # not unique

        expected_url1 = id_url.replace '<id>', '1'
        expected_url2 = url
        $httpBackend.expectPUT(expected_url1).respond {id: 1, x: 'b', y: 'y'}
        $httpBackend.expectPOST(expected_url2).respond {id: 2, x: 'c', z: 'z'}

        err = record_list = raw = null
        list.restSave list[0], list[1], (_err, _record_list, _raw...) ->
          err = _err
          record_list = _record_list
          raw = _raw

        $httpBackend.flush()
        expect(record_list[0]).toBe list[0]
        expect(record_list[1]).toBe list[1]
        expect(raw[0].data.id).toBe 1
        expect(raw[1].data.id).toBe 2
        expect(raw[0].config.method).toBe 'PUT'
        expect(raw[1].config.method).toBe 'POST'
        expect(list[0].y).toBe 'y'
        expect(list[1].z).toBe 'z'
        expect(list[1]._id).toBe 2

      it 'With composite id + bulkSave', ->
        list = new RestList
          endpoint: {url, bulkSave: true}
          record:   idProperty: ['id', 'x']

        list.push {id: 1, x: 2, a: 'a'}, {id: 1, x: 3, a: 'b'}

        list.map['1-2'].a = 'c'
        list.restSave list.map['1-2']

        $httpBackend.expectPUT(url).respond [{id: 1, x: 2, a: 'd'}]
        $httpBackend.flush()

        expect(list.map['1-2'].a).toBe 'd'

      it 'With composite id + NO bulkSave', ->
        list = new RestList
          endpoint: {url}
          record:   {idProperty: ['id', 'x'], endpoint: url: id_url}

        list.push {id: 1, x: 2, a: 'a'}, {id: 1, x: 3, a: 'b'}

        list.map['1-2'].a = 'c'
        list.restSave list.map['1-2']

        response = {id: 1, x: 2, a: 'd'}
        $httpBackend.expectPUT(id_url.replace '<id>', '1').respond response
        $httpBackend.flush()

        expect(list.map['1-2'].a).toBe 'd'

      it 'With bulkSave', ->
        list = new RestList endpoint: {bulkSave: 'POST'}
        list.push {id: 1, x: 'a'}
        list[0].x = 'b'
        expect(-> list.restSave list[0]).toThrow() # options.endpoint.url req'd

        list = new RestList endpoint: {url: 1, bulkSave: 'POST'}
        list.push {id: 1, x: 'a'}
        # options.endpoint.url to be string
        expect(-> list.restSave list[0]).toThrow()

        list = new RestList endpoint: {url, bulkSave: 'POST'}
        list.push {id: 1, x: 'a'}, {id: null, x: 'b'}, {id: 3, x: 'c'}
        list[0].x = 'x'
        list[1].x = 'x'

        $httpBackend.expectPOST(url).respond [{id: 1, x: 'x'},
                                              {id: 2, x: 'y', ext: 1}]

        err = record_list = raw = null
        list.restSave list[0], list[1], (_err, _record_list, _raw...) ->
          err = _err
          record_list = _record_list
          raw = _raw

        $httpBackend.flush()

        expect(record_list[0]).toBe list[0]
        expect(record_list[1]).toBe list[1]
        expect(raw.length).toBe 1
        expect(raw[0].data[0].id).toBe 1
        expect(raw[0].data[1].id).toBe 2
        expect(raw[0].config.method).toBe 'POST'

        expect(list.length).toBe 3
        expect(list.map[2].ext).toBe 1
        expect(list.map[1].x).toBe 'x'
        expect(list.map[2].x).toBe 'y'
        expect(list.map[1]._changes).toBe 0
        expect(list.map[2]._changes).toBe 0

        list.options.endpoint.bulkSave = true # should be PUT not POST
        list[0].x = 'a'
        list[1].x = 'a'

        $httpBackend.expectPUT(url).respond [{id: 2, x: 'a'}, {id: 1, x: 'a'}]

        err = record_list = raw = null
        list.restSave list[1], list[0], (_err, _record_list, _raw...) ->
          err = _err
          record_list = _record_list
          raw = _raw

        $httpBackend.flush()

        expect(list.length).toBe 3
        expect(list.map[2].ext).toBeUndefined()
        expect(list.map[1].x).toBe 'a'
        expect(list.map[2].x).toBe 'a'
        expect(list.map[1]._changes).toBe 0
        expect(list.map[2]._changes).toBe 0
        expect(list.map[3]._changes).toBe 0

      it 'Save error', ->
        list = new RestList
          endpoint: {url}
          record: endpoint: url: id_url

        list.push new EditableRecord {id: 1, a: 2}

        list.map[1].a = 3
        expect(list.map[1]._changes).toBe 1

        response = {error: 1}

        $httpBackend.expectPUT(id_url.replace '<id>', '1').respond 500, response

        cb_response = promise_response = null

        promise = list.restSave 1, (err, changed_records, raw_response) ->
          cb_response = [err, raw_response.data]

        promise.then (->), (response) ->
          promise_response = ['error', response.data]

        $httpBackend.flush()

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

        $httpBackend.expectPUT(url).respond 500, response

        cb_response = promise_response = null

        promise = list.restSave 1, (err, changed_records, raw_response) ->
          cb_response = [err, raw_response.data]

        promise.then (->), (response) ->
          promise_response = ['error', response.data]

        $httpBackend.flush()

        expect(list.length).toBe 1
        expect(list.map[1].a).toBe 3
        expect(list.map[1]._changes).toBe 1
        expect(list.map[1]._changedKeys.a).toBe true
        expect(cb_response[0] instanceof Error).toBe true
        expect(cb_response[1]).toEqual response
        expect(promise_response[0]).toBe 'error'
        expect(promise_response[1]).toEqual response

    describe 'Method .restDelete()', ->

      it 'Basic scenarios', ->
        list = new RestList
          endpoint: {url}
          record: endpoint: url: id_url

        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'}
        list[0].x = 'x'

        expect(-> list.restDelete()).toThrow() # no record passed in

        $httpBackend.expectDELETE(id_url.replace '<id>', '1').respond {a: 1}
        $httpBackend.expectDELETE(id_url.replace '<id>', '2').respond {b: 1}

        responses = null

        spyable = {callback: ->}
        spyOn spyable, 'callback'

        promise = list.restDelete list.map[1], list.map[2], spyable.callback
        promise.then (_responses) -> # success path
          responses = _responses

        $httpBackend.flush()

        expect(list.length).toBe 1
        expect(responses.length).toBe 2
        expect(responses[0].data).toEqual {a: 1}
        expect(responses[0].config.url).toBe id_url.replace '<id>', '1'
        expect(responses[1].data).toEqual {b: 1}
        expect(responses[1].config.url).toBe id_url.replace '<id>', '2'
        expect(promise.success).toBeUndefined() # chained promises don't have
                                                # HttpPromise specific stuff
        expect(spyable.callback).toHaveBeenCalled()

      it 'With composite id + bulkDelete', ->
        list = new RestList
          endpoint: {url, bulkDelete: true}
          record:   idProperty: ['id', 'x']

        list.push {id: 1, x: 2, a: 'a'}, {id: 1, x: 3, a: 'b'}

        list.restDelete list.map['1-2']

        $httpBackend.expectDELETE(url).respond {yo: 1}
        $httpBackend.flush()

        expect(list.map['1-2']).toBeUndefined()
        expect(list.length).toBe 1

      it 'With bulkDelete', ->
        list = new RestList endpoint: {url, bulkDelete: true}

        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'}
        list[0].x = 'x'

        $httpBackend.expectDELETE(url).respond {x: 'ee'}

        spyable = {callback: ->}
        spyOn spyable, 'callback'

        list.restDelete list[2], list[1], spyable.callback

        $httpBackend.flush()

        expect(list.length).toBe 1
        expect(list.map[2]).toBeUndefined()
        expect(list.map[3]).toBeUndefined()
        expect(list.map[1].x).toBe 'x'
        expect(list.map[1]._changes).toBe 1
        expect(spyable.callback).toHaveBeenCalled()

      it 'With no callback - bulk', ->
        list = new RestList endpoint: {url, bulkDelete: 1}
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}
        expect(list[0]._id).toBe 1
        $httpBackend.expectDELETE(url).respond {yo: 1}
        list.restDelete list[0]
        $httpBackend.flush()
        expect(list.length).toBe 1

      it 'With no callback - not bulk', ->
        list = new RestList {endpoint: {url}, record: endpoint: url: id_url}
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}
        expect(list[0]._id).toBe 1
        $httpBackend.expectDELETE(id_url.replace '<id>', '1').respond {yo: 1}
        list.restDelete list[0]
        $httpBackend.flush()
        expect(list.length).toBe 1

      it 'Refuses pseudo/new records', ->
        list = new RestList list_cfg
        list.push {id: null, a: 1}
        expect(list.pseudo[list[0]._pseudo]).toBe list[0]
        expect(-> list.restDelete list[0]).toThrow()

    it 'Method .restLoad() error', ->
      list = new RestList list_cfg

      response = {error: 1}

      $httpBackend.expectGET(url).respond 500, response

      cb_response = promise_response = null

      promise = list.restLoad (err, changed_records, raw_response) ->
        cb_response = [err, raw_response.data]

      promise.then (->), (response) ->
        promise_response = ['error', response.data]

      $httpBackend.flush()

      expect(cb_response[0] instanceof Error).toBe true
      expect(cb_response[1]).toEqual response
      expect(promise_response[0]).toBe 'error'
      expect(promise_response[1]).toEqual response
