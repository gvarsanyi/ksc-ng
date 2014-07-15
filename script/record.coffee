
app.factory 'ksc.Record', ->

  class Record
    constructor: (data) ->
      return @_construct(data) if data?

    _construct: (data) ->
      base = new @constructor
      base._base = base

      base._saved = saved = Object.create base
      saved[k] = v for own k, v of angular.copy data
      base._id = saved._getId()
      saved

    _clone: (return_plain_object=false) ->
      saved = {}
      saved[k] = v for own k, v of @_saved
      clone = angular.copy saved

      unless return_plain_object
        clone = new @constructor clone

      clone

    _entity: ->
      @_clone true

    _getId: ->
      key = 'idProperty'
      options = @_base._options ?= {}
      unless options[key]
        for own k of @_saved
          options[key] = k
          break

      unless (id_property = options[key])
        throw new Error 'Could not identify ._options.idProperty'

      if typeof id_property is 'object'
        return (@[pt] for pt in id_property when data[pt]?).join '-'

      @[id_property]
