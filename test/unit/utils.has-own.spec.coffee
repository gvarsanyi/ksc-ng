
describe 'app.factory', ->

  describe 'Utils', ->

    Utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        Utils = $injector.get 'ksc.Utils'


    describe 'Method .hasOwn()', ->
      it 'enumerable does not mattter', ->
        a = {a: 1}
        b = Object.create a

        expect(Utils.hasOwn a, 'a').toBe true
        expect(b.a).toBe 1
        expect(Utils.hasOwn b, 'a').toBe false

      it 'enumerable=true', ->
        a = {a: 1, b: 2}
        Object.defineProperty a, 'b', enumerable: false

        expect(Utils.hasOwn a, 'a', true).toBe true
        expect(Utils.hasOwn a, 'b', true).toBe false

      it 'enumerable=false', ->
        a = {a: 1, b: 2}
        Object.defineProperty a, 'b', enumerable: false

        expect(Utils.hasOwn a, 'a', false).toBe false
        expect(Utils.hasOwn a, 'b', false).toBe true
