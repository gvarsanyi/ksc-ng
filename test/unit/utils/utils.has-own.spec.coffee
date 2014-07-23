
describe 'app.factory', ->

  describe 'Utils', ->

    Utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        Utils = $injector.get 'ksc.Utils'


    it 'Method .hasOwn()', ->
      a = {a: 1}
      b = Object.create a
      b.b = 2

      expect(Utils.hasOwn a, 'a').toBe true
      expect(b.a).toBe 1
      expect(Utils.hasOwn b, 'a').toBe false
