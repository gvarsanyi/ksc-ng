
describe 'app.service', ->

  describe 'util', ->

    EditableRecord = Record = util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        EditableRecord = $injector.get 'ksc.EditableRecord'
        Record         = $injector.get 'ksc.Record'
        util           = $injector.get 'ksc.util'


    describe 'Method .identical()', ->

      it 'Comparing equal primitives', ->
        expect(util.identical {}.x, {}.y).toBe true # undefined
        expect(util.identical 1, 1).toBe true
        expect(util.identical 0, 0).toBe true
        expect(util.identical '', '').toBe true
        expect(util.identical 'str', 'str').toBe true
        expect(util.identical true, true).toBe true
        expect(util.identical false, false).toBe true
        expect(util.identical null, null).toBe true

      it 'Comparing equal objects', ->
        expect(util.identical {}, {}).toBe true
        expect(util.identical {a: 1}, {a: 1}).toBe true
        expect(util.identical {a: null, b: {c: {}, d: ''}},
                               {a: null, b: {c: {}, d: ''}}).toBe true
        expect(util.identical new Record({a: 1}),
                               new EditableRecord {a: 1}).toBe true
        expect(util.identical new Record({a: 1}),
                               new Record {a: 1}).toBe true

        r1 = new Record {a: 1, b: {c: 2}}
        r2 = new EditableRecord {a: 1, b: {c: 1}}
        r2.b.c = 2
        expect(util.identical r1, r2).toBe true

      it 'Comparing non-equal values', ->
        expect(util.identical undefined, null).toBe false
        expect(util.identical 0, null).toBe false
        expect(util.identical false, null).toBe false
        expect(util.identical {}, null).toBe false
        expect(util.identical 0, false).toBe false
        expect(util.identical 0, '').toBe false
        expect(util.identical 1, 2).toBe false
        expect(util.identical 1, 'xx').toBe false
        expect(util.identical {a: 1}, {a: 2}).toBe false
        expect(util.identical {a: 1}, {b: 1}).toBe false
        expect(util.identical {a: 1, x: undefined}, {a: 1}).toBe false
        expect(util.identical {a: 1, b: {}}, {a: 1, b: {x: 1}}).toBe false
        expect(util.identical {a: 1, b: {x: 1}}, {a: 1, b: {x: 2}}).toBe false
