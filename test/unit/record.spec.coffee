
describe 'Record', ->
  Record = null

  beforeEach ->
    module 'app'
    inject ($injector) ->
      Record = $injector.get 'ksc.Record'


  it 'Does not accept property names starting with underscore', ->
    expect(-> new Record _a: 1).toThrow()

