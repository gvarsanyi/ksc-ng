
describe 'app.factory', ->

  describe 'EditableRecord', ->

    EditableRecord = example_set = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        EditableRecord = $injector.get 'ksc.EditableRecord'
        example_set    = {a: 1, b: {c: 1, d: {e: 1, f: 1, g: 1, h: 1}}}


    describe 'Events', ->

      it 'Replace', ->
        record = new EditableRecord example_set

        distributed = null
        record._events.on 'update', (update) ->
          distributed = update
        record._replace {b: 2}

        expect(distributed.node).toBe record
        expect(distributed.action).toBe 'replace'
        expect(distributed.parent).toBeUndefined()

      it 'Revert', ->
        record = new EditableRecord example_set
        record.a = 2

        distributed = null
        value = null

        record._events.on 'update', (update) ->
          distributed = update
          value = record.a

        record._revert()

        expect(distributed.node).toBe record
        expect(distributed.action).toBe 'revert'
        expect(value).toBe 1

      it 'Delete', ->
        record = new EditableRecord example_set
        record.c = 'x'

        distributed = null
        value = null

        record._events.on 'update', (update) ->
          distributed = update
          value = record.b

        record._delete 'b', 'c'

        expect(distributed.node).toBe record
        expect(distributed.action).toBe 'delete'
        expect(distributed.keys).toEqual ['b', 'c']
        expect(value).toBeUndefined()

      it 'Set', ->
        record = new EditableRecord example_set

        distributed = null
        value = null

        record._events.on 'update', (update) ->
          distributed = update
          value = record.a

        record.a = 2

        expect(distributed.node).toBe record
        expect(distributed.action).toBe 'set'
        expect(distributed.key).toBe 'a'
        expect(value).toBe 2

      it 'Subrecord set', ->
        record = new EditableRecord example_set

        distributed = null
        value = null

        record._events.on 'update', (update) ->
          distributed = update
          value = record.b.d.e

        record.b.d.e = 2

        expect(distributed.node).toBe record.b.d
        expect(distributed.parent).toBe record
        expect(distributed.path).toEqual ['b', 'd']
        expect(distributed.action).toBe 'set'
        expect(distributed.key).toBe 'e'
        expect(value).toBe 2
