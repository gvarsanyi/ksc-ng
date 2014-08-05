
describe 'app.service', ->

  describe 'utils', ->

    utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        utils = $injector.get 'ksc.utils'


    it 'Method .mergeIn()', ->
      a = {a: 1, b: 2}
      b = {b: 3, c: 4}
      res = utils.mergeIn a, b
      expect(res).toBe a
      expect(a.a).toBe 1
      expect(a.b).toBe 3
      expect(a.c).toBe 4

      expect(-> utils.mergeIn()).toThrow()
      expect(-> utils.mergeIn {}).toThrow()
      expect(-> utils.mergeIn {}, true).toThrow()
