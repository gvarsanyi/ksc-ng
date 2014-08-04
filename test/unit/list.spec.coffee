
describe 'app.factory', ->

  describe 'List', ->

    EditableRecord = List = Record = utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        EditableRecord = $injector.get 'ksc.EditableRecord'
        List           = $injector.get 'ksc.List'
        Record         = $injector.get 'ksc.Record'
        utils          = $injector.get 'ksc.utils'

    it 'Constructs a vanilla Array instance', ->
      list = new List

      expect(Array.isArray list).toBe true
      expect(list.length).toBe 0

    it 'Overrides pop, push, shift & unshift methods, keeps default sort', ->
      list = new List

      expect(list.pop).not.toBe Array::pop
      expect(list.push).not.toBe Array::push
      expect(list.shift).not.toBe Array::shift
      expect(list.unshift).not.toBe Array::unshift
      expect(list.sort).toBe Array::sort

    it 'Should not take non-object elements', ->
      list = new List
      expect(-> list.push 'x').toThrow()

    it 'Add/remove (push, unshift, pop, shift, length)', ->
      list = new List
      list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}
      len = list.unshift {id: 3, x: 'c'}, {id: 4, x: 'd'}

      expect(-> list.push()).toThrow() # no argument passed
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
      list.unshift {id: 6}, {id: 0}
      expect(list[0].id).toBe 0
      expect(list[1].id).toBe 1
      expect(list[2].id).toBe 2
      expect(list[3].id).toBe 3
      expect(list[4].id).toBe 5
      expect(list[5].id).toBe 6
      expect(list[6].id).toBe 8

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
      expect(affected.upsert.length).toBe 2
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
        utils.defineValue list[0], '_id', 11
        expect(-> list.cut list[0]).toThrow()

      it 'Not in the pseudo map (tempered record._pseudo)', ->
        list = new List
        list.push {id: 1}
        utils.defineValue list[0], '_pseudo', 11
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

        expect(list._pseudoCount).toBe 0

        list.push {x: 'c'}

        expect(list._pseudoCount).toBe 1
        expect(list.pseudo[1].x).toBe 'c'
        expect(list.pseudo[1]).toBe list[2]

        list.push {id: null, x: 'd'}

        expect(list._pseudoCount).toBe 2
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
        expect(list._pseudoCount).toBe 1
