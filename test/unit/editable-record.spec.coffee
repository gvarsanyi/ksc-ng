
describe 'EditableRecord', ->
  EditableRecord = Record = null

  beforeEach ->
    module 'app'
    inject ($injector) ->
      EditableRecord = $injector.get 'ksc.EditableRecord'
      Record         = $injector.get 'ksc.Record'


  it 'Instace of Record', ->
    record = new EditableRecord {a: 1}
    expect(record instanceof Record).toBe true

  it 'Properties ._changes, ._changedKeys and method .revert()', ->
    record = new EditableRecord {a: 1, b: {x: 2}, c: {x: 3}, d: null}

    expect(record._changes).toBe 0
    expect(record._changedKeys).toEqual {}

    record.a = 2
    expect(record._changes).toBe 1
    expect(record._changedKeys).toEqual {a: true}

    record._revert()
    expect(record._changes).toBe 0
    expect(record._changedKeys).toEqual {}

    record.b = null
    expect(record._changes).toBe 1
    expect(record._changedKeys).toEqual {b: true}

    record.c.x = 4
    expect(record._changes).toBe 2
    expect(record._changedKeys).toEqual {b: true, c: true}

    record.c.x = 3
    expect(record._changes).toBe 1
    expect(record._changedKeys).toEqual {b: true}

    record._revert()
    record.d = {a: 3}
    expect(record._changes).toBe 1
    expect(record._changedKeys).toEqual {d: true}

    record.d = null
    expect(record._changes).toBe 0
    expect(record._changedKeys).toEqual {}
