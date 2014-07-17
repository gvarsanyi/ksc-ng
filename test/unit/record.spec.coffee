
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

  it 'Data is required', ->
    expect(-> new Record).toThrow()
    expect(-> new Record {}).toThrow()

  it 'Options arg must be null/undefined/Object', ->
    expect(-> new Record {a: 1}, 'fds').toThrow()

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

    example.ext = 1
    record.ext = 1
    obj = record._clone true
    expect(obj).toEqual example

    record2 = record._clone()
    expect(record).toEqual record2
    expect(record).not.toBe record2

  it 'Method ._entity()', ->
    example = {id: 1, x: 2, y: {a: 3}}
    record = new Record example
    ent = record._entity()
    expect(ent).toEqual example
    expect(ent).not.toBe example

  it 'Method ._replace()', ->
    example = {id: 1, x: 2, y: {a: 3}}
    example2 = {id: 2, x: 3, y: new Record {dds: 43, dff: 4}}
    expected = {id: 2, x: 3, y: {dds: 43, dff: 4}}
    record = new Record example
    record._replace example2
    ent = record._clone true
    expect(ent).toEqual expected
    expect(ent).not.toBe expected

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

  it 'Parent registration', ->
    record = new Record {id: 1}, null, {x: 'a'}
    expect(record._parent.x).toBe 'a'

    # Parent must be an object if specified
    expect(-> new Record {id: 1}, null, 'x').toThrow()

    # Parent_key must be string or number
    expect(-> new Record {id: 1}, null, {}, true).toThrow()

    # Parent_key requires parent object
    expect(-> new Record {id: 1}, null, null, 'x').toThrow()
