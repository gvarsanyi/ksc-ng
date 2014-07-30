
describe 'app.factory', ->

  describe 'RestUtils', ->

    $http = $httpBackend = RestUtils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        $http        = $injector.get '$http'
        $httpBackend = $injector.get '$httpBackend'
        RestUtils    = $injector.get 'ksc.RestUtils'


    it 'No instance use (no properties on instance)', ->
      obj = new RestUtils
      keys = (k for k of obj)
      expect(keys.length).toBe 0

    describe 'Method .asyncSquash()', ->

      it 'Single request', ->
        records = [{x: 1}]

        done = 0
        item_iterated = []
        results = []
        err = null

        done_cb = (_err, _results...) ->
          err = _err
          results.push _results...

        $httpBackend.expectGET('/').respond {asdf: 1}

        promise = RestUtils.asyncSquash records, done_cb, (record) ->
          item_iterated.push record
          $http.get '/' # returns promise

        expect(promise.success).not.toBeUndefined()
        expect(item_iterated.length).toBe 1
        expect(item_iterated[0]).toBe records[0]

        $httpBackend.flush()

        expect(results.length).toBe 1
        expect(results[0].data).toEqual {asdf: 1}
        expect(err).toBe null

      it 'Chained requests', ->
        records = [{x: 1}, {x: 2}, {x: 3}]

        done = 0
        item_iterated = []
        results = []
        err = null

        done_cb = (_err, _results...) ->
          err = _err
          results.push _results...

        for item in records
          $httpBackend.expectGET('/').respond {asdf: item.x}

        promise = RestUtils.asyncSquash records, done_cb, (record) ->
          item_iterated.push record
          $http.get '/' # returns promise

        # chained promise is not an HTTP promise
        expect(promise.success).toBeUndefined()

        expect(item_iterated.length).toBe 3
        expect(item_iterated[0]).toBe records[0]
        expect(item_iterated[2]).toBe records[2]

        $httpBackend.flush()

        expect(results.length).toBe 3
        expect(results[0].data).toEqual {asdf: 1}
        expect(results[2].data).toEqual {asdf: 3}
        expect(err).toBe null

      it 'Handling request error', ->
        records = [{x: 1}, {x: 2}, {x: 3}]

        done = 0
        item_iterated = []
        results = []
        err = null

        done_cb = (_err, _results...) ->
          err = _err
          results.push _results...

        $httpBackend.expectGET('/').respond {asdf: 1}
        $httpBackend.expectGET('/').respond 500, {fail: true}
        $httpBackend.expectGET('/').respond {asdf: 3}

        promise = RestUtils.asyncSquash records, done_cb, (record) ->
          item_iterated.push record
          $http.get '/' # returns promise

        # chained promise is not an HTTP promise
        expect(promise.success).toBeUndefined()

        expect(item_iterated.length).toBe 3
        expect(item_iterated[0]).toBe records[0]
        expect(item_iterated[2]).toBe records[2]

        $httpBackend.flush()

        expect(results.length).toBe 3
        expect(results[0].data).toEqual {asdf: 1}
        expect(results[1].data).toEqual {fail: true}
        expect(results[2].data).toEqual {asdf: 3}
        expect(Array.isArray err).toBe false
        expect(err instanceof Error).toBe true

      it 'Handling multiple request errors', ->
        records = [{x: 1}, {x: 2}, {x: 3}]

        done = 0
        item_iterated = []
        results = []
        err = null

        done_cb = (_err, _results...) ->
          err = _err
          results.push _results...

        $httpBackend.expectGET('/').respond {asdf: 1}
        $httpBackend.expectGET('/').respond 500, {fail: true}
        $httpBackend.expectGET('/').respond 403, {asdf: 3}

        promise = RestUtils.asyncSquash records, done_cb, (record) ->
          item_iterated.push record
          $http.get '/' # returns promise

        # chained promise is not an HTTP promise
        expect(promise.success).toBeUndefined()

        expect(item_iterated.length).toBe 3
        expect(item_iterated[0]).toBe records[0]
        expect(item_iterated[2]).toBe records[2]

        $httpBackend.flush()

        expect(results.length).toBe 3
        expect(results[0].data).toEqual {asdf: 1}
        expect(results[1].data).toEqual {fail: true}
        expect(results[2].data).toEqual {asdf: 3}
        expect(Array.isArray err).toBe true
        expect(err.length).toBe 2
