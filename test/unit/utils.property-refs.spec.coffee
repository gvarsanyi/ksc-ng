
describe 'app.service', ->

  describe 'utils', ->

    utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        utils = $injector.get 'ksc.utils'


    describe 'Method .propertyRefs()', ->

      it 'Inherited object', ->
        a = {a: 1, b: 1}
        b = Object.create a
        b.b = 2
        c = Object.create b
        c.c = 3

        res = utils.propertyRefs c

        expect(Array.isArray res.a).toBe true
        expect(res.a.length).toBe 1
        expect(res.a[0]).toBe a
        expect(res.b.length).toBe 2
        expect(res.b[0]).toBe b
        expect(res.b[1]).toBe a
        expect(res.c.length).toBe 1
        expect(res.c[0]).toBe c

      it 'Error case for non-object provided', ->
        expect(-> utils.propertyRefs false).toThrow()
