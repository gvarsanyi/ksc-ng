
main.factory 'kareo.Record', ->

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
      clone = angular.copy @_saved
      unless return_plain_object
        clone = new @constructor angular.copy source
      clone

    _entity: ->
      @_clone true

    _getId: ->
      unless id_property = @_idProperty
        for own k of @_saved
          @_idProperty = id_property = k
          break
      if typeof id_property is 'object'
        return (@[part] for part in id_property when data[part]?).join '-'
      @[id_property]
