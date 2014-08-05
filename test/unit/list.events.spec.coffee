
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

        expect(distributed.action.add.length).toBe 1
        expect(distributed.action.add[0].x).toBe 'd'
        expect(distributed.action.update.length).toBe 1
        expect(distributed.action.update[0].record.x).toBe 'c'
        expect(distributed.action.update[0].source).toEqual {id: 2, x: 'c'}

      it 'Method .unshift()', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        distributed = null

        list.events.on 'update', (update) ->
          distributed = update

        list.push {id: 2, x: 'c'}, {id: 3, x: 'd'}

        expect(distributed.action.add.length).toBe 1
        expect(distributed.action.add[0].x).toBe 'd'
        expect(distributed.action.update.length).toBe 1
        expect(distributed.action.update[0].record.x).toBe 'c'
        expect(distributed.action.update[0].source).toEqual {id: 2, x: 'c'}

      it 'Method .pop()', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        distributed = null

        list.events.on 'update', (update) ->
          distributed = update

        list.pop()

        expect(distributed.action.cut.length).toBe 1
        expect(distributed.action.cut[0].x).toBe 'b'

      it 'Method .shift()', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        distributed = null

        list.events.on 'update', (update) ->
          distributed = update

        list.shift()

        expect(distributed.action.cut.length).toBe 1
        expect(distributed.action.cut[0].x).toBe 'a'

      it 'Method .empty()', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        distributed = null

        list.events.on 'update', (update) ->
          distributed = update

        list.empty()

        expect(distributed.action.cut.length).toBe 2
        expect(distributed.action.cut[0].x).toBe 'a'
        expect(distributed.action.cut[1].x).toBe 'b'

      it 'Method .cut()', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        distributed = null

        list.events.on 'update', (update) ->
          distributed = update

        list.cut 2, 1

        expect(distributed.action.cut.length).toBe 2
        expect(distributed.action.cut[0].x).toBe 'b'
        expect(distributed.action.cut[1].x).toBe 'a'

      it 'On record change', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        response = null
        list.events.on 'update', (info) ->
          response = info

        list.map[2].x = 'c'

        expect(response.action.update[0].record.id).toBe 2
        expect(response.action.update[0].info.action).toBe 'set'
        expect(response.action.update[0].info.key).toBe 'x'

      it 'On record change (with ._id update)', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        response = null
        list.events.on 'update', (info) ->
          response = info

        list.map[2].id = 3
        record = list[1]

        action = response.action

        expect(action.update.length).toBe 1
        expect(action.update[0].move).toEqual {from: {map: 2}, to: {map: 3}}
        expect(action.update[0].record).toBe record
        expect(action.update[0].record._id).toBe 3
        expect(action.update[0].info.key).toBe 'id'
        expect(list.map[2]).toBeUndefined()
        expect(list.map[3]).toBe list[1]

      it 'On record change (with ._id update triggered merge)', ->
        list = new List
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        record = list[0]
        source = list[1]

        response = null
        list.events.on 'update', (info) ->
          response = info

        list.map[2].id = 1

        action = response.action

        expect(action.update.length).toBe 1
        expect(action.update[0].merge).toEqual {from: {map: 2}, to: {map: 1}}
        expect(action.update[0].record).toBe record
        expect(action.update[0].source).toBe source
        expect(action.update[0].record._id).toBe 1
        expect(action.update[0].info.key).toBe 'id'
        expect(list.map[2]).toBeUndefined()
        expect(list.length).toBe 1
        expect(list[0].x).toBe 'b'

      it 'On record change / error handling', ->
        list = new List
        list.push {id: 1, a: 1}

        expect(-> list._recordChange {}).toThrow() # expects Record instance
        expect(-> list._recordChange list[0], {}, 99).toThrow() # old_id bugga
