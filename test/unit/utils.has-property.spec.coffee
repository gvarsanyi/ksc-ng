
describe 'app.factory', ->

  describe 'Utils', ->

    Utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        Utils = $injector.get 'ksc.Utils'


    describe 'Method .hasProperty()', ->

      it 'Check inherited object', ->
        a = {a: 1}
        b = Object.create a

        expect(Utils.hasProperty a, 'a').toBe true
        expect(Utils.hasProperty b, 'a').toBe true
        expect(Utils.hasProperty b, 'b').toBe false

      it 'Check not inheried object (~= hasOwn)', ->
        a = {a: 1}
        expect(Utils.hasProperty a, 'a').toBe true

      it 'Returns false when not parsable as object', ->
        expect(Utils.hasProperty false, 'a').toBe false
        expect(Utils.hasProperty null, 'a').toBe false
