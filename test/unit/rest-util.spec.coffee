
describe 'app.service', ->

  describe 'restUtil', ->

    restUtil = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        restUtil = $injector.get 'ksc.restUtil'


    it 'restUtil() should return undefined', ->
      expect(restUtil()).toBeUndefined()
