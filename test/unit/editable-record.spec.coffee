
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
      expect(record._changes).toBe 1
      expect(record._changedKeys).toEqual {a: true}

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
      expect(record.c._changes).toBe 1

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

    it 'Method ._delete()', ->
      example = {id: 1, x: 2, y: {a: 3}, z: null}
      record = new EditableRecord example

      expect(-> record._delete()).toThrow() # no key

      record._delete 'x'
      expect(record.x).toBeUndefined()
      expect(Object.getOwnPropertyDescriptor(record, 'x').enumerable).toBe false
      expect(record.hasOwnProperty 'x').toBe true

      record._delete 'x'
      expect(record.x).toBeUndefined()
      expect(Object.getOwnPropertyDescriptor(record, 'x').enumerable).toBe false
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

    it 'Method ._clone()', ->
      example = {id: 1, x: 2, y: {a: 3}, z: null}
      record = new EditableRecord example

      record.x = 4
      record.y.faux = 1
      record.z = {x: 1}
      record.faux = 1

      expected_saved  = {id: 1, x: 2, y: {a: 3, faux: 1}, z: null, faux: 1}
      expected_edited = {id: 1, x: 4, y: {a: 3, faux: 1}, z: {x: 1}, faux: 1}

      # plain object, saved
      obj = record._clone true, true
      expect(obj).toEqual expected_saved

      # plain object, edited
      obj = record._clone true
      expect(obj).toEqual expected_edited

      # object cloning
      record2 = record._clone()
      expect(record).toEqual record2
      expect(record).not.toBe record2

    it 'Id changes', ->
      example = {id: 1, x: 2}

      record = new EditableRecord example
      record.id = 2
      expect(record._id).toBe 2

      # report to parent
      faux_parent = {recordIdChanged: ->}
      spyOn faux_parent, 'recordIdChanged'
      record = new EditableRecord example, null, faux_parent
      record.id = 2
      expect(faux_parent.recordIdChanged).toHaveBeenCalledWith record, 1

      # don't report if id has not changed
      faux_parent = {recordIdChanged: ->}
      spyOn faux_parent, 'recordIdChanged'
      record = new EditableRecord example, null, faux_parent
      record.x = 3
      expect(faux_parent.recordIdChanged).not.toHaveBeenCalled()

      # should not fail if parent has no .recordIdChanged() method
      record = new EditableRecord example, null, {}
      expect(-> record.id = 3).not.toThrow()
      expect(record._id).toBe 3

    it 'Can create empty container', ->
      record = null
      expect(-> record = new EditableRecord).not.toThrow()

      found_keys = 0
      for k, v of record
        found_keys += 1
      expect(found_keys).toBe 0

    it 'Will not replace if not needed', ->
      record = new EditableRecord {a: 1}

      saved = record._saved
      record._replace {a: 1}
      expect(record._saved).toBe saved

      record._replace {a: 1, b: 2}
      expect(record._saved).not.toBe saved

      # with contract
      record = new EditableRecord null, {contract: {a: default: 1}}

      saved = record._saved
      record._replace {}
      expect(record._saved).toBe saved

      record._replace {a: 2}
      expect(record._saved).not.toBe saved

    it 'Composite id changes', ->
      example = {id1: 1, id2: 2, x: 3}
      opts    = idProperty: ['id1', 'id2']

      record = new EditableRecord example, opts
      record.id1 = 4
      record.id1 = 2
      expect(record._id).toBe '2-2'

      # report to parent
      faux_parent = {recordIdChanged: ->}
      spyOn faux_parent, 'recordIdChanged'
      record = new EditableRecord example, opts, faux_parent
      record.id1 = 2
      expect(faux_parent.recordIdChanged).toHaveBeenCalledWith record, '1-2'

      # don't report if id has not changed
      faux_parent = {recordIdChanged: ->}
      spyOn faux_parent, 'recordIdChanged'
      record = new EditableRecord example, opts, faux_parent
      record.x = 2
      expect(faux_parent.recordIdChanged).not.toHaveBeenCalled()

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
      record.d = {xxx: 1}
      expect(record.d.xxx).toBeUndefined()
      expect(-> record.d = null).not.toThrow()
      expect(record.d).toBe null
      expect(-> record.e = null).toThrow()
