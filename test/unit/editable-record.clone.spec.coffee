
describe 'app.factory', ->

  describe 'EditableRecord', ->

    EditableRecord = Record = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        EditableRecord = $injector.get 'ksc.EditableRecord'
        Record         = $injector.get 'ksc.Record'


    describe 'Method ._clone()', ->
      it 'to plain object, saved', ->
        example = {id: 1, x: 2, y: {a: 3}, z: null, a: 1}
        record = new EditableRecord example

        record.x = 4
        record.y.faux = 1
        record.z = {x: 1}
        record.faux = 1
        record._delete 'a'

        expected = {id: 1, x: 2, y: {a: 3}, z: null, a: 1}

        obj = record._clone true, true
        expect(obj).toEqual expected

      it 'to plain object, edited', ->
        example = {id: 1, x: 2, y: {a: 3}, z: null, a: 1}
        record = new EditableRecord example

        record.x = 4
        record.y.faux = 1
        record.z = {x: 1}
        record.faux = 1
        record._delete 'a'

        expected = {id: 1, x: 4, y: {a: 3, faux: 1}, z: {x: 1}, faux: 1}

        obj = record._clone true
        expect(obj).toEqual expected

      it 'to Record object, saved', ->
        example = {id: 1, x: 2, y: {a: 3}, z: null, a: 1}
        record = new EditableRecord example

        record.x = 4
        record.y.faux = 1
        record.z = {x: 1}
        record.faux = 1

        record2 = record._clone false, true
        record._revert()
        expect(record).toEqual record2
        expect(record).not.toBe record2

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

      it 'to Record object, edited (not contracted, with deleted data)', ->
        example = {id: 1, x: 2, y: {a: 3}, z: null, a: 1}
        record = new EditableRecord example

        record.x = 4
        record.y.faux = 1
        record.z = {x: 1}
        record.faux = 1
        record._delete 'a'

        record2 = record._clone()
        expect(record).toEqual record2
        expect(record).not.toBe record2
