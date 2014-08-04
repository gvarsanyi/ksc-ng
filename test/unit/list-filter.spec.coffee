
describe 'app.factory', ->

  describe 'ListFilter', ->

    List = ListFilter = action = list = sublist = unsubscribe = null

    filter_fn = (record) -> # has letter 'A' or 'a' in stringified record.a
      String(record.a).toLowerCase().indexOf('a') > -1

    beforeEach ->
      module 'app'
      inject ($injector) ->
        List       = $injector.get 'ksc.List'
        ListFilter = $injector.get 'ksc.ListFilter'

        list = new List
        list.push {id: 1, a: 'xyz'}, {id: 2, a: 'abc'}

        sublist = new ListFilter list, filter_fn

        action = null
        unsubscribe = sublist.events.on 'update', (info) ->
          action = info.action

    afterEach ->
      unsubscribe()


    it 'Filters immediately when created', ->
      list = new List
      list.push {id: 1, a: 'xyz'}, {id: 2, a: 'abc'}, {a: 'aaa'}

      sublist = new ListFilter list, filter_fn

      expect(sublist.length).toBe 2
      expect(sublist[0].id).toBe 2
      expect(sublist[1].id).toBeUndefined()

    describe 'Following events', ->

      it 'Addition', ->
        list.push {id: 3, a: 'fff'} # should not trigger (does not have 'a')
        expect(action).toBe null

        list.push {id: 4, a: 'xaxa'}, {id: 5}, {id: 6, a: 'aaa'},
                  {a: 'x'}, {a: 'aa'}
        expect(action.add.length).toBe 3
        expect(action.add[0]).toBe list[3]
        expect(action.add[0]).toBe sublist[1]
        expect(sublist.length).toBe 4

      it 'Cut', ->
        list.cut 1 # should not trigger (does not have 'a')
        expect(action).toBe null

        list.push {id: 4, a: 'xaxa'}, {id: 5}, {id: 6, a: 'aaa'},
                  {a: 'x'}, {a: 'aa'}, {a: 'b'}

        record = sublist[0]
        list.cut 2, list[6], list[5]
        expect(action.cut.length).toBe 2
        expect(action.cut[0]).toBe record
        expect(sublist.length).toBe 2

      it 'Empty', ->
        list.push {id: 3, a: 'aaa'}, {a: 'a'}, {a: 'few'}

        list.empty()
        expect(action.cut.length).toBe 3
        expect(sublist.length).toBe 0

      it 'Upsert', ->
        list.push {id: 1, a: 'xxx'} # should not trigger (does not have 'a')
        expect(action).toBe null

        list.push {id: 2, a: 'aaa'}, {a: 'a'}
        expect(action.upsert.length).toBe 1
        expect(action.upsert[0]).toBe sublist[0]
        expect(action.add[0]).toBe sublist[1]
        expect(sublist.length).toBe 2

        list.push {id: 2, a: 'yyy'} # triggers cut @ sublist
        expect(action.cut.length).toBe 1
        expect(action.cut[0]).toBe list[1]
        expect(sublist.length).toBe 1
