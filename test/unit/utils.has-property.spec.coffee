
describe 'app.service', ->

  describe 'utils', ->

    utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        utils = $injector.get 'ksc.utils'


    describe 'Method .hasProperty()', ->

      it 'Check inherited object', ->
        a = {a: 1}
        b = Object.create a

        expect(utils.hasProperty a, 'a').toBe true
        expect(utils.hasProperty b, 'a').toBe true
        expect(utils.hasProperty b, 'b').toBe false

      it 'Check not inheried object (~= hasOwn)', ->
        a = {a: 1}
        expect(utils.hasProperty a, 'a').toBe true

      it 'Returns false when not parsable as object', ->
        expect(utils.hasProperty false, 'a').toBe false
        expect(utils.hasProperty null, 'a').toBe false
