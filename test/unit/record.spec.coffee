
describe 'app.factory', ->

  describe 'Record', ->

    List = Record = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        List   = $injector.get 'ksc.List'
        Record = $injector.get 'ksc.Record'


    it 'Does not accept property names starting with underscore', ->
      expect(-> new Record _a: 1).toThrow()

    it 'Data argument must be null/undefined/Object', ->
      expect(-> new Record 'fds').toThrow()

    it 'Options argument must be null/undefined/Object', ->
      expect(-> new Record {a: 1}, 'fds').toThrow()

    it 'Handles real arrays', ->
      r = null
      arr = [1, 2]
      expect(-> r = new Record a: arr).not.toThrow()

      expect(Array.isArray r.a).toBe true
      expect(r.a).not.toBe arr
      expect(r.a.length).toBe 2
      expect(r.a[0]).toBe 1

      expect(-> r.a.push 3).toThrow()
      expect(r.a[2]).toBeUndefined()

      expect(-> r.a = [11, 12, 13, 14]).toThrow()

    it 'Returned native array object carries record properies', ->
      r = new Record a: [1, 2]
      expect(r.a._record instanceof Record).toBe true
      expect(r.a._delete).toBe r._delete
      expect(r.a._getProperty).toBe r._getProperty

      r.a._record._eee = 3423
      expect(r.a._eee).toBe 3423
      expect(r.a.hasOwnProperty '_eee').toBe true

      delete r.a._record._eee
      expect(r.a._eee).toBeUndefined()
      expect(r.a.hasOwnProperty '_eee').toBe false

    it 'Method ._clone()', ->
