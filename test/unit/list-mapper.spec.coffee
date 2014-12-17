
describe 'app.factory', ->

  describe 'ListMapper', ->

    List = ListMapper = ListMask = null
    list = list2 = list3 = sublist = sublist2 = sublist3 = null
    property_desc = Object.getOwnPropertyDescriptor

    beforeEach ->
      module 'app'
      inject ($injector) ->
        $rootScope = $injector.get '$rootScope'
        List       = $injector.get 'ksc.List'
        ListMapper = $injector.get 'ksc.ListMapper'
        ListMask   = $injector.get 'ksc.ListMask'

        list = new List 'id'
        list.push {id: 1, a: 'xyz'}, {id: null, a: 'abc'}

        list2 = new List 'id2'
        list2.push {id2: 1, a: 'xyz'}, {id2: 2, a: 'abc'}

        list3 = new List 'id3'
        list3.push {id3: 1, a: 'xyz'}, {id3: 2, a: 'abc'}

        sublist  = new ListMask list, (-> true)
        sublist2 = new ListMask {list1: list, list2}, (-> true)
        sublist3 = new ListMask {sub: sublist2, list3}, (-> true)


    it 'Creates ._mapper, .idMap and .pseudoMap', ->
      expect(sublist._mapper instanceof ListMapper).toBe true
      expect(typeof sublist.idMap).toBe 'object'
      expect(typeof sublist.pseudoMap).toBe 'object'

    it 'Multi-level .idMap and .pseudoMap', ->
      expect(sublist2.idMap.list1[1]).toBe list[0]
      expect(sublist2.idMap.list2[2]).toBe list2[1]
      expect(sublist3.idMap.sub.list2[2]).toBe list2[1]
      expect(sublist3.pseudoMap.sub.list1[1]).toBe list[1]
      expect(sublist3.idMap.list3[2]).toBe list3[1]

      list3.pop()
      expect(sublist3.idMap.list3[2]).toBeUndefined()

      list.pop()
      expect(sublist3.pseudoMap.sub.list1[1]).toBeUndefined()

    describe 'Getterified', ->

      it '.idMap assignment (list.idMap[x] = {}) uses ._replace()', ->

        list = new List 'id', [{id: 1, a: 1}, {id: 2, a: 2}]
        record = list.idMap[2]
        expect(list.idMap[3]).toBeUndefined()
        expect(property_desc(list.idMap, 1).get?).toBe true
        expect(list[1]).toBe record
        list.idMap[2] = {id: 3, a: 3}

        expect(list.idMap[3]).toBe record
        expect(list.idMap[2]).toBeUndefined()
        expect(list[1]).toBe record
        expect(record.a).toBe 3

      it '.pseudoMap assignment (list.pseudoMap[x] = {}) uses ._replace()', ->

        list = new List 'id', [{id: 1, a: 1}, {id: null, a: 2}]
        expect(list.idMap[3]).toBeUndefined()
        for key of list.pseudoMap # gets pseudo_id
          pseudo_id = key
          break
        record = list.pseudoMap[pseudo_id]
        expect(property_desc(list.pseudoMap, pseudo_id).get?).toBe true
        expect(list[1]).toBe record
        list.pseudoMap[pseudo_id] = {id: 3, a: 3}

        expect(list.idMap[3]).toBe record
        expect(list.pseudoMap[pseudo_id]).toBeUndefined()
        expect(list[1]).toBe record
        expect(record.a).toBe 3
