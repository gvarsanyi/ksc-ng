
describe 'app.service', ->

  describe 'restUtil', ->

    $http = $httpBackend = restUtil = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        $http        = $injector.get '$http'
        $httpBackend = $injector.get '$httpBackend'
        restUtil     = $injector.get 'ksc.restUtil'


    describe 'Method .wrapPromise()', ->

      it 'Successful request', ->
        cb_err = cb_result = promise_err = promise_result = null

        expected_result = {x: 1}

        $httpBackend.expectGET('/').respond expected_result

        promise = $http.get '/'

        promise.success (result) ->
          promise_result = result

        promise.error (result) ->
          promise_err = 1
          promise_result = result

        restUtil.wrapPromise promise, (err, result) ->
          cb_err = err
          cb_result = result

        $httpBackend.flush()

        expect(cb_result.data).toEqual expected_result
        expect(cb_err).toBe null
        expect(promise_result).toEqual expected_result
        expect(promise_err).toBe null

      it 'Request error handling', ->
        cb_err = cb_result = promise_err = promise_result = null

        expected_result = {x: 1}

        $httpBackend.expectGET('/').respond 500, expected_result

        promise = $http.get '/'

        promise.success (result) ->
          promise_result = result

        promise.error (result) ->
          promise_err = 1
          promise_result = result

        restUtil.wrapPromise promise, (err, result) ->
          cb_err = err
          cb_result = result

        $httpBackend.flush()

        expect(cb_result.data).toEqual expected_result
        expect(cb_err instanceof Error).toBe true
        expect(promise_result).toEqual expected_result
        expect(promise_err).toBe 1