#       example = {id: 1, x: 2, y: {a: 3}, z: [0, 1, 2]}
      example = {id: 1, x: 2, y: {a: 3}}
      record = new Record example

      obj = record._clone true
      expect(obj).toEqual example

      example.ext = 1
      record.ext = 1
      obj = record._clone true
      expect(obj).toEqual example

      record2 = record._clone()
      expect(record).toEqual record2
      expect(record).not.toBe record2

    it 'Method ._entity()', ->
      example = {id: 1, x: 2, y: {a: 3}}
      record = new Record example
      ent = record._entity()
      expect(ent).toEqual example
      expect(ent).not.toBe example

    it 'Method ._replace()', ->
      example = {id: 1, x: 2, y: {a: 3}, z: 1}
      example2 = {id: 2, x: 3, y: new Record {dds: 43, dff: 4}}
      expected = {id: 2, x: 3, y: {dds: 43, dff: 4}}
      record = new Record example
      record._replace example2
      ent = record._clone true
      expect(ent).toEqual expected
      expect(ent).not.toBe expected

    it 'Will not replace if not needed', ->
      record = new Record {a: {x: 1}}

      ref = record.a

      expect(record._replace {a: {x: 1}}).toBe false
      expect(record.a).toBe ref # did not change references either

      # with contract
      record = new Record {id: 1},
        contract:
          id: {type: 'number'}
          a:  {default: 1}

      saved = record._entity()

      record._replace {id: 1}
      expect(record._entity()).toEqual saved

      record._replace {id: 1, a: 2}
      expect(record._entity()).not.toEqual saved

      record._replace {id: 1}
      expect(record._entity()).toEqual saved

    it 'No _id case', ->
      list = new List record: idProperty: 'x'
      record = null
      expect(-> list.push record = new Record {}).not.toThrow()
      expect(record._id).toBeUndefined()

    it 'idProperty-contract type conflict', ->
      list = new List record: idProperty: 'x', contract: {x: type: 'boolean'}
      expect(-> list.push new Record {}).toThrow()

    it 'idProperty missing in contract error', ->
      list = new List record: idProperty: 'id', contract: {x: type: 'number'}
      expect(-> list.push new Record {}).toThrow()

    describe 'Composite _id (listparent.options.record.idProperty is array)', ->

      it 'Basic scenarios', ->
        list = new List record: idProperty: ['id', 'otherId']
        record = new Record {id: 1, otherId: 2}
        list.push record
        expect(record._id).toBe '1-2'
        expect(record._primaryId).toBe 1

        record._replace {id: 1}
        expect(record._id).toBe '1'
        expect(record._primaryId).toBe 1

        record._replace {otherId: 1}
        expect(record._id).toBeUndefined()
        expect(record._primaryId).toBeUndefined()

      it 'Contract mismatches', ->
        list = new List record: idProperty: ['id', 'x']
        contract =
          id: {type: 'number', nullable: true}
          x:  {type: 'boolean'}

        expect(-> list.push new Record {}, {contract}).toThrow()

    it 'Data separation', ->
      example_sub = {a: 3}
      example = {id: 1, x: 2, y: example_sub}

      record = new Record example

      example.id    = 2
      example.ext   = 3
      example_sub.a = 4
      example_sub.x = 4

      expect(record.id).toBe 1
      expect(record.ext).toBeUndefined()
      expect(record.y.a).toBe 3
      expect(record.y.x).toBeUndefined()

    it 'Does not take functions', ->
      expect(-> new Record {id: 1, fn: ->}).toThrow()

    it 'Parent registration', ->
      record = new Record {id: 1}, null, {x: 'a'}
      expect(record._parent.x).toBe 'a'

      # Parent must be an object if specified
      expect(-> new Record {id: 1}, null, 'x').toThrow()

      # Parent_key must be string or number
      expect(-> new Record {id: 1}, null, {}, true).toThrow()

      # Parent_key requires parent object
      expect(-> new Record {id: 1}, null, null, 'x').toThrow()

    it 'Contract record', ->
      list = new List record: idProperty: 'id'

      contract =
        id: {type: 'number'}
        a: {type: 'string', nullable: true}
        b: {type: 'string'}
        c: {default: ':)', nullable: true}
        d: {type: 'boolean', nullable: true}
        e: {type: 'boolean', default: true, nullable: true}
        f: {type: 'boolean'}
        g: {contract: {a: {type: 'number'}}, nullable: true}
        h: {type: 'object', contract: {
          a: {type: 'number', default: 1, nullable: true},
          b: {contract: {x: {type: 'number', nullable: true}}}}}

      list.push record = new Record {id: 1}, {contract}

      expect(record._id).toBe 1
      expect(record.id).toBe 1
      expect(record.a).toBe null
      expect(record.b).toBe ''
      expect(record._options.contract.c.type).toBe 'string'
      expect(record.c).toBe ':)'
      expect(record.d).toBe null
      expect(record.e).toBe true
      expect(record.f).toBe false
      expect(record.g).toBe null
      expect(record.h.a).toBe 1
      expect(record.h.b.x).toBe null

      expect(-> new Record {id: 1}, {contract: 1}).toThrow()

      contract = {id: {type: 'string'}}
      expect(-> new Record {id: 1}, {contract}).toThrow()

      contract = {id: {type: 'number'}}
      expect(-> new Record {id: null}, {contract}).toThrow()

      contract = {x: {type: 'number'}}
      expect(-> new Record {id: 1}, {contract}).toThrow()

      contract = {id: {type: 'number'}, _id: {type: 'number'}}
      expect(-> new Record {id: 1}, {contract}).toThrow()

      contract = {id: {type: 'number', nullable: 1}}
      record = new Record {id: 1}, {contract}
      expect(record._options.contract.id.nullable).toBe true

      contract = {id: {type: 'number'}, x: {contract: 1}}
      expect(-> new Record {id: 1}, {contract}).toThrow()

      contract = {id: {type: 'object'}}
      expect(-> new Record null, {contract}).toThrow()

      contract = {id: {contract: {a: {type: 'number'}}, type: 'string'}}
      expect(-> new Record null, {contract}).toThrow()

      contract = {id: {type: 'joke'}}
      expect(-> new Record null, {contract}).toThrow()

      contract = {id: {contract: 1}}
      expect(-> new Record null, {contract}).toThrow()

      contract = {id: {contract: {a: {type: 'number'}}, default: null}}
      expect(-> new Record {id: 1}, {contract}).toThrow()

    it 'Defined .options.idProperty', ->
      list = new List record: idProperty: 'b'
      list.push record = new Record {a: 1, b: 2}
      expect(record._id).toBe 2

    it 'Undefined .options.idProperty and no data leaves _id undefined', ->
      record = new Record
      expect(record._id).toBeUndefined()

    it 'Can not _replace() subobject', ->
      record = new Record {a: 1, b: {a: 1}}
      expect(-> record.b._replace {x: 1}).toThrow()

    it 'Subscribing for update events', ->
      record = new Record {a: 1}
      distributed = null
      record._events.on 'update', (update) ->
        distributed = update
      record._replace {b: 2}

      expect(distributed.node).toBe record
      expect(distributed.action).toBe 'replace'

    it 'Method ._delete() throws error (read-only)', ->
      record = new Record {a: 1}
      expect(-> record._delete('a')).toThrow()
      expect(-> record._delete('b')).toThrow()
      expect(-> record._delete('c', 'd')).toThrow()
      expect(-> record._delete()).toThrow()

    it 'Method Record.checkIdProperty()', ->
      expect(-> Record.checkIdProperty()).not.toThrow()
      expect(-> Record.checkIdProperty null).not.toThrow()
      expect(-> Record.checkIdProperty undefined).not.toThrow()
      expect(-> Record.checkIdProperty false).toThrow()
      expect(-> Record.checkIdProperty true).toThrow()
      expect(-> Record.checkIdProperty []).toThrow()
      expect(-> Record.checkIdProperty {0: 'a', 1: 'b'}).toThrow()
      expect(-> Record.checkIdProperty 0).not.toThrow()
      expect(-> Record.checkIdProperty [0, 1]).not.toThrow()
      expect(-> Record.checkIdProperty 'aa').not.toThrow()
#
