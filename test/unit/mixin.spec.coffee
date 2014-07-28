
describe 'app.factory', ->

  describe 'Mixin', ->

    Mixin = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        Mixin = $injector.get 'ksc.Mixin'


    it 'No instance use (no properties on instance)', ->
      obj = new Mixin
      keys = (k for k of obj)
      expect(keys.length).toBe 0

    it 'Copy all non-overriding properties', ->
      class A
        @instProp: 'x'
        protoProp: 'y'
        zProp: 'not z here'

      class B
        zProp: 'z'

      Mixin.extend B, A

      expect(B.instProp).toBe 'x'
      expect(B::protoProp).toBe 'y'
      expect(B::zProp).toBe 'z'

    it 'Extend with explicitly listed properties', ->
      class A
        @instProp1: 'x'
        @instProp2: 'x'
        protoProp1: 'y'
        protoProp2: 'y'
        zProp1: 'not z here'
        zProp2: 'not z here'

      class B
        Mixin.extend B, A, 'instProp1', 'protoProp1', 'zProp1'
        zProp1: 'z'
        zProp2: 'z'

      expect(B.instProp1).toBe 'x'
      expect(B.instProp2).toBeUndefined()
      expect(B::protoProp1).toBe 'y'
      expect(B::protoProp2).toBeUndefined()
      expect(B::zProp1).toBe 'z'
      expect(B::zProp2).toBe 'z'

    it 'Extend with everything but explicitly listed properties', ->
      class A
        @instProp1: 'x'
        @instProp2: 'x'
        protoProp1: 'y'
        protoProp2: 'y'
        zProp1: 'not z here'
        zProp2: 'not z here'

      class B
        Mixin.extend B, A, false, 'instProp1', 'protoProp1', 'zProp1'
        zProp1: 'z'
        zProp2: 'z'

      expect(B.instProp1).toBeUndefined()
      expect(B.instProp2).toBe 'x'
      expect(B::protoProp1).toBeUndefined()
      expect(B::protoProp2).toBe 'y'
      expect(B::zProp1).toBe 'z'
      expect(B::zProp2).toBe 'z'

    it 'Method .extendInstance()', ->
      class A
        @instProp: 'x'
        protoProp: 'y'

      class B
        Mixin.extendInstance B, A

      expect(B.instProp).toBe 'x'
      expect(B::protoProp).toBeUndefined()

    it 'Method .extendProto()', ->
      class A
        @instProp: 'x'
        protoProp: 'y'

      class B
        Mixin.extendProto B, A

      expect(B.instProp).toBeUndefined()
      expect(B::protoProp).toBe 'y'

    it 'Error handling: property id is not string/number (key type)', ->
      class A
      class B
      expect(-> Mixin.extendInstance B, A, {}, 'x').toThrow()
