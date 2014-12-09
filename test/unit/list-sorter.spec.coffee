
describe 'app.factory', ->

  describe 'ListSorter', ->

    List = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        List = $injector.get 'ksc.List'


    it 'Function', ->
      list = new List
        record: idProperty: 'id'
        sorter: (a, b) ->
          if a._id >= b._id then 1 else -1

      list.push {id: 2}, {id: 1}, {id: 3}, {id: 4}

      expect(list[0]._id).toBe 1
      expect(list[1]._id).toBe 2
      expect(list[2]._id).toBe 3
      expect(list[3]._id).toBe 4

    it 'String', ->
      list = new List {record: {idProperty: 'id'}, sorter: '_id'}

      list.push {id: 2}, {id: 1}, {id: 3}, {id: 4}

      expect(list[0]._id).toBe 1
      expect(list[1]._id).toBe 2
      expect(list[2]._id).toBe 3
      expect(list[3]._id).toBe 4

    it 'Array of keys', ->
      list = new List {record: {idProperty: 'id'}, sorter: ['x', 'y']}

      list.unshift {id: 1, x: 'a', y: 'b'}, {id: 2, x: 'b', y: 'b'},
                    {id: 3, x: 'b'}, {id: 4, x: 'a', y: 'a'}

      expect(list[0]._id).toBe 4
      expect(list[1]._id).toBe 1
      expect(list[2]._id).toBe 3
      expect(list[3]._id).toBe 2

    it 'Number sort', ->
      list = new List 'id',
        sorter:
          key:  'x'
          type: 'number'

      list.push {id: 1, x: -43}, {id: 8, x: ''}, {id: 2, x: 7},
                {id: 3, x: 7.1}, {id: 4, x: 10}, {id: 5, x: 0},
                {id: 6, x: null}, {id: 7, x: ''}, {id: 9, x: 'aaa'}

      expect(list[2].x).toBe 'aaa'
      expect(list[0].x).toBe ''
      expect(list[1].x).toBe ''
      expect(list[3].x).toBe null
      expect(list[4].x).toBe -43
      expect(list[5].x).toBe 0
      expect(list[6].x).toBe 7
      expect(list[7].x).toBe 7.1
      expect(list[8].x).toBe 10

    it 'Numbers in natural sort (identical to number)', ->
      list = new List {record: {idProperty: 'id'}, sorter: 'x'}

      list.push {id: 1, x: -43}, {id: 2, x: 7}, {id: 3, x: 7.1},
                {id: 4, x: 10}, {id: 5, x: 0},

      expect(list[0].x).toBe -43
      expect(list[1].x).toBe 0
      expect(list[2].x).toBe 7
      expect(list[3].x).toBe 7.1
      expect(list[4].x).toBe 10

    it 'Byte sort', ->
      list = new List
        record: idProperty: 'id'
        sorter:
          key:  'id'
          type: 'byte'

      list.push {id: 'aaaa'}, {id: ' '}, {id: 'AA'}, {id: 'x'}, {id: '123'}

      expect(list[0]._id).toBe ' '
      expect(list[1]._id).toBe '123'
      expect(list[2]._id).toBe 'AA'
      expect(list[3]._id).toBe 'aaaa'
      expect(list[4]._id).toBe 'x'

    it 'Byte sort w/ reverse: true', ->
      list = new List
        record: idProperty: 'id'
        sorter:
          key:  'id'
          type: 'byte'
          reverse: true

      list.push {id: 'a'}, {id: ' '}, {id: 'A'}, {id: 'x'}, {id: '1'}

      expect(list[0]._id).toBe 'x'
      expect(list[1]._id).toBe 'a'
      expect(list[2]._id).toBe 'A'
      expect(list[3]._id).toBe '1'
      expect(list[4]._id).toBe ' '

    it 'Identical records are first-come-first-served', ->
      list = new List {record: {idProperty: 'id'}, sorter: 'x'}

      list.push {id: 1, x: 'b'}, {id: 2, x: 'b'}, {id: 3, x: 'aa'},
                {id: 4, x: 'aa'}, {id: 5, x: 'b'}, {id: 6, x: 'ccc'},
                {id: 7}, {id: 8}, {id: 9, x: 'cx'}

      expect(list[0]._id).toBe 7
      expect(list[1]._id).toBe 8
      expect(list[2]._id).toBe 3
      expect(list[3]._id).toBe 4
      expect(list[4]._id).toBe 1
      expect(list[5]._id).toBe 2
      expect(list[6]._id).toBe 5
      expect(list[7]._id).toBe 6
      expect(list[8]._id).toBe 9

    it 'Byte-sort w/ identicals', ->
      list = new List
        record: idProperty: 'id'
        sorter:
          key:  'x'
          type: 'byte'

      list.push {id: 1, x: 1}, {id: 2, x: 3}, {id: 3, x: 2}, {id: 4, x: 3}

      expect(list[0].x).toBe 1
      expect(list[1].x).toBe 2
      expect(list[2].x).toBe 3
      expect(list[3].x).toBe 3

    it 'Natural sort variation', ->
      list = new List {record: {idProperty: 'id'}, sorter: 'x'}

      list.push {id: 1, x: 'a1a12a'}, {id: 2, x: 'aa'}, {id: 5, x: false},
                {id: 3, x: 'aaaa'}, {id: 6, x: true}, {id: 4, x: 'a1a12a'},
                {id: 7, x: 'a1a12a'}

      expect(list[0].id).toBe 1
      expect(list[1].id).toBe 4
      expect(list[2].id).toBe 7
      expect(list[3].id).toBe 2
      expect(list[4].id).toBe 3
      expect(list[5].id).toBe 5
      expect(list[6].id).toBe 6

    it 'Update sorter (automatic re-sorting)', ->
      list = new List {record: {idProperty: 'id'}, sorter: 'id'}

      list.push {id: 1, x: 'c'}, {id: 3, x: 'b'}, {id: 2, x: 'a'}
      list.sorter = 'x'
      expect(list[0].id).toBe 2
      expect(list[1].id).toBe 3
      expect(list[2].id).toBe 1

    it 'Pull sorter', ->
      list = new List {record: {idProperty: 'id'}, sorter: 'id'}

      list.push {id: 1, x: 'c'}, {id: 3, x: 'b'}, {id: 2, x: 'a'}
      list.sorter = false
      expect(list.sorter).toBe null
      # does not re-sort if sorter is pulled
      expect(list[0].id).toBe 1
      expect(list[1].id).toBe 2
      expect(list[2].id).toBe 3


    describe 'Edge cases', ->

      it 'Sort function returns non-numeric data', ->
        list = new List {record: {idProperty: 'id'}, sorter: -> 'a'}
        expect(-> list.push {id: 1}, {id: 2}).toThrow()

      it 'sorter type is bugous', ->
        list = new List
        expect(-> list.sorter = true).toThrow()

      it 'sorter.key type is bugous', ->
        list = new List
        expect(-> list.sorter = {key: true}).toThrow()

      it 'sorter.type value is bugous', ->
        list = new List
        expect(-> list.sorter = {key: 'id', type: 'wtf'}).toThrow()

      it 'sorter.reverse is cast to boolean', ->
        list = new List sorter: {key: 'a', reverse: 1}
        expect(list.sorter.reverse).toBe true
        list = new List sorter: {key: 'a', reverse: ''}
        expect(list.sorter.reverse).toBe false
