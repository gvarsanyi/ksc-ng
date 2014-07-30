
describe 'app.factory', ->

  describe 'List', ->

    EditableRecord = List = Record = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        EditableRecord = $injector.get 'ksc.EditableRecord'
        List           = $injector.get 'ksc.List'
        Record         = $injector.get 'ksc.Record'

    it 'Constructs a vanilla Array instance', ->
      list = new List

      expect(Array.isArray list).toBe true
      expect(list.length).toBe 0

    it 'option.class is ksc.List', ->
      list = new List

      expect(list.options.class).toBe List.prototype

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

    it 'Upsert', ->
      list = new List
      list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'}

      len = list.unshift {id: 1, x: 'x'}

      expect(len).toBe 3
      expect(list.length).toBe 3
      expect(list.map[1].x).toBe 'x'

      affected = list.push {id: 1, x: 'y'}, {id: 4, x: 'e'},
                           {id: 2, x: 'y'}, true

      expect(affected.insert.length).toBe 1
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

    it 'Method .empty()', ->
      list = new List
      list.push {id: 1, x: 'a'}, {id: 2, x: 'b'}, {id: 3, x: 'c'},
                {id: 4, x: 'd'}
      res = list.empty()

      expect(res.length).toBe 0
      expect(res).toBe list

      expect(-> list.empty()).not.toThrow()
