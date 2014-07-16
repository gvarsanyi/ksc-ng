
describe 'Record', ->
  Record = null

  beforeEach ->
    module 'app'
    inject ($injector) ->
      Record = $injector.get 'ksc.Record'


  it 'Does not accept property names starting with underscore', ->
    expect(-> new Record _a: 1).toThrow()

  it 'Requires 1+ properties', ->
    expect(-> new Record {}).toThrow()

  it 'Composite id', ->
    record = new Record {id1: 1, id2: 2, x: 3}, idProperty: ['id1', 'id2']
    expect(record._id).toBe '1-2'

    record = new Record {id1: 1, id2: null, x: 3}, idProperty: ['id1', 'id2']
    expect(record._id).toBe '1'

  it 'Method ._clone()', ->
    example = {id: 1, x: 2, y: {a: 3}}
    record = new Record example

    obj = record._clone true
    expect(obj).toEqual example

    record2 = record._clone()
    expect(record).toEqual record2
    expect(record).not.toBe record2

  it 'Data separation', ->
    example_sub = {a: 3}
    example = {id: 1, x: 2, y: example_sub}

    record = new Record example

    example.id    = 2
    example.ext   = 3
    example_sub.a = 4
    example_sub.x = 4

    expect(record.id).toBe 1
    expect(record.ext).toBeUndefined()
    expect(record.y.a).toBe 3
    expect(record.y.x).toBeUndefined()

  it 'Does not take functions', ->
    expect(-> new Record {id: 1, fn: ->}).toThrow()
