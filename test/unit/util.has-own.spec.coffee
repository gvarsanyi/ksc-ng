
describe 'app.service', ->

  describe 'util', ->

    util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        util = $injector.get 'ksc.util'


    describe 'Method .hasOwn()', ->
      it 'enumerable does not mattter', ->
        a = {a: 1}
        b = Object.create a

        expect(util.hasOwn a, 'a').toBe true
        expect(b.a).toBe 1
        expect(util.hasOwn b, 'a').toBe false

      it 'enumerable=true', ->
        a = {a: 1, b: 2}
        Object.defineProperty a, 'b', enumerable: false

        expect(util.hasOwn a, 'a', true).toBe true
        expect(util.hasOwn a, 'b', true).toBe false

      it 'enumerable=false', ->
        a = {a: 1, b: 2}
        Object.defineProperty a, 'b', enumerable: false

        expect(util.hasOwn a, 'a', false).toBe false
        expect(util.hasOwn a, 'b', false).toBe true
