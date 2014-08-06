
describe 'app.factory', ->

  describe 'ListFilter', ->

    List = ListFilter = action = filter_c = list = sublist = unsubscribe = null

    filter_fn = (record) -> # has letter 'A' or 'a' in stringified record.a
      String(record.a).toLowerCase().indexOf(filter_c) > -1

    beforeEach ->
      module 'app'
      inject ($injector) ->
        List       = $injector.get 'ksc.List'
        ListFilter = $injector.get 'ksc.ListFilter'

        list = new List
        list.push {id: 1, a: 'xyz'}, {id: 2, a: 'abc'}

        filter_c = 'a'

        sublist = new ListFilter list, filter_fn

        action = null
        unsubscribe = sublist.events.on 'update', (info) ->
          action = info.action

    afterEach ->
      unsubscribe()


    it 'Filters immediately when created', ->
      list = new List sorter: 'b'
      list.push {id: 1, a: 'xyz', b: 'a'}, {id: 2, a: 'abc', b: 'b'},
                {id: null, a: 'aaa', b: 'c'}

      sublist = new ListFilter list, filter_fn

      expect(sublist.length).toBe 2
      expect(sublist[0].id).toBe 2
      expect(sublist[1].id).toBe null

    it 'Uses its own sorter for initial load', ->
      list = new List
      list.push {id: 1, a: 'xyz'}, {id: 2, a: 'abc'}, {id: null, a: 'aaa'}

      sublist = new ListFilter list, filter_fn, sorter: 'a'

      expect(sublist.length).toBe 2
      expect(sublist[0].a).toBe 'aaa'
      expect(sublist[1].a).toBe 'abc'

    it 'Keeps parent list sort', ->
      list = new List sorter: 'a'
      sublist = new ListFilter list, filter_fn

      list.push {id: 1, a: 'xyz'}, {id: 2, a: 'abc'}, {id: null, a: 'aaa'}

      expect(sublist.length).toBe 2
      expect(sublist[0].a).toBe 'aaa'
      expect(sublist[1].a).toBe 'abc'

      list[1].a = 'aax'

      expect(sublist.length).toBe 2
      expect(sublist[0].a).toBe 'aaa'
      expect(sublist[1].a).toBe 'aax'

    it 'Sorted sublist updates', ->
      list = new List
      sublist = new ListFilter list, filter_fn, sorter: 'a'

      list.push {id: 1, a: 'xyz'}, {id: 2, a: 'abc'}, {id: null, a: 'aaa'}

      expect(sublist.length).toBe 2
      expect(sublist[0].a).toBe 'aaa'
      expect(sublist[1].a).toBe 'abc'

      list[1].a = 'aax'

      expect(sublist.length).toBe 2
      expect(sublist[0].a).toBe 'aaa'
      expect(sublist[1].a).toBe 'aax'

      list[1].a = 'xxx'
      list[2].a = 'xxx'
      expect(sublist.length).toBe 0

    it 'Method .destroy() unsubscribes from list', ->
      expect(sublist.destroy()).toBe true
      list[1].id = 3

      expect(action).toBe null

      expect(-> sublist.destroy()).toThrow()

    it 'Method .update()', ->
      list.push {id: 3, a: 'bbb'}, {id: 4, a: 'aaa'}, {id: null, a: 'boo'}
      expect(sublist.length).toBe 2
      expect(sublist[1].id).toBe 4
      filter_c = 'b'
      expect(sublist.length).toBe 2
      expect(sublist[1].id).toBe 4
      sublist.update()
      expect(sublist.length).toBe 3
      expect(sublist[1].id).toBe 3
      expect(sublist[2].a).toBe 'boo'

      filter_c = 'x'
      sublist.update()
      expect(sublist.length).toBe 1
      expect(sublist[0].id).toBe 1

      filter_c = '0'
      sublist.update()
      expect(sublist.length).toBe 0

      filter_c = '1'
      sublist.update()
      expect(sublist.length).toBe 0

      filter_c = 'x'
      sublist.update()
      expect(sublist.length).toBe 1
      expect(sublist[0].id).toBe 1

    it 'Method .update() called on .filter = fn', ->
      list.push {id: 3, a: 'bbb'}, {id: 4, a: 'aaa'}, {id: null, a: 'boo'}
      sublist.filter = (record) ->
        record.id is null
      expect(sublist.length).toBe 1
      expect(sublist[0].a).toBe 'boo'

      # should only accept functions
      expect(-> sublist.filter = true).toThrow()

    it 'Constructor argument type checks', ->
      expect(-> new ListFilter [], (->)).toThrow()
      expect(-> new ListFilter list).toThrow()

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
        expect(action.update.length).toBe 1
        expect(action.update[0].record).toBe sublist[0]
        expect(action.add[0]).toBe sublist[1]
        expect(sublist.length).toBe 2

        list.push {id: 2, a: 'yyy'} # triggers cut @ sublist
        expect(action.cut.length).toBe 1
        expect(action.cut[0]).toBe list[1]
        expect(sublist.length).toBe 1

      it 'Update a pseudo record that is on sublist', ->
        list.push {id: null, a: 'aba'}
        action = null

        list[2].a = 'aca'
        expect(action.update.length).toBe 1
        expect(action.update[0].info.key).toBe 'a'
        expect(sublist[1].a).toBe 'aca'

      describe 'Move', ->

        describe 'Meets filter', ->

          describe 'Was on sublist', ->

            it 'Parent list move: map -> map', ->
              list.map[2].id = 9

              expect(action.update.length).toBe 1
              move_info = {from: {map: 2}, to: {map: 9}}
              expect(action.update[0].move).toEqual move_info
              expect(action.update[0].record).toBe sublist[0]
              expect(sublist.map[2]).toBeUndefined()
              expect(sublist.map[9]).toBe list[1]

            it 'Parent list move: map -> pseudo', ->
              list.map[2].id = null

              expect(action.update.length).toBe 1
              move_info = {from: {map: 2}, to: {pseudo: sublist[0]._pseudo}}
              expect(action.update[0].move).toEqual move_info
              expect(action.update[0].record).toBe sublist[0]
              expect(sublist.map[2]).toBeUndefined()
              expect(sublist.pseudo[sublist[0]._pseudo]).toBe list[1]

            it 'Parent list move: pseudo -> map', ->
              list[1].id = null
              orig_pseudo = list[1]._pseudo
              list[1].id = 9

              expect(action.update.length).toBe 1
              move_info = {from: {pseudo: orig_pseudo}, to: {map: 9}}
              expect(action.update[0].move).toEqual move_info
              expect(action.update[0].record).toBe sublist[0]
              expect(sublist.pseudo[orig_pseudo]).toBeUndefined()
              expect(sublist.map[9]).toBe list[1]

          describe 'Was NOT on sublist', ->

            it 'Parent list move: map -> map', ->
              list[1]._replace {id: 2, a: 'x'} # removes from sublist
              expect(sublist.length).toBe 0

              list[1]._replace {id: 9, a: 'aaa'}

              expect(action.add.length).toBe 1
              expect(sublist.length).toBe 1
              expect(sublist.map[9]).toBe list[1]

            it 'Parent list move: map -> pseudo', ->
              list[1]._replace {id: 2, a: 'x'} # removes from sublist
              expect(sublist.length).toBe 0

              list[1]._replace {id: null, a: 'aaa'}

              expect(action.add.length).toBe 1
              expect(sublist.length).toBe 1
              expect(sublist.pseudo[list[1]._pseudo]).toBe list[1]

            it 'Parent list move: pseudo -> map', ->
              list[1]._replace {id: null, a: 'x'} # removes from sublist
              expect(sublist.length).toBe 0

              list[1]._replace {id: 9, a: 'aaa'}

              expect(action.add.length).toBe 1
              expect(sublist.length).toBe 1
              expect(sublist.map[9]).toBe list[1]

        describe 'Does NOT meet filter', ->

          it 'Was on sublist map', ->
            list[1]._replace {id: 2, a: 'y'}

            expect(action.cut.length).toBe 1
            expect(sublist.length).toBe 0
            expect(sublist.map[2]).toBeUndefined()

          it 'Was on sublist pseudo', ->
            list[1].id = null
            action = null

            list[1]._replace {id: 9, a: 'y'}

            expect(action.cut.length).toBe 1
            expect(sublist.length).toBe 0
            expect(sublist.map[2]).toBeUndefined()

          it 'Was not on sublist', ->
            list[1]._replace {id: 2, a: 'x'} # removes from sublist
            expect(sublist.length).toBe 0
            action = null

            list[1]._replace {id: 2, a: 'y'}
            expect(sublist.length).toBe 0
            expect(action).toBe null

      describe 'Merge', ->

        it 'Both source and target were on sublist', ->
          list.push {id: null, a: 'aaa'}
          orig_pseudo = list[2]._pseudo
          action = null

          list[2].id = 2
          expect(action.update.length).toBe 1
          merge_info = {from: {pseudo: orig_pseudo}, to: {map: 2}}
          expect(action.update[0].merge).toEqual merge_info
          expect(sublist.length).toBe 1
          expect(sublist.map[2].a).toBe 'aaa'

        it 'Should cut both source and target from sublist (on map)', ->
          list.push {id: 9, a: 'axa'}
          expect(sublist.length).toBe 2

          list[1]._replace {id: 9, a: 'eeee'}
          expect(action.cut.length).toBe 2
          expect(sublist.length).toBe 0
