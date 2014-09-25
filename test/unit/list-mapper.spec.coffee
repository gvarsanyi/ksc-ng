
describe 'app.factory', ->

  describe 'ListMapper', ->

    List = ListMapper = ListMask = null
    list = list2 = list3 = sublist = sublist2 = sublist3 = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        $rootScope = $injector.get '$rootScope'
        List       = $injector.get 'ksc.List'
        ListMapper = $injector.get 'ksc.ListMapper'
        ListMask   = $injector.get 'ksc.ListMask'

        list = new List
        list.push {id: 1, a: 'xyz'}, {id: null, a: 'abc'}

        list2 = new List
        list2.push {id2: 1, a: 'xyz'}, {id2: 2, a: 'abc'}

        list3 = new List
        list3.push {id3: 1, a: 'xyz'}, {id3: 2, a: 'abc'}

        sublist  = new ListMask list, (-> true)
        sublist2 = new ListMask {list1: list, list2}, (-> true)
        sublist3 = new ListMask {sub: sublist2, list3}, (-> true)


    it 'Creates ._mapper, .map and .pseudo', ->
      expect(sublist._mapper instanceof ListMapper).toBe true
      expect(typeof sublist.map).toBe 'object'
      expect(typeof sublist.pseudo).toBe 'object'

    it 'Multi-level .map and .pseudo', ->
      expect(sublist2.map.list1[1]).toBe list[0]
      expect(sublist2.map.list2[2]).toBe list2[1]
      expect(sublist3.map.sub.list2[2]).toBe list2[1]
      expect(sublist3.pseudo.sub.list1[1]).toBe list[1]
      expect(sublist3.map.list3[2]).toBe list3[1]

      list3.pop()
      expect(sublist3.map.list3[2]).toBeUndefined()

      list.pop()
      expect(sublist3.pseudo.sub.list1[1]).toBeUndefined()
