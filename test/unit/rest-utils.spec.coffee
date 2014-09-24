
describe 'app.service', ->

  describe 'restUtils', ->

    restUtils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        restUtils = $injector.get 'ksc.restUtils'


    it 'restUtils() should return undefined', ->
      expect(restUtils()).toBeUndefined()
