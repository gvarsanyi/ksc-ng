
describe 'app.factory', ->

  describe 'EditableRecord', ->

    EditableRecord = Record = example = record = null

    is_getter = (obj, name) ->
      inf = Object.getOwnPropertyDescriptor obj, name
      inf.hasOwnProperty 'get'

    beforeEach ->
      module 'app'
      inject ($injector) ->
        EditableRecord = $injector.get 'ksc.EditableRecord'
        Record         = $injector.get 'ksc.Record'

        example = {id: 1, x: 2, y: {a: 3}, z: null, a: 1}
        record = new EditableRecord example
        record.x = 4
        record.y.faux = 1
        record.z = {x: 1}
        record.faux = 1
        record._delete 'a'


    describe 'Method ._clone()', ->

      describe 'To EditableRecord objects: ._clone(false)', ->

        describe 'Incluing static properties: ._clone(false, false)', ->

          it 'Edited data: ._clone(false, false, false)', ->
            record2 = record._clone()

            expect(record2.id).toBe 1
            expect(record2._changedKeys.id).toBeUndefined()
            expect(record2.x).toBe 4
            expect(record2._changedKeys.x).toBe true
            expect(record2.y.faux).toBe 1
            expect(is_getter record2.y, 'faux').toBe false
            expect(record2.z.x).toBe 1
            expect(is_getter record2.z, 'x').toBe true
            expect(record2._changedKeys.z).toBe true
            expect(record2.a).toBeUndefined()
            expect(is_getter record2, 'a').toBe true
            expect(record2.faux).toBe 1
            expect(is_getter record2, 'faux').toBe false

          it 'Saved only: ._clone(false, false, true)', ->
            record2 = record._clone false, false, true

            expect(record2.id).toBe 1
            expect(record2._changedKeys.id).toBeUndefined()
            expect(record2.x).toBe 2
            expect(record2._changedKeys.x).toBeUndefined()
            expect(record2.y.faux).toBe 1
            expect(is_getter record2.y, 'faux').toBe false
            expect(is_getter record2.y, 'a').toBe true
            expect(record2.z).toBe null
            expect(record2._changedKeys.z).toBeUndefined()
            expect(record2.a).toBe 1
            expect(is_getter record2, 'a').toBe true
            expect(record2.faux).toBe 1
            expect(is_getter record2, 'faux').toBe false

        describe 'Excluing static properties: ._clone(false, true)', ->

          it 'Edited data: ._clone(false, true, false)', ->
            record2 = record._clone false, true

            expect(record2.id).toBe 1
            expect(is_getter record2, 'id').toBe true
            expect(record2._changedKeys.id).toBeUndefined()
            expect(record2.x).toBe 4
            expect(is_getter record2, 'x').toBe true
            expect(record2._changedKeys.x).toBe true
            expect(record2.y.faux).toBeUndefined()
            expect(record2.y.a).toBe 3
            expect(is_getter record2.y, 'a').toBe true
            expect(record2.z.x).toBe 1
            expect(is_getter record2, 'z').toBe true
            expect(is_getter record2.z, 'x').toBe true
            expect(record2._changedKeys.z).toBe true
            expect(record2.a).toBeUndefined()
            expect(record2.faux).toBeUndefined()

          it 'Saved only: ._clone(false, true, true)', ->
            record2 = record._clone false, true, true

            expect(record2.id).toBe 1
            expect(record2._changedKeys.id).toBeUndefined()
            expect(record2.x).toBe 2
            expect(record2._changedKeys.x).toBeUndefined()
            expect(record2.y.faux).toBeUndefined()
            expect(is_getter record2, 'y').toBe true
            expect(record2.y.a).toBe 3
            expect(is_getter record2.y, 'a').toBe true
            expect(record2.z).toBe null
            expect(is_getter record2, 'z').toBe true
            expect(record2._changedKeys.z).toBeUndefined()
            expect(record2.a).toBe 1
            expect(record2.faux).toBeUndefined()

      describe 'To plain objects: ._clone(true)', ->

        describe 'Incluing static properties: ._clone(true, false)', ->

          it 'Edited data: ._clone(true, false, false)', ->
            obj = record._clone true

            expected = {id: 1, x: 4, y: {a: 3, faux: 1}, z: {x: 1}, faux: 1}
            expect(obj).toEqual expected

          it 'Saved only: ._clone(true, false, true)', ->
            obj = record._clone true, false, true

            expected = {id: 1, x: 2, y: {a: 3, faux: 1}, z: null, a: 1, faux: 1}
            expect(obj).toEqual expected

        describe 'Excluing static properties: ._clone(true, true)', ->

          it 'Edited data: ._clone(true, true, false)', ->
            obj = record._clone true, true

            expected = {id: 1, x: 4, y: {a: 3}, z: {x: 1}}
            expect(obj).toEqual expected

          it 'Saved only: ._clone(true, true, true)', ->
            obj = record._clone true, true, true

            expected = {id: 1, x: 2, y: {a: 3}, z: null, a: 1}
            expect(obj).toEqual expected

      it 'array cloning', ->
        b = {id: 'x', a: null, b: {x: 1}, c: [1, 2]}
        obj = {id: 1, a: null, b, c: [3, 4], d: [5], e: []}
        record = new EditableRecord obj
        record.a = [1]
        record.b.a = [8, 9, 10]
        record.b.b = [8, 9, 10]
        record.b.c = [8, 9, 10]
        record.b.s = [6, 7]
        record.c = [9]
        record._delete 'd'
        record.e = null
        record.s = [9, 99]

        clone = record._clone()
        expect(record.a).toEqual [1]
        expect(record.b.a).toEqual [8, 9, 10]
        expect(record.b.b).toEqual [8, 9, 10]
        expect(record.b.c).toEqual [8, 9, 10]
        expect(record.b.s).toEqual [6, 7]
        expect(record.c).toEqual [9]
        expect(record.d).toBeUndefined()
        expect(record.e).toEqual null
        expect(record.s).toEqual [9, 99]
        expect(is_getter record, 'a').toBe true
        expect(is_getter record.b, 'a').toBe true
        expect(is_getter record.b, 'b').toBe true
        expect(is_getter record.b, 'c').toBe true
        expect(is_getter record.b, 's').toBe false
        expect(is_getter record, 'c').toBe true
        expect(is_getter record, 'd').toBe true
        expect(is_getter record, 's').toBe false

      it 'to Record object, edited (contracted)', ->
        example = {id: 1, x: 2, y: {a: 3}, z: null, a: 1}

        contract =
          id: {type: 'number'}
          x: {type: 'number', nullable: true}
          y: {contract: {a: {type: 'number'}}, nullable: true}
          z: {contract: {x: {type: 'number'}}, nullable: true}
          a: {type: 'number'}

        record = new EditableRecord example, {contract}

        record.x = 4
        record.z = {x: 1}

        record2 = record._clone()
        expect(record._entity()).toEqual record2._entity()
        expect(record).not.toBe record2
