
describe 'app.service', ->

  describe 'util', ->

    util = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        util = $injector.get 'ksc.util'


    it 'Method .isKeyConform()', ->
      expect(util.isKeyConform (->)).toBe false
      expect(util.isKeyConform {}).toBe false
      expect(util.isKeyConform true).toBe false
      expect(util.isKeyConform false).toBe false
      expect(util.isKeyConform null).toBe false
      expect(util.isKeyConform()).toBe false
      expect(util.isKeyConform NaN).toBe false
      expect(util.isKeyConform '').toBe false
      expect(util.isKeyConform 'x').toBe true
      expect(util.isKeyConform 0).toBe true
      expect(util.isKeyConform 1).toBe true
      expect(util.isKeyConform -1).toBe true
      expect(util.isKeyConform 1.23).toBe true
