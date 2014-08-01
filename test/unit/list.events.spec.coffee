
describe 'app.factory', ->

  describe 'List', ->

    EditableRecord = List = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        EditableRecord = $injector.get 'ksc.EditableRecord'
        List           = $injector.get 'ksc.List'

    describe 'Events', ->

      it 'Method .push()', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        distributed = null

        list.events.on 'update', (update) ->
          distributed = update

        list.push {id: 2, x: 'c'}, {id: 3, x: 'd'}

        expect(distributed.insert.length).toBe 1
        expect(distributed.insert[0].x).toBe 'd'
        expect(distributed.update.length).toBe 1
        expect(distributed.update[0].x).toBe 'c'

      it 'Method .unshift()', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        distributed = null

        list.events.on 'update', (update) ->
          distributed = update

        list.push {id: 2, x: 'c'}, {id: 3, x: 'd'}

        expect(distributed.insert.length).toBe 1
        expect(distributed.insert[0].x).toBe 'd'
        expect(distributed.update.length).toBe 1
        expect(distributed.update[0].x).toBe 'c'

      it 'Method .pop()', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        distributed = null

        list.events.on 'update', (update) ->
          distributed = update

        list.pop()

        expect(distributed.cut.length).toBe 1
        expect(distributed.cut[0].x).toBe 'b'

      it 'Method .shift()', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        distributed = null

        list.events.on 'update', (update) ->
          distributed = update

        list.shift()

        expect(distributed.cut.length).toBe 1
        expect(distributed.cut[0].x).toBe 'a'

      it 'Method .empty()', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        distributed = null

        list.events.on 'update', (update) ->
          distributed = update

        list.empty()

        expect(distributed.cut.length).toBe 2
        expect(distributed.cut[0].x).toBe 'a'
        expect(distributed.cut[1].x).toBe 'b'

      it 'Method .cut()', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        distributed = null

        list.events.on 'update', (update) ->
          distributed = update

        list.cut 2, 1

        expect(distributed.cut.length).toBe 2
        expect(distributed.cut[0].x).toBe 'b'
        expect(distributed.cut[1].x).toBe 'a'

      it 'On record change', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        response = null
        list.events.on 'update', (info) ->
          response = info

        list.map[2].x = 'c'

        expect(response.record.node.id).toBe 2
        expect(response.record.action).toBe 'set'
        expect(response.record.key).toBe 'x'

      it 'On record change (with ._id update)', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        response = null
        list.events.on 'update', (info) ->
          response = info

        list.map[2].id = 3

        expect(response.update.length).toBe 1
        expect(response.update[0]).toBe list[1]
        expect(response.record.node._id).toBe 3
        expect(response.record.key).toBe 'id'
        expect(list.map[2]).toBeUndefined()
        expect(list.map[3]).toBe list[1]

      it 'On record change (with ._id update triggered merge)', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        record = list[1]

        response = null
        list.events.on 'update', (info) ->
          response = info

        list.map[2].id = 1

        expect(response.update.length).toBe 1
        expect(response.update[0]).toBe record
        expect(response.record.node._id).toBe 1
        expect(response.record.key).toBe 'id'
        expect(list.map[2]).toBeUndefined()
        expect(list.length).toBe 1
        expect(list[0].x).toBe 'b'

      it 'On record change / error handling', ->
        list = new List
        list.push {id: 1, a: 1}

        expect(-> list._recordChange {}).toThrow() # expects Record instance
        expect(-> list._recordChange list[0], {}, 99).toThrow() # old_id bugga
