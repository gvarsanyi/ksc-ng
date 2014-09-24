
describe 'app.service', ->

  describe 'util', ->

    util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        util = $injector.get 'ksc.util'


    it 'Method .mergeIn()', ->
      a = {a: 1, b: 2}
      b = {b: 3, c: 4}
      res = util.mergeIn a, b
      expect(res).toBe a
      expect(a.a).toBe 1
      expect(a.b).toBe 3
      expect(a.c).toBe 4

      expect(-> util.mergeIn()).toThrow()
      expect(-> util.mergeIn {}).toThrow()
      expect(-> util.mergeIn false, {}).toThrow()
      expect(-> util.mergeIn {}, true).toThrow()
