
describe 'app.factory', ->

  describe 'EditableRecord', ->

    EditableRecord = Record = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        EditableRecord = $injector.get 'ksc.EditableRecord'
        Record         = $injector.get 'ksc.Record'


    it 'Instace of Record', ->
      record = new EditableRecord {a: 1}
      expect(record instanceof Record).toBe true

    it 'Options arg must be null/undefined/Object', ->
      expect(-> new EditableRecord {a: 1}, 'fds').toThrow()

    it 'Properties ._changes, ._changedKeys and method ._revert()', ->
      example = {a: 1, b: {x: 2}, c: {x: 3, y: 4}, d: null}

      record = new EditableRecord example
      expect(record._changes).toBe 0
      expect(record._changedKeys).toEqual {}

      record.a = 2
      record._delete 'b'
      expect(record._changes).toBe 2
      expect(record._changedKeys).toEqual {a: true, b: true}

      record._revert()
      expect(record._changes).toBe 0
      expect(record._changedKeys).toEqual {}

      record.b = null
      expect(record._changes).toBe 1
      expect(record._changedKeys).toEqual {b: true}

      record.c.x = 4
      expect(record._changes).toBe 2
      expect(record._changedKeys).toEqual {b: true, c: true}

      record.c.x = 3
      expect(record._changes).toBe 1
      expect(record._changedKeys).toEqual {b: true}

      record._revert()
      record.d = {a: 3}
      expect(record._changes).toBe 1
      expect(record._changedKeys).toEqual {d: true}

      record.d = null
      expect(record._changes).toBe 0
      expect(record._changedKeys).toEqual {}

      record = new EditableRecord example
      record.c = {x: 3, y: 2, z: 1}
      expect(record._changes).toBe 1
      expect(record.c._changes).toBe 2

      record.c = {x: 3, y: 2}
      expect(record._changes).toBe 1

      expect(record.c._changes).toBe 1

      record.c = cc = {x: 3, y: 4}
      expect(record._changes).toBe 0
      expect(record.c._changes).toBe 0

      record = new EditableRecord {id: 1, a: {b: {c: {d: 1, e: 1}}}}
      record.a.b.c.d = 2
      record.a.b.c.e = 2
      expect(record._changes).toBe 1
      expect(record.a._changes).toBe 1
      expect(record.a.b._changes).toBe 1
      expect(record.a.b.c._changes).toBe 2

    describe '._getProperty()', ->

      it 'Basic scenario', ->
        record = new EditableRecord {a: 1, b: [1, 2, 3]}
        expect(record._getProperty 'a').toBe 1

      it 'Returns native array for array types', ->
        record = new EditableRecord {a: 1, b: [1, 2, 3]}
        expect(record._getProperty 'b').toEqual [1, 2, 3]
        expect(Array.isArray record._getProperty 'b').toBe true

      it 'Returns undefined for deleted keys', ->
        record = new EditableRecord {a: 1, b: [1, 2, 3]}
        record._delete 'b'
        expect(record._getProperty 'b').toBeUndefined()

      it 'Requires key', ->
        record = new EditableRecord {a: 1, b: [1, 2, 3]}
        record._delete 'b'
        expect(-> record._getProperty()).toThrow()

    describe 'Method ._delete()', ->

      it 'Basic scenarios', ->
        example = {id: 1, x: 2, y: {a: 3}, z: null}
        record = new EditableRecord example

        expect(-> record._delete()).toThrow() # no key

        record.x = 4
        record._delete 'x'
        expect(record.x).toBeUndefined()
        enumerable = Object.getOwnPropertyDescriptor(record, 'x').enumerable
        expect(enumerable).toBe false
        expect(record.hasOwnProperty 'x').toBe true

        record._delete 'x'
        expect(record.x).toBeUndefined()
        enumerable = Object.getOwnPropertyDescriptor(record, 'x').enumerable
        expect(enumerable).toBe false
        expect(record.hasOwnProperty 'x').toBe true

        record.xx = 'xx'
        record._delete 'xx'
        expect(record.xx).toBeUndefined()
        expect(record.hasOwnProperty 'xx').toBe false

        record._delete 'xx'
        expect(record.xx).toBeUndefined()
        expect(record.hasOwnProperty 'xx').toBe false

        # special properties can't be deleted
        expect(-> record._delete '_changes').toThrow()

      it 'init -> delete -> set to original -> delete -> modify', ->
        record = new EditableRecord {id: 1, x: 2}
        expect(record.x).toBe 2
        expect(record._changes).toBe 0
        expect(record._changedKeys).toEqual {}
        expect(record._deletedKeys).toEqual {}

        record._delete 'x'
        expect(record.x).toBeUndefined()
        expect(record._changes).toBe 1
        expect(record._changedKeys).toEqual {x: true}
        expect(record._deletedKeys).toEqual {x: true}

        record._setProperty 'x', 2
        expect(record.x).toBe 2
        expect(record._changes).toBe 0
        expect(record._changedKeys).toEqual {}
        expect(record._deletedKeys).toEqual {}

        record._delete 'x'

        record._setProperty 'x', 3
        expect(record.x).toBe 3
        expect(record._changes).toBe 1
        expect(record._changedKeys).toEqual {x: true}
        expect(record._deletedKeys).toEqual {}

      it 'Forbidden when contracted', ->
        record = new EditableRecord {id: 1}, contract: id: type: 'number'
        record.id = 2
        expect(-> record._delete 'id').toThrow()

      describe 'Arrays', ->
        arr = r = null
        beforeEach ->
          arr = [1, 2]
          r = new EditableRecord {id: 1, a: arr}

        it 'Construction', ->
          expect(Array.isArray r.a).toBe true
          expect(r.a).not.toBe arr
          expect(r.a.length).toBe 2
          expect(r.a[0]).toBe 1
          expect(r.a._record instanceof EditableRecord).toBe true

        it '.push()', ->
          r.a.push 3
          expect(r.a[2]).toBe 3
          expect(r.a.length).toBe 3

        describe 'Replacing cases', ->

          it 'Array -> Array (keeps reference)', ->
            pre_r_a = r.a
            r.a = [11, 12, 13, 14]
            expect(r.a).toBe pre_r_a
            expect(r.a).toEqual [11, 12, 13, 14]
            expect(r._changedKeys.a).toBe true
            expect(r._changes).toBe 1
            expect(r.a._changedKeys[0]).toBe true
            expect(r.a._changedKeys[1]).toBe true
            expect(r.a._changedKeys[2]).toBe true
            expect(r.a._changedKeys[3]).toBe true
            expect(r.a._changes).toBe 4

          it 'Array -> equally long Array', ->
            pre_r_a = r.a
            r.a = [11, 12]
            expect(r.a).toBe pre_r_a
            expect(r.a).toEqual [11, 12]

          it 'Array -> shorter Array', ->
            pre_r_a = r.a
            r.a = [11]
            expect(r.a).toBe pre_r_a
            expect(r.a).toEqual [11]

          it 'Array -> empty Array', ->
            pre_r_a = r.a
            r.a = []
            expect(r.a).toBe pre_r_a
            expect(r.a).toEqual []

          it 'Array -> Object (keeps reference @ ._record)', ->
            pre_r_a = r.a._record
            r.a = {a: 1, b: 2, 0: 99}
            expect(r.a).toEqual new EditableRecord {a: 1, b: 2, 0: 99}
            expect(r.a).toBe pre_r_a
            expect(r._changedKeys.a).toBe true
            expect(r._changes).toBe 1
            expect(r.a._changedKeys.a).toBe true
            expect(r.a._changedKeys.b).toBe true
            expect(r.a._changedKeys[0]).toBe true
            expect(r.a._changedKeys[1]).toBe true
            expect(r.a._changes).toBe 4

          it 'Object -> Array (keeps reference @ ._record)', ->
            r = new EditableRecord {id: 1, a: {a: 'z', 1: 999}}
            pre_r_a = r.a
            r.a = [1, 2, 3]
            expect(r.a).toEqual [1, 2, 3]
            expect(r.a._record).toBe pre_r_a
            expect(r._changedKeys.a).toBe true
            expect(r._changes).toBe 1
            expect(r.a._changedKeys.a).toBe true
            expect(r.a._changedKeys[0]).toBe true
            expect(r.a._changedKeys[1]).toBe true
            expect(r.a._changedKeys[2]).toBe true
            expect(r.a._changes).toBe 4

          it 'Arrray -> null', ->
            pre_r_a = r.a
            r.a = null
            expect(r.a).toBe null
            expect(r._saved.a._array).toBe pre_r_a
            expect(r._changedKeys.a).toBe true
            expect(r._changes).toBe 1

          it 'null -> Array', ->
            r = new EditableRecord {id: 1, a: null}
            r.a = [11, 12, 13]
            expect(r.a).toEqual [11, 12, 13]
            expect(r._saved.a).toBe null
            expect(r._changedKeys.a).toBe true
            expect(r._changes).toBe 1

      it 'Throws error if key is invalid', ->
        record = new EditableRecord {id: 1, a: 1},
          contract:
            id: {type: 'number'}
            a:  {type: 'number'}

        expect(-> record._delete()).toThrow()
        expect(-> record._delete null).toThrow()
        expect(-> record._delete {}).toThrow()
        expect(-> record._delete true).toThrow()
        expect(-> record._delete false).toThrow()
        expect(-> record._delete 'a', true).toThrow()

      it 'Can not delete idProperty key', ->
        record = new EditableRecord {id: 1}, {idProperty: 'id'}
        expect(-> record._delete 'id').toThrow()

        record = new EditableRecord {id: 1, x: 2}, {idProperty: ['id', 'x']}
        expect(-> record._delete 'x').toThrow()

    it 'Id changes', ->
      example = {id: 1, x: 2}

      record = new EditableRecord example
      record.id = 2
      expect(record._id).toBe 2

      # report to parent
      faux_parent = {_recordChange: ->}
      spyOn faux_parent, '_recordChange'
      record = new EditableRecord example, null, faux_parent
      record.id = 2
      info = {node: record, action: 'set', key: 'id'}
      expect(faux_parent._recordChange).toHaveBeenCalledWith record, info, 1
      expect(record._id).toBe 2

      # don't report if id has not changed
      faux_parent = {_recordChange: ->}
      spyOn faux_parent, '_recordChange'
      record = new EditableRecord example, null, faux_parent
      record.x = 3
      info = {node: record, action: 'set', key: 'x'}
      expect(faux_parent._recordChange).toHaveBeenCalledWith record, info, 1

      # should not fail if parent has no ._recordChange() method
      record = new EditableRecord example, null, {}
      expect(-> record.id = 3).not.toThrow()
      expect(record._id).toBe 3

    it 'Composite id changes', ->
      record = new EditableRecord {id: 1, x: 2}, {idProperty: ['id', 'x']}

      expect(-> record.x = false).toThrow() # string, number or null is required

      record.x = 3
      expect(record._id).toBe '1-3'
      expect(record._primaryId).toBe 1

      record.id = null
      expect(record._id).toBe null
      expect(record._primaryId).toBe null

    it 'Can create empty container', ->
      record = null
      expect(-> record = new EditableRecord).not.toThrow()

      found_keys = 0
      for k, v of record
        found_keys += 1
      expect(found_keys).toBe 0

    it 'Will not replace if not needed', ->
      record = new EditableRecord {a: 1}
      expect(record._replace {a: 1}).toBe false
      expect(record._replace {a: 1, b: 2}).toBe true

      # with contract
      record = new EditableRecord null, {contract: {a: default: 1}}
      expect(record._replace {}).toBe false
      expect(record._replace {a: 1}).toBe false
      expect(record._replace {a: 2}).toBe true

    it 'Does not take functions', ->
      record = new EditableRecord {id: 1, x: 3}
      expect(-> record.x = ->).toThrow()

    it 'Contract record', ->
      contract =
        id: {type: 'number'}
        a: {type: 'string', nullable: true}
        b: {type: 'string'}
        c: {type: 'boolean', nullable: true}
        d: {contract: {a: {type: 'number', nullable: true}}, nullable: true}
        e: {type: 'object', contract: {
          a: {type: 'number', default: 1},
          b: {nullable: false, contract:
            x: {type: 'number', nullable: true}}}}

      record = new EditableRecord {id: 1}, {contract}
      expect(-> record.id = 'wsd').toThrow()
      expect(-> record.a = {}).toThrow()
      expect(-> record.b = null).toThrow()
      expect(-> record.c = 1).toThrow()
      expect(-> record.d = {}).not.toThrow()
      expect(record.d.a).toBe null
      expect(-> record.d = {xxx: 1}).toThrow()
      expect(record.d.xxx).toBeUndefined()
      expect(-> record.d = null).not.toThrow()
      expect(record.d).toBe null
      expect(-> record.e = null).toThrow()
