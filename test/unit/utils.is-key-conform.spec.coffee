
describe 'app.service', ->

  describe 'utils', ->

    utils = null

    beforeEach ->
      module 'app'
      inject ($injector) ->
        utils = $injector.get 'ksc.utils'


    it 'Method .isKeyConform()', ->
      expect(utils.isKeyConform (->)).toBe false
      expect(utils.isKeyConform {}).toBe false
      expect(utils.isKeyConform true).toBe false
      expect(utils.isKeyConform false).toBe false
      expect(utils.isKeyConform null).toBe false
      expect(utils.isKeyConform()).toBe false
      expect(utils.isKeyConform NaN).toBe false
      expect(utils.isKeyConform '').toBe false
      expect(utils.isKeyConform 'x').toBe true
      expect(utils.isKeyConform 0).toBe true
      expect(utils.isKeyConform 1).toBe true
      expect(utils.isKeyConform -1).toBe true
      expect(utils.isKeyConform 1.23).toBe true
