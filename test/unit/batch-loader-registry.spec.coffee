
describe 'app.service', ->

  describe 'batchLoaderRegistry', ->

    BatchLoader = batchLoaderRegistry = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        BatchLoader         = $injector.get 'ksc.BatchLoader'
        batchLoaderRegistry = $injector.get 'ksc.batchLoaderRegistry'


    it 'Method .get()', ->
      # calls batchLoaderRegistry.register()
      loader = new BatchLoader '/api/Bootstrap', {Test: '/api/Test'}
      expect(batchLoaderRegistry.get 'x').toBe false
      expect(typeof batchLoaderRegistry.get '/api/Test').toBe 'object'
      loader.open = false
      expect(batchLoaderRegistry.get '/api/Test').toBe false

    it 'Method .register()', ->
      # calls batchLoaderRegistry.register()
      loader = new BatchLoader '/api/Bootstrap', {Test: '/api/Test'}
      expect(batchLoaderRegistry.map['/api/Bootstrap']).toBe loader

    it 'Method .unregister()', ->
      expect(batchLoaderRegistry.unregister {endpoint: 'x'}).toBe false
      batchLoaderRegistry.register {endpoint: 'x'}
      expect(batchLoaderRegistry.unregister {endpoint: 'x'}).toBe true
      expect(batchLoaderRegistry.unregister {endpoint: 'x'}).toBe false

    describe 'Error handling', ->

      it 'Method .register() arguments', ->
        expect(-> batchLoaderRegistry.register()).toThrow()
        expect(-> batchLoaderRegistry.register true).toThrow()
        expect(-> batchLoaderRegistry.register {}).toThrow()
        expect(-> batchLoaderRegistry.register {endpoint: 1}).toThrow()
        expect(-> batchLoaderRegistry.register {endpoint: ''}).toThrow()
        expect(-> batchLoaderRegistry.register {endpoint: 'x'}).not.toThrow()
        expect(typeof batchLoaderRegistry.map.x).toBe 'object'
        expect(-> batchLoaderRegistry.register {endpoint: 'x'}).toThrow() # dupe
