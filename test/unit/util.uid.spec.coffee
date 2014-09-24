
describe 'app.service', ->

  describe 'util', ->

    util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        util = $injector.get 'ksc.util'


    it 'Method .uid()', ->
      uid = util.uid()

      expect(!!uid).toBe true
      expect(typeof uid).toBe 'number'

      uid2 = util.uid()
      expect(!!uid2).toBe true
      expect(typeof uid2).toBe 'number'
      expect(uid2).not.toBe uid

    it 'Method .uid(\'name\')', ->
      uid = util.uid 'named'

      expect(!!uid).toBe true
      expect(typeof uid).toBe 'number'

      uid2 = util.uid 'named'
      expect(!!uid2).toBe true
      expect(typeof uid2).toBe 'number'
      expect(uid2).not.toBe uid

      expect(-> util.uid true).toThrow()
