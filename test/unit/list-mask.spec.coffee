
describe 'app.factory', ->

  describe 'ListMask', ->

    $rootScope = List = ListMask = action = filter_c = list = list2 = null
    splitter = sublist = unsubscribe = null

    filter_fn = (record) -> # has letter 'A' or 'a' in stringified record.a
      String(record.a).toLowerCase().indexOf(filter_c) > -1

    beforeEach ->
      module 'app'
      inject ($injector) ->
        $rootScope = $injector.get '$rootScope'
        List       = $injector.get 'ksc.List'
        ListMask   = $injector.get 'ksc.ListMask'

        list = new List 'id'
        list.push {id: 1, a: 'xyz'}, {id: 2, a: 'abc'}

        list2 = new List 'id2'
        list2.push {id2: 1, a: 'xyz2'}, {id2: 22, a: 'abc2'}

        filter_c = 'a'

        splitter = (record) ->
          step = 10
          if record.end - record.start > step
            fakes = for i in [record.start ... record.end] by step
              {start: i, end: Math.min record.end, i + step}
            return fakes
          false # just use the record

        sublist = new ListMask list, filter_fn

        action = null
        unsubscribe = sublist.events.on 'update', (info) ->
          action = info.action

    afterEach ->
      unsubscribe()

      # all items must be getters
      for item, i in list
        expect(Object.getOwnPropertyDescriptor(list, i).get?).toBe true


    it 'Extended class works', ->
      class Masky extends ListMask
        constructor: (list) ->
          return super list, (-> true)

        first: ->
          @[0]

        list = new List
        list.push {id: 1, start: 30, end: 50}, {id: 2, start: 7, end: 8}

        sublist = new Masky list
        expect(sublist.length).toBe 2
        expect(sublist.first().id).toBe 1

    describe 'Split records', ->
      it 'basic scenario', ->
        list = new List
        list.push {id: 1, start: 30, end: 50}, {id: 2, start: 7, end: 8},
                  {id: 3, start: 20, end: 41}

        sublist = new ListMask list, {splitter}
        expect(sublist.length).toBe 6
        expect(sublist[5].start).toBe 40
        expect(sublist[5].end).toBe 41

        list.pop()
        expect(sublist.length).toBe 3

      it 'Split records w/ sorting', ->
        list = new List 'id'
        list.push {id: 1, start: 30, end: 50}, {id: 2, start: 7, end: 8},
                  {id: 3, start: 19, end: 41}

        sorter = (a, b) ->
          if a.start > b.start then 1 else -1

        sublist = new ListMask list, {splitter, sorter}
        expect(sublist.length).toBe 6
        expect(sublist[5].start).toBe 40
        expect(sublist[5].end).toBe 50

        list.pop()
        expect(sublist.length).toBe 3

        expect(sublist[2].id).toBe 1
        sublist[1].id = null
        expect(sublist.length).toBe 3
        expect(sublist[2].id).toBe null
        expect(sublist[2]._original).toBe sublist.pseudoMap[1]
        expect(sublist[2]._original).toBe list[0]

      it 'Changing splitter fn triggers reprocessing', ->
        list = new List
        list.push {id: 1, start: 30, end: 50}, {id: 2, start: 7, end: 8},
                  {id: 3, start: 20, end: 41}

        sublist = new ListMask list, {splitter}

        sublist.splitter = null # sets to no splitting
        expect(sublist.length).toBe 3

        sublist.splitter = splitter # back to splitting
        expect(sublist.length).toBe 6

      it 'Throws error if splitter fn returns array with non-object values', ->
        list = new List
        list.push {id: 1, start: 30, end: 50}

        splitter = ->
          ['a', {x: 1}]

        expect(-> sublist = new ListMask list, {splitter}).toThrow()

      it 'Throws error if splitter fn is truthy but not a fn', ->
        splitter = 1
        expect(-> sublist = new ListMask list, {splitter}).toThrow()

        sublist = new ListMask list
        expect(-> sublist.splitter = splitter).toThrow()

    it 'Filter is optional', ->
      list = new List
      list.push {id: 1, a: 'xyz', b: 'a'}, {id: 2, a: 'abc', b: 'b'},
                {id: null, a: 'aaa', b: 'c'}
      expect(-> sublist = new ListMask list).not.toThrow()
      expect(sublist.length).toBe 3

      expect(-> sublist = new ListMask list, {xopt: 1}).not.toThrow()
      expect(sublist.length).toBe 3

    it 'Filter function can be neutralized', ->
      expect(sublist.length).toBe 1
      sublist.filter = false
      expect(sublist.length).toBe 2

    it 'Filters immediately when created', ->
      list = new List sorter: 'b'
      list.push {id: 1, a: 'xyz', b: 'a'}, {id: 2, a: 'abc', b: 'b'},
                {id: null, a: 'aaa', b: 'c'}

      sublist = new ListMask list, filter_fn

      expect(sublist.length).toBe 2
      expect(sublist[0].id).toBe 2
      expect(sublist[1].id).toBe null

    it 'Uses its own sorter for initial load', ->
      list = new List
      list.push {id: 1, a: 'xyz'}, {id: 2, a: 'abc'}, {id: null, a: 'aaa'}

      sublist = new ListMask list, filter_fn, sorter: 'a'

      expect(sublist.length).toBe 2
      expect(sublist[0].a).toBe 'aaa'
      expect(sublist[1].a).toBe 'abc'

    it 'Keeps parent list sort', ->
      list = new List sorter: 'a'
      sublist = new ListMask list, filter_fn

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
      sublist = new ListMask list, filter_fn, sorter: 'a'

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

      expect(sublist.destroy()).toBe false

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
      expect(-> new ListMask [], (->)).toThrow()
      expect(-> new ListMask list, true).toThrow()
      expect(-> new ListMask list, (->), true).toThrow()
      expect(-> new ListMask list, (->), {}, {}).toThrow()

    it '$scope unsubscriber, method .destroy()', ->
      scope = $rootScope.$new()

      sublist = new ListMask list, (->), scope
      scope.$emit '$destroy'
      expect(sublist.destroy()).toBe false # already destroyed

      sublist = new ListMask list, (->), {}, scope
      scope.$emit '$destroy'
      expect(sublist.destroy()).toBe false # already destroyed

      sublist = new ListMask list, (->), scope
      called = false
      old_fn = sublist._scopeUnsubscriber
      Object.defineProperty sublist, '_scopeUnsubscriber', writable: true
      Object.defineProperty sublist, '_scopeUnsubscriber',
        value: ->
          called = true
          old_fn()
      sublist.destroy()
      expect(called).toBe true

      sublist = new ListMask list, (->)
      list.destroy()
      expect(sublist.destroy()).toBe false

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

            it 'Parent list move: idMap -> idMap', ->
              list.idMap[2].id = 9

              expect(action.update.length).toBe 1
              move_info = {from: {idMap: 2}, to: {idMap: 9}}
              expect(action.update[0].move).toEqual move_info
              expect(action.update[0].record).toBe sublist[0]
              expect(sublist.idMap[2]).toBeUndefined()
              expect(sublist.idMap[9]).toBe list[1]

            it 'Parent list move: idMap -> pseudoMap', ->
              list.idMap[2].id = null

              expect(action.update.length).toBe 1
              move_info = {from: {idMap: 2}, to: pseudoMap: sublist[0]._pseudo}
              expect(action.update[0].move).toEqual move_info
              expect(action.update[0].record).toBe sublist[0]
              expect(sublist.idMap[2]).toBeUndefined()
              expect(sublist.pseudoMap[sublist[0]._pseudo]).toBe list[1]

            it 'Parent list move: pseudoMap -> idMap', ->
              list[1].id = null
              orig_pseudo = list[1]._pseudo
              list[1].id = 9

              expect(action.update.length).toBe 1
              move_info = {from: {pseudoMap: orig_pseudo}, to: {idMap: 9}}
              expect(action.update[0].move).toEqual move_info
              expect(action.update[0].record).toBe sublist[0]
              expect(sublist.pseudoMap[orig_pseudo]).toBeUndefined()
              expect(sublist.idMap[9]).toBe list[1]

          describe 'Was NOT on sublist', ->

            it 'Parent list move: idMap -> idMap', ->
              list[1]._replace {id: 2, a: 'x'} # removes from sublist
              expect(sublist.length).toBe 0

              list[1]._replace {id: 9, a: 'aaa'}

              expect(action.add.length).toBe 1
              expect(sublist.length).toBe 1
              expect(sublist.idMap[9]).toBe list[1]

            it 'Parent list move: idMap -> pseudoMap', ->
              list[1]._replace {id: 2, a: 'x'} # removes from sublist
              expect(sublist.length).toBe 0

              list[1]._replace {id: null, a: 'aaa'}

              expect(action.add.length).toBe 1
              expect(sublist.length).toBe 1
              expect(sublist.pseudoMap[list[1]._pseudo]).toBe list[1]

            it 'Parent list move: pseudoMap -> idMap', ->
              list[1]._replace {id: null, a: 'x'} # removes from sublist
              expect(sublist.length).toBe 0

              list[1]._replace {id: 9, a: 'aaa'}

              expect(action.add.length).toBe 1
              expect(sublist.length).toBe 1
              expect(sublist.idMap[9]).toBe list[1]

        describe 'Does NOT meet filter', ->

          it 'Was on sublist idMap', ->
            list[1]._replace {id: 2, a: 'y'}

            expect(action.cut.length).toBe 1
            expect(sublist.length).toBe 0
            expect(sublist.idMap[2]).toBeUndefined()

          it 'Was on sublist pseudoMap', ->
            list[1].id = null
            action = null

            list[1]._replace {id: 9, a: 'y'}

            expect(action.cut.length).toBe 1
            expect(sublist.length).toBe 0
            expect(sublist.idMap[2]).toBeUndefined()

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
          merge_info = {from: {pseudoMap: orig_pseudo}, to: {idMap: 2}}
          expect(action.update[0].merge).toEqual merge_info
          expect(sublist.length).toBe 1
          expect(sublist.idMap[2].a).toBe 'aaa'

        it 'Should cut both source and target from sublist (on idMap)', ->
          list.push {id: 9, a: 'axa'}
          expect(sublist.length).toBe 2

          list[1]._replace {id: 9, a: 'eeee'}
          expect(action.cut.length).toBe 2
          expect(sublist.length).toBe 0

    describe 'Multiple sources', ->

      it 'Error if trying to mix unnamed and named', ->
        expect(-> new ListMask {_: list, l2: list2}, filter_fn).toThrow()

      it 'Takes multiple sources, names .idMap and .pseudoMap', ->
        sublist = new ListMask {l1: list, l2: list2}, filter_fn
        expect(sublist.length).toBe 2
        expect(sublist.idMap.l1[2]).toBe list[1]
        expect(sublist.idMap.l2[22]).toBe list2[1]
        expect(sublist.pseudoMap.l1).toEqual {}
        expect(sublist.pseudoMap.l2).toEqual {}

      it 'Update scenarios: add, remove by rename, move to pseudoMap', ->
        sublist = new ListMask {l1: list, l2: list2}, filter_fn
        list.push {id: 9, a: 'axa'}
        expect(sublist.length).toBe 3
        expect(sublist.idMap.l1[9]).toBe list[2]

        list[2].a = 'eee'
        expect(sublist.length).toBe 2
        expect(sublist.idMap.l1[9]).toBeUndefined()

        list[1].id = null
        expect(sublist.length).toBe 2
        expect(sublist.idMap.l1[2]).toBeUndefined()
        expect(sublist.pseudoMap.l1[1]).toBe list[1]

      it 'Chained ListMasks with multiple sources', ->
        list3 = new List 'id3'
        list3.push {id3: 1, a: 'xyz'}, {id3: 2, a: 'abc'}

        sublist1 = new ListMask {l1: list, l2: list2}, filter_fn

        sublist2 = new ListMask {sub: sublist1, ls: list3}, filter_fn
        expect(sublist2.length).toBe 3

        list.push {id: 9, a: 'axa'}, {id: 10, a: 'fsdf'}

        list3.push {id3: 11, a: 'aya'}
        expect(sublist2.idMap.ls[2]).toBe list3[1]
        expect(sublist2.idMap.ls[11]).toBe list3[2]
        expect(sublist2.length).toBe 5

        list3[2].a = 'eee'
        expect(sublist2.idMap.ls[11]).toBeUndefined()

        expect(sublist2.idMap.sub.l2[22]).toBe list2[1]
        list2.idMap[22].a = 'eee'
        expect(sublist2.idMap.sub.l2[22]).toBeUndefined()

      it 'Should not allow double-referencing list sources', ->
        refs = {l0: list, l1: list2, l2: list2}
        expect(-> new ListMask refs, filter_fn).toThrow()

    it 'Without mapped sourc(es)', ->
      list     = new List [{id: 1, a: 'xyz'}, {id: 2, a: 'abc'}]
      sublist  = new ListMask list, filter_fn
      sublist2 = new ListMask {ls1: sublist}, filter_fn

      expect(list.idMap).toBeUndefined()
      expect(sublist.idMap).toBeUndefined()
      expect(sublist2.idMap).toBeUndefined()
      expect(list.length).toBe 2
      expect(sublist.length).toBe 1
      expect(sublist2.length).toBe 1
      expect(sublist[0].id).toBe 2

      list.pop()
      expect(sublist.length).toBe 0
      expect(sublist2.length).toBe 0

      sublist.filter = sublist2.filter = (-> true)
      expect(sublist.length).toBe 1
      expect(sublist2.length).toBe 1
      expect(sublist[0].id).toBe 1

      sublist.filter = sublist2.filter = (-> false)
      expect(sublist.length).toBe 0
      expect(sublist2.length).toBe 0
