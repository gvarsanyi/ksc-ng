
describe 'app.service', ->

  describe 'restUtils', ->

    $http = $httpBackend = restUtils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        $http        = $injector.get '$http'
        $httpBackend = $injector.get '$httpBackend'
        restUtils    = $injector.get 'ksc.restUtils'


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

        iteration = (record) ->
          item_iterated.push record
          $http.get '/' # returns promise

        promise = restUtils.asyncSquash records, iteration, done_cb

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

        iteration = (record) ->
          item_iterated.push record
          $http.get '/' # returns promise

        promise = restUtils.asyncSquash records, iteration, done_cb

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

        iteration = (record) ->
          item_iterated.push record
          $http.get '/' # returns promise

        promise = restUtils.asyncSquash records, iteration, done_cb

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

        iteration = (record) ->
          item_iterated.push record
          $http.get '/' # returns promise

        promise = restUtils.asyncSquash records, iteration, done_cb

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
