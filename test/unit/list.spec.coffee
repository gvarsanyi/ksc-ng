
describe 'app.factory', ->

  describe 'List', ->

    $rootScope = EditableRecord = List = Record = util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        $rootScope     = $injector.get '$rootScope'
        EditableRecord = $injector.get 'ksc.EditableRecord'
        List           = $injector.get 'ksc.List'
        Record         = $injector.get 'ksc.Record'
        util           = $injector.get 'ksc.util'

    it 'Constructs a vanilla Array instance', ->
      list = new List

      expect(Array.isArray list).toBe true
      expect(list.length).toBe 0

    it 'Extendible as class', ->
      class X extends List
        a: 'a'

      list = new X
      expect(Array.isArray list).toBe true
      expect(list.a).toBe 'a'

    it 'Overrides pop, push, shift, unshift, splice, reverse & sort methods', ->
      list = new List

      expect(list.pop).not.toBe Array::pop
      expect(list.push).not.toBe Array::push
      expect(list.shift).not.toBe Array::shift
      expect(list.unshift).not.toBe Array::unshift
      expect(list.splice).not.toBe Array::splice
      expect(list.sort).not.toBe Array::sort
      expect(list.reverse).not.toBe Array::reverse

    it 'Should not take non-object elements', ->
      list = new List
      expect(-> list.push 'x').toThrow()

    it 'Add/remove (push, unshift, pop, shift, length)', ->
      list = new List
      list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}
      len = list.unshift {id: 3, x: 'c'}, {id: 4, x: 'd'}

      expect(-> list.push true).toThrow() # no item argument passed

      expect(len).toBe 4
      expect(list.length).toBe 4
      expect(list.pop().id).toBe 2
      expect(list.shift().id).toBe 3
      expect(list.length).toBe 2
      expect(list.map[1].x).toBe 'a'
      list.pop()
      list.pop()
      expect(list.pop()).toBeUndefined()

    it 'Methods push/unshift on sorted list (insert to sorted position)', ->
      list = new List
      list.push {id: 8}, {id: 2}, {id: 5}
      list.sorter = 'id'
      expect(list[0].id).toBe 2
      expect(list[1].id).toBe 5
      expect(list[2].id).toBe 8
      list.push {id: 3}, {id: 1}
      expect(list[0].id).toBe 1
      expect(list[1].id).toBe 2
      expect(list[2].id).toBe 3
      expect(list[3].id).toBe 5
      expect(list[4].id).toBe 8
      res = list.unshift {id: 6}, {id: 0}, true
      expect(res.add.length).toBe 2
      expect(list[0].id).toBe 0
      expect(list[1].id).toBe 1
      expect(list[2].id).toBe 2
      expect(list[3].id).toBe 3
      expect(list[4].id).toBe 5
      expect(list[5].id).toBe 6
      expect(list[6].id).toBe 8

    it 'Record updates effect sort order in sorted lists', ->
      list = new List sorter: 'a'
      list.push {id: 1, a: 'a'}, {id: 2, a: 'f'}, {id: 3, a: 'z'}
      expect(list.map[3]).toBe list[2]
      list.map[3].a = 'b'
      expect(list.map[3]).toBe list[1]

    it 'Method .reverse()', ->
      list = new List
      list.push {id: 1}

      called = null
      list.events.on 'update', (info) ->
        called = info.action

      list.reverse()
      expect(called).toBe null

      list.push {id: 2}
      called = null

      list.reverse()
      expect(list[0].id).toBe 2
      expect(list.length).toBe 2
      expect(called.reverse).toBe true

      list.sorter = 'id'
      expect(-> list.reverse()).toThrow() # can't sort auto-sorted list

    describe 'Method .sort()', ->

      it 'default sort', ->
        list = new List
        list.push {id: 2, x: 'c'}, {id: 1, x: 'b'}, {id: null, x: 'a'},
                  {id: null, x: 'd'}
        list.sort()
        expect(list[0].x).toBe 'a'
        expect(list[1].x).toBe 'd'
        expect(list[2].x).toBe 'b'
        expect(list[3].x).toBe 'c'

        list = new List
        list.push {id: null, x: 'c'}, {id: 1, x: 'b'}, {id: null, x: 'a'},
                  {id: null, x: 'd'}, {id: 2, x: 'b'}, {id: null, x: 'c'}
        list.sort()
        expect(list[0].id).toBe null
        expect(list[3].id).toBe null
        expect(list[4].id).toBe 1

      it 'sort by a function', ->
        list = new List
        list.push {id: 2, x: 'c'}, {id: 1, x: 'b'}, {id: null, x: 'a'},
                  {id: null, x: 'd'}
        list.sort (a, b) ->
          if a.x > b.x
            return 1
          -1
        expect(list[0].x).toBe 'a'
        expect(list[1].x).toBe 'b'
        expect(list[2].x).toBe 'c'
        expect(list[3].x).toBe 'd'

      it 'Can not resort auto-sorted list', ->
        list = new List sorter: 'id'
        list.push {id: 2, x: 'c'}, {id: 1, x: 'b'}
        expect(-> list.sort()).toThrow()

      it 'Does not emit event if nothing changed', ->
        list = new List
        called = null
        list.events.on 'update', (info) ->
          called = info.action

        list.sort()
        expect(called).toBe null

        list.push {id: 1, x: 'c'}
        called = null
        list.sort()
        expect(called).toBe null

        list.push {id: 3, x: 'a'}
        called = null
        list.sort()
        expect(called).toBe null

        list.push {id: 2, x: 'a'}
        list.sort()
        expect(called.sort).toBe true

    it 'Upsert', ->
      list = new List
      list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'}

      len = list.unshift {id: 1, x: 'x'}

      expect(len).toBe 3
      expect(list.length).toBe 3
      expect(list.map[1].x).toBe 'x'

      affected = list.push {id: 1, x: 'y'}, {id: 4, x: 'e'},
                           {id: 2, x: 'y'}, true

      expect(affected.add.length).toBe 1
      expect(affected.update.length).toBe 2
      expect(list.map[1].x).toBe 'y'
      expect(list.map[2].x).toBe 'y'

    it 'Upsert Record instances', ->
      record1 = new Record {id: 2, x: 'x'}
      record2 = new EditableRecord {id: 4, x: 'y'}

      list = new List {record: {class: EditableRecord}}
      res = list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'},
                      record1, record2, true

      expect(list.map[2].x).toBe 'x'
      expect(list.map[4].x).toBe 'y'
      expect(list.map[4] instanceof EditableRecord).toBe true

    it 'Constructor argument type checks', ->
      expect(-> new List true).toThrow()
      expect(-> new List {}, {}).toThrow()

    it '$scope unsubscriber, method .destroy()', ->
      scope = $rootScope.$new()

      sublist = new List scope
      scope.$emit '$destroy'
      expect(sublist.destroy()).toBe false # already destroyed

      sublist = new List {}, scope
      scope.$emit '$destroy'
      expect(sublist.destroy()).toBe false # already destroyed

      sublist = new List {}, scope
      called = false
      old_fn = sublist._scopeUnsubscriber
      Object.defineProperty sublist, '_scopeUnsubscriber', writable: true
      Object.defineProperty sublist, '_scopeUnsubscriber',
        value: ->
          called = true
          old_fn()
      sublist.destroy()
      expect(called).toBe true

    it 'Method .splice()', ->
      list = new List
      list.push {id: 0}, {id: 10}, {id: 20}
      action = null
      list.events.on 'update', (info) ->
        action = info.action

      to_be_cut = list[1]

      list.splice 1, 1, {id: 5}, {id: 6}

      expect(list.length).toBe 4
      expect(list[0].id).toBe 0
      expect(list[1].id).toBe 5
      expect(list[2].id).toBe 6
      expect(list[3].id).toBe 20
      expect(action.cut.length).toBe 1
      expect(action.cut[0]).toBe to_be_cut
      expect(action.add.length).toBe 2
      expect(action.add[0]).toBe list[1]
      expect(action.add[1]).toBe list[2]

    describe 'Method .splice() edge cases', ->

      it 'on sorted list', ->
        list = new List sorter: 'id'
        list.push {id: 10}, {id: 0}, {id: 20}
        list.splice 1, 1, {id: -2}, {id: 6}
        expect(list[0]._id).toBe -2
        expect(list[1]._id).toBe 0
        expect(list[2]._id).toBe 6
        expect(list[3]._id).toBe 20
        expect(list.length).toBe 4

      it 'upsert', ->
        list = new List
        list.push {id: 0, a: 'a'}, {id: 10, a: 'b'}, {id: 20, a: 'c'}
        res = list.splice 2, 0, {id: 0, a: 'z'}, true
        expect(res.add).toBeUndefined()
        expect(res.cut).toBeUndefined()
        expect(res.update.length).toBe 1
        expect(list.length).toBe 3
        expect(list[0].a).toBe 'z'

      it 'nothing to do', ->
        list = new List
        list.push {id: 0, a: 'a'}, {id: 10, a: 'b'}, {id: 20, a: 'c'}
        res = list.splice 4, true
        expect(res.add).toBeUndefined()
        expect(res.cut).toBeUndefined()
        expect(res.update).toBeUndefined()
        expect(list.length).toBe 3

      it 'negative pos on empty list', ->
        list = new List
        action = null
        list.events.on 'update', (info) ->
          action = info.action
        list.splice -1, 1, {id: 10}
        expect(action.add.length).toBe 1
        expect(action.add[0]).toBe list[0]

      it 'missing count', ->
        list = new List
        list.push {id: 0}, {id: 10}, {id: 20}
        to_be_cut = list[2]
        action = null
        list.events.on 'update', (info) ->
          action = info.action
        list.splice -1
        expect(list.length).toBe 2
        expect(action.cut.length).toBe 1
        expect(action.cut[0]).toBe to_be_cut

      it 'error handling', ->
        list = new List
        expect(-> list.splice NaN).toThrow()
        expect(-> list.splice {}).toThrow()
        expect(-> list.splice true).toThrow()
        expect(-> list.splice 'a').toThrow()
        expect(-> list.splice '').toThrow()
        expect(-> list.splice false).toThrow()
        expect(-> list.splice null).toThrow()
        expect(-> list.splice .4).toThrow()
        expect(-> list.splice 0, -1).toThrow()
        expect(-> list.splice 0, {}).toThrow()
        expect(-> list.splice 0, true).not.toThrow()

    it 'Method .cut(records...)', ->
      list = new List
      list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'},
                {id: 4, x: 'd'}

      res = list.cut 3, list.map[2]

      expect(res.cut.length).toBe 2
      expect(res.cut[0].x).toBe 'c'
      expect(list.length).toBe 2
      expect(list.map[2]).toBeUndefined()
      expect(list.map[3]).toBeUndefined()
      expect(list[1].x).toBe 'd'

      expect(-> list.cut 32).toThrow() # no such id
      expect(-> list.cut()).toThrow() # no record argument provided

    describe 'Method .cut(records...) edge cases', ->

      it 'Not in the map (id)', ->
        list = new List
        expect(-> list.cut 2).toThrow()

      it 'Not in the map (record)', ->
        list = new List
        record = new EditableRecord {id: 2}
        expect(-> list.cut record).toThrow()

      it 'Not in the map (tempered record._id)', ->
        list = new List
        list.push {id: 1}
        util.defineValue list[0], '_id', 11
        expect(-> list.cut list[0]).toThrow()

      it 'Not in the pseudo map (tempered record._pseudo)', ->
        list = new List
        list.push {id: 1}
        util.defineValue list[0], '_pseudo', 11
        expect(-> list.cut list[0]).toThrow()

    it 'Method .empty()', ->
      list = new List
      list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'},
                {id: 4, x: 'd'}
      res = list.empty()

      expect(res.length).toBe 0
      expect(res).toBe list

      expect(-> list.empty()).not.toThrow()

    it 'Method .empty(true) # returns action object', ->
      list = new List
      list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}
      rec1 = list[0]
      rec2 = list[1]

      res = list.empty true
      expect(res.cut.length).toBe 2
      expect(res.cut[0]).toBe rec1
      expect(res.cut[1]).toBe rec2

    describe 'New/pseudo record storage', ->

      it 'Record storage', ->
        list = new List record: idProperty: 'id'
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        list.push {x: 'c'}

        expect(list.pseudo[1].x).toBe 'c'
        expect(list.pseudo[1]).toBe list[2]

        list.push {id: null, x: 'd'}

        expect(list.pseudo[1].x).toBe 'c'
        expect(list.pseudo[2].x).toBe 'd'
        expect(list.pseudo[2]).toBe list[3]

      it 'Moving pseudo record to map', ->
        list = new List record: idProperty: 'id'
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: null, x: 'c'},
                  {id: null, x: 'd'}

        list[2].id = 3

        expect(list.pseudo[1]).toBeUndefined()
        expect(list.map[3]).toBe list[2]

        list[3].id = 1 # merge
        expect(list.length).toBe 3
        expect(list.pseudo[2]).toBeUndefined()
        expect(list.map[1].x).toBe 'd'

      it 'Moving mapped record to pseudo', ->
        list = new List record: idProperty: 'id'
        list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}

        list[1].id = null

        expect(list[1]._pseudo).toBe 1
        expect(list.pseudo[1]).toBe list[1]
        expect(list.map[2]).toBeUndefined()

      it 'Remove pseudo element', ->
        list = new List record: idProperty: 'id'
        list.push {id: null, x: 'a'}, {id: 2, x: 'b'}
        list.shift()
        expect(list.length).toBe 1
        expect(list.pseudo[1]).toBeUndefined()

    it 'Records may only have 1 or 0 list parents', ->
      list1  = new List record: idProperty: 'id'
      list2  = new List record: idProperty: 'id'
      record = new EditableRecord {id: 1, a: 'abc'}
      expect(list1.length).toBe 0

      list1.push record
      expect(list1.length).toBe 1
      expect(list1[0]).toBe record

      list2.push record
      expect(list1.length).toBe 0
      expect(list1[0]).toBeUndefined()
      expect(list2.length).toBe 1
      expect(list2[0]).toBe record
