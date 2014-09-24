
describe 'app.service', ->

  describe 'util', ->

    util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        util = $injector.get 'ksc.util'


    describe 'Method .hasProperty()', ->

      it 'Check inherited object', ->
        a = {a: 1}
        b = Object.create a

        expect(util.hasProperty a, 'a').toBe true
        expect(util.hasProperty b, 'a').toBe true
        expect(util.hasProperty b, 'b').toBe false

      it 'Check not inheried object (~= hasOwn)', ->
        a = {a: 1}
        expect(util.hasProperty a, 'a').toBe true

      it 'Returns false when not parsable as object', ->
        expect(util.hasProperty false, 'a').toBe false
        expect(util.hasProperty null, 'a').toBe false
