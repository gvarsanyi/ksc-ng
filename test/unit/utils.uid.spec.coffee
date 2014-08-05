
describe 'app.service', ->

  describe 'utils', ->

    utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        utils = $injector.get 'ksc.utils'


    it 'Method .uid()', ->
      uid = utils.uid()

      expect(!!uid).toBe true
      expect(typeof uid).toBe 'number'

      uid2 = utils.uid()
      expect(!!uid2).toBe true
      expect(typeof uid2).toBe 'number'
      expect(uid2).not.toBe uid

    it 'Method .uid(\'name\')', ->
      uid = utils.uid 'named'

      expect(!!uid).toBe true
      expect(typeof uid).toBe 'number'

      uid2 = utils.uid 'named'
      expect(!!uid2).toBe true
      expect(typeof uid2).toBe 'number'
      expect(uid2).not.toBe uid
