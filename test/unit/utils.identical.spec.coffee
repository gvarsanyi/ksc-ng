
describe 'app.service', ->

  describe 'utils', ->

    EditableRecord = Record = utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        EditableRecord = $injector.get 'ksc.EditableRecord'
        Record         = $injector.get 'ksc.Record'
        utils          = $injector.get 'ksc.utils'


    describe 'Method .identical()', ->

      it 'Comparing equal primitives', ->
        expect(utils.identical {}.x, {}.y).toBe true # undefined
        expect(utils.identical 1, 1).toBe true
        expect(utils.identical 0, 0).toBe true
        expect(utils.identical '', '').toBe true
        expect(utils.identical 'str', 'str').toBe true
        expect(utils.identical true, true).toBe true
        expect(utils.identical false, false).toBe true
        expect(utils.identical null, null).toBe true

      it 'Comparing equal objects', ->
        expect(utils.identical {}, {}).toBe true
        expect(utils.identical {a: 1}, {a: 1}).toBe true
        expect(utils.identical {a: null, b: {c: {}, d: ''}},
                               {a: null, b: {c: {}, d: ''}}).toBe true
        expect(utils.identical new Record({a: 1}),
                               new EditableRecord {a: 1}).toBe true
        expect(utils.identical new Record({a: 1}),
                               new Record {a: 1}).toBe true

        r1 = new Record {a: 1, b: {c: 2}}
        r2 = new EditableRecord {a: 1, b: {c: 1}}
        r2.b.c = 2
        expect(utils.identical r1, r2).toBe true

      it 'Comparing non-equal values', ->
        expect(utils.identical undefined, null).toBe false
        expect(utils.identical 0, null).toBe false
        expect(utils.identical false, null).toBe false
        expect(utils.identical {}, null).toBe false
        expect(utils.identical 0, false).toBe false
        expect(utils.identical 0, '').toBe false
        expect(utils.identical 1, 2).toBe false
        expect(utils.identical 1, 'xx').toBe false
        expect(utils.identical {a: 1}, {a: 2}).toBe false
        expect(utils.identical {a: 1}, {b: 1}).toBe false
        expect(utils.identical {a: 1, x: undefined}, {a: 1}).toBe false
        expect(utils.identical {a: 1, b: {}}, {a: 1, b: {x: 1}}).toBe false
        expect(utils.identical {a: 1, b: {x: 1}}, {a: 1, b: {x: 2}}).toBe false
