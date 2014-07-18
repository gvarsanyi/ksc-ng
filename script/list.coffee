
app.factory 'ksc.List', [
  'ksc.EditableRecord', 'ksc.Record', 'ksc.Utils',
  (EditableRecord, Record, Utils) ->

    is_object = Utils.isObject

    ###
    Constructor for an Array instance and methods to be added to that instance

    Only contains objects. Methods push() and unshift() take vanilla objects
    too, but turn them into ksc.Record instances.

    @note This record contains a unique list of records. Methods push() and
    unshift() are turned into "upsert" loaders: if the record is already in
    the list it will update the already existing one instead of being added to
    the list

    Maintains a key-value map of record._id's in the .map={id: Record} property

    @example
      list = new List
        record:
          class: Record
          idProperty: 'id'

      list.push {id: 1, x: 2}
      list.push {id: 2, x: 3}
      list.push {id: 2, x: 4}
      console.log list # [{id: 1, x: 2}, {id: 2, x: 4}]
      console.log list.map[2] # {id: 2, x: 4}

    Options that may be used:
    - .options.record.class (class reference for record objects)
    - .options.record.idProperty (property/properties that define record ID)

    @author Greg Varsanyi <greg.varsanyi@kareo.com>
    ###
    class List

      ###
      Creates a vanilla Array instance (e.g. []), adds methods and overrides
      pop/shift/push/unshift logic to support the special features. Will inherit
      standard Array behavior for .length and others.

      @param [Object] options (optional) configuration data for this list

      @return [Array] returns plain [] with extra methods and some overrides
      ###
      constructor: (options={}) ->
        list = []
        list.map = {}
        list.options = angular.copy options

        list.options.class = proto = @constructor.prototype

        for k, v of proto
          if typeof v is 'function' and k.indexOf('constructor') is -1 and
          k.substr(0, 2) isnt '__'
            list[k] = v

        return list


      ###
      Cut 1 or more records from the list

      Option used:
      - .options.record.idProperty (property/properties that define record ID)

      @param [Record] records... Record(s) or record ID(s) to be removed

      @throw [Error] if element can't be found
      @throw [Error] if not record reference argument is provided

      @return [Object] returns list of affected records: {cut: [records...]}
      ###
      cut: (records...) ->
        unless records.length
          throw new Error 'At least one record reference argument is required'

        cut      = []
        deleting = {}
        list     = @
        for record in records
          unless is_object record
            record = list.map[record]

          unless list.map[record?._id]
            throw new Error 'Could not find element: ' + record

          delete list.map[record._id]
          deleting[record._id] = true
          cut.push record

        for record, pos in list when deleting[record._id]?
          tmp_container = []
          while list.length > pos
            item = Array::pop.call list
            tmp_container.push(item) unless deleting[item._id]
          Array::push.call list, tmp_container...
          break

        {cut}


      ###
      Empty list

      Option used:
      - .options.record.idProperty (property/properties that define record ID)

      @return [List] returns the list array (chainable)
      ###
      empty: ->
        for i in [0 ... @length] by 1
          @pop()
        @


      ###
      Remove the last element

      Option used:
      - .options.record.idProperty (property/properties that define record ID)

      @return [Record] The removed element
      ###
      pop: ->
        List::__remove.call @, 'pop'


      ###
      Upsert 1 or more records - adds to the end of the list.
      Records with an ID that exists in the list already will update the
      existing one instead of being added.

      Option used:
      - .options.record.idProperty (property/properties that define record ID)

      @overload push(items...)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)

        @return [number] New length of list

      @overload push(items..., return_records)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)
        @param [boolean] return_records Request to return an object with
        references to the affected records:
        {insert: [records...], update: [records...]}

        @return [Object] Affected records
      ###
      push: (items..., return_records) ->
        List::__add.call @, 'push', items..., return_records


      ###
      Remove the first element

      Option used:
      - .options.record.idProperty (property/properties that define record ID)

      @return [Record] The removed element
      ###
      shift: ->
        List::__remove.call @, 'shift'


      ###
      Upsert 1 or more records - adds to the beginning of the list.
      Records with an ID that exists in the list already will update the
      existing one instead of being added.

      Option used:
      - .options.record.idProperty (property/properties that define record ID)

      @overload unshift(items...)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)

        @return [number] New length of list

      @overload unshift(items..., return_records)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)
        @param [boolean] return_records Request to return an object with
        references to the affected records:
        {insert: [records...], update: [records...]}

        @return [Object] Affected records
      ###
      unshift: (items..., return_records) ->
        List::__add.call @, 'unshift', items..., return_records


      ###
      Aggregate method for push/unshift

      Option used:
      - .options.record.idProperty (property/properties that define record ID)

      @param [string] orig_fn 'push' or 'unshift'
      @param [Object] items... Record or vanilla object to be added
      @param [string] return_records Triggers stat object response (not .length)

      @return [number|Object] list.length or {insert: [...], update: [...]}
      ###
      __add: (orig_fn, items..., return_records) ->
        if typeof return_records is 'boolean'
          return_records = {}
        else
          items.push return_records
          return_records = null

        list = @

        tmp = []
        record_opts = list.options.record
        record_class = record_opts?.class or EditableRecord
        for item in items
          unless is_object item
            throw new Error 'List can only contain objects. `' + item +
                            '` is ' + (typeof item) + 'type.'

          unless item instanceof record_class
            if item instanceof Record
              item = new record_class item._clone(true), record_opts, list
            else
              item = new record_class item, record_opts, list

          if existing = list.map[item._id]
            existing._replace item._clone true
            if return_records
              (return_records.update ?= []).push item
          else
            list.map[item._id] = item
            tmp.push item
            if return_records
              (return_records.insert ?= []).push item

        if tmp.length
          Array.prototype[orig_fn].apply list, tmp

        return return_records if return_records
        list.length # default push/unshift return behavior


      ###
      Aggregate method for pop/shift

      Option used:
      - .options.record.idProperty (property/properties that define record ID)

      @param [string] orig_fn 'pop' or 'shift'

      @return [Record] Removed record
      ###
      __remove: (orig_fn) ->
        record = Array.prototype[orig_fn].call @
        delete @map[record._id]
        record
]
