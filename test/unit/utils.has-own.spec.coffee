
describe 'app.service', ->

  describe 'utils', ->

    utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        utils = $injector.get 'ksc.utils'


    describe 'Method .hasOwn()', ->
      it 'enumerable does not mattter', ->
        a = {a: 1}
        b = Object.create a

        expect(utils.hasOwn a, 'a').toBe true
        expect(b.a).toBe 1
        expect(utils.hasOwn b, 'a').toBe false

      it 'enumerable=true', ->
        a = {a: 1, b: 2}
        Object.defineProperty a, 'b', enumerable: false

        expect(utils.hasOwn a, 'a', true).toBe true
        expect(utils.hasOwn a, 'b', true).toBe false

      it 'enumerable=false', ->
        a = {a: 1, b: 2}
        Object.defineProperty a, 'b', enumerable: false

        expect(utils.hasOwn a, 'a', false).toBe false
        expect(utils.hasOwn a, 'b', false).toBe true
