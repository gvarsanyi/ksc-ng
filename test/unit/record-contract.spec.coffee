
describe 'app.factory', ->

  describe 'RecordContract', ->

    Record = RecordContract = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        Record         = $injector.get 'ksc.Record'
        RecordContract = $injector.get 'ksc.RecordContract'


    it 'Does not create new instance when already a RecordContract', ->
      record1 = new Record {}, contract: a: type: 'number'
      record2 = new Record {}, contract: record1._options.contract
      expect(record1._options.contract).toBe record2._options.contract
      expect(record1._options.contract instanceof RecordContract).toBe true

    it 'Uses specified defaults', ->
      record = new Record {},
        contract:
          a:
            default: 1
          b:
            contract:
              x:
                type: 'boolean'
              y:
                type: 'boolean'
                nullable: true

      expect(record.a).toBe 1
      expect(record.b.x).toBe false
      expect(record.b.y).toBe null

    it 'Read-only array contracts', ->
      record = new Record {id: 1, c: [{}, {x: true, y: true}]},
        contract:
          id: {default: 1}
          a:
            array:
              type: 'number'
              nullable: true
          b:
            nullable: true
            array:
              type: 'boolean'
          c:
            nullable: true
            array:
              contract:
                x: {type: 'boolean'}
                y: {type: 'boolean', nullable: true}

      expect(Array.isArray record.a).toBe true
      expect(record.b).toBe null
      expected = JSON.stringify [{x: false, y: null}, {x: true, y: true}]
      expect(JSON.stringify record.c).toBe expected

      expect(-> record.a.push 'a').toThrow()
      expect(record.a.length).toBe 0

      expect(-> record.a.push 1).toThrow()
      expect(record.a.length).toBe 0

      expect(-> record.a = null).toThrow() # read only

    it 'Method .finalizeRecord()', ->
      record = new Record {}, contract: a: type: 'number'
      RecordContract.finalizeRecord record
      record.x = 1
      expect(record.x).toBeUndefined()

    it 'Method ._default()', ->
      record = new Record {}, contract: a: type: 'number'
      expect(record._options.contract._default 'a').toBe 0

    it 'Method ._match()', ->
      record = new Record {}, contract: a: type: 'number'
      expect(record._options.contract._match 'a', 1).toBe true

    describe 'Edge cases', ->

      it 'Mutually exclusive keys: array, contract, default', ->
        contract = a: {contract: {x: type: 'string'}, default: null}
        expect(-> new Record {}, {contract}).toThrow()

        contract = a: {array: {type: 'string'}, default: null}
        expect(-> new Record {}, {contract}).toThrow()

        contract = a: {array: {type: 'string'}, contract: {x: type: 'number'}}
        expect(-> new Record {}, {contract}).toThrow()

      it 'Contract a proper description', ->
        expect(-> new Record {}, contract: true).toThrow()
        expect(-> new Record {}, contract: a: {type: 'object'}).toThrow()
        expect(-> new Record {}, contract: a: array: 1).toThrow()
        expect(-> new Record {}, contract: a: {type: 'x'}).toThrow()

        contract =
            a:
              type: 'number'
              default: 'a'
        expect(-> new Record {}, {contract}).toThrow()

        contract =
            a:
              contract: x: type: 'string'
              type: 'number'
        expect(-> new Record {}, {contract}).toThrow()

        contract =
            a:
              array: type: 'string'
              type: 'number'
        expect(-> new Record {}, {contract}).toThrow()

        contract =
            a:
              contract: x: type: 'string'
              default: null
        expect(-> new Record {}, {contract}).toThrow()

      it 'Contract keys can not start with underscore', ->
        expect(-> new Record {}, contract: '_a': type: 'number').toThrow()

      it 'Method ._default() with invalid key', ->
        record = new Record {}, contract: a: type: 'number'
        expect(-> record._options.contract._default true).toThrow()

      it 'Method ._match() with invalid key', ->
        record = new Record {}, contract: a: type: 'number'
        expect(-> record._options.contract._match true, 'x').toThrow()

      it 'Method ._match() with invalid value', ->
        record = new Record {}, contract: a: type: 'number'
        expect(-> record._options.contract._match 'a', 'x').toThrow()

    it 'Not extensible ($$hashKey added)', ->
      record = new Record {}, contract: a: type: 'number'
      try
        record.b = 1
      expect(record.b).toBeUndefined()
      expect(record.hasOwnProperty '$$hashKey').toBe true
      expect(record.propertyIsEnumerable '$$hashKey').toBe false

      record = new Record {$$hashKey: 'x'}, contract:
        a: type: 'number'
        $$hashKey: type: 'string'
      try
        record.b = 1
      expect(record.b).toBeUndefined()
      expect(record.propertyIsEnumerable '$$hashKey').toBe true
