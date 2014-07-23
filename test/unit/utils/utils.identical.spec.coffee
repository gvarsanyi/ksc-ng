
describe 'app.factory', ->

  describe 'Utils', ->

    EditableRecord = Record = Utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        EditableRecord = $injector.get 'ksc.EditableRecord'
        Record         = $injector.get 'ksc.Record'
        Utils          = $injector.get 'ksc.Utils'


    describe 'Method .identical()', ->

      it 'Comparing equal primitives', ->
        expect(Utils.identical {}.x, {}.y).toBe true # undefined
        expect(Utils.identical 1, 1).toBe true
        expect(Utils.identical 0, 0).toBe true
        expect(Utils.identical '', '').toBe true
        expect(Utils.identical 'str', 'str').toBe true
        expect(Utils.identical true, true).toBe true
        expect(Utils.identical false, false).toBe true
        expect(Utils.identical null, null).toBe true

      it 'Comparing equal objects', ->
        expect(Utils.identical {}, {}).toBe true
        expect(Utils.identical {a: 1}, {a: 1}).toBe true
        expect(Utils.identical {a: null, b: {c: {}, d: ''}},
                               {a: null, b: {c: {}, d: ''}}).toBe true
        expect(Utils.identical new Record({a: 1}),
                               new EditableRecord {a: 1}).toBe true
        expect(Utils.identical new Record({a: 1}),
                               new Record {a: 1}).toBe true

        r1 = new Record {a: 1, b: {c: 2}}
        r2 = new EditableRecord {a: 1, b: {c: 1}}
        r2.b.c = 2
        expect(Utils.identical r1, r2).toBe true

      it 'Comparing non-equal values', ->
        expect(Utils.identical {}.undef, null).toBe false
        expect(Utils.identical 0, null).toBe false
        expect(Utils.identical false, null).toBe false
        expect(Utils.identical {}, null).toBe false
        expect(Utils.identical 0, false).toBe false
        expect(Utils.identical 0, '').toBe false
        expect(Utils.identical 1, 2).toBe false
        expect(Utils.identical 1, 'xx').toBe false
        expect(Utils.identical {a: 1}, {a: 2}).toBe false
        expect(Utils.identical {a: 1}, {b: 1}).toBe false
        expect(Utils.identical {a: 1, x: {}.undef}, {a: 1}).toBe false
        expect(Utils.identical {a: 1, b: {}}, {a: 1, b: {x: 1}}).toBe false
        expect(Utils.identical {a: 1, b: {x: 1}}, {a: 1, b: {x: 2}}).toBe false
