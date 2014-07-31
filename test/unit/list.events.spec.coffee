
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
