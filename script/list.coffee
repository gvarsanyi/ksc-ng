
app.factory 'ksc.List', [
  'ksc.EditableRecord', 'ksc.EventEmitter', 'ksc.ListSorter', 'ksc.Record',
  'ksc.errors', 'ksc.utils',
  (EditableRecord, EventEmitter, ListSorter, Record,
   errors, utils) ->

    define_value = utils.defineValue
    is_object    = utils.isObject

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

    @author Greg Varsanyi
    ###
    class List

      # @property [EventEmitter] reference to related event-emitter instance
      events: null

      # @property [object] hash map of records (keys being record ._id values)
      map: null

      # @property [object] hash map of records without ._id keys
      pseudo: null

      # @property [object] list-related options
      options: null

      # @property [ListSorter] list auto-sort logic (optional)
      sorter: null


      ###
      Creates a vanilla Array instance (e.g. []), adds methods and overrides
      pop/shift/push/unshift logic to support the special features. Will inherit
      standard Array behavior for .length and others.

      @param [Object] options (optional) configuration data for this list

      @return [Array] returns plain [] with extra methods and some overrides
      ###
      constructor: (options={}) ->
        list = []

        List.addProperties list, @constructor

        options = angular.copy options
        define_value list, 'options', options

        define_value list, 'events', new EventEmitter, false, true

        define_value list, 'map', {}, false, true

        define_value list, 'pseudo', {}, false, true
        define_value list, '_pseudoCount', 0

        ListSorter.register list, options.sorter
        delete options.sorter # list.sorter is created and hold sorter info

        return list


      ###
      Cut 1 or more records from the list

      Option used:
      - .options.record.idProperty (property/properties that define record ID)

      @param [Record] records... Record(s) or record ID(s) to be removed

      @throw [KeyError] element can not be found
      @throw [MissingArgumentError] record reference argument not provided

      @event 'update' sends out message if list changes
              events.emit 'update', {node: list, action: {cut: [records...]}}

      @return [Object] returns list of affected records: {cut: [records...]}
      ###
      cut: (records...) ->
        unless records.length
          throw new errors.MissingArgument {name: 'record', argument: 1}

        cut       = []
        list      = @
        map       = list.map
        pseudo    = list.pseudo
        removable = []

        for record in records
          if is_object record
            unless record in list
              throw new errors.Value {record, description: 'not found in list'}

            if record._pseudo?
              unless pseudo[record._pseudo]
                throw new errors.Key {record, description: 'pseudo id error'}
              delete pseudo[record._pseudo]
              cut.push record
            else
              unless map[record._id]
                throw new errors.Key {record, description: 'map id error'}
              delete map[record._id]
              cut.push record
          else # id (maybe old_id) passed
            id = record
            record = map[id]
            unless map[id]
              throw new errors.Key {id, description: 'map id error'}
            delete map[id]
            if record._id isnt id
              cut.push id
            else
              cut.push record

          removable.push record

        tmp_container = []

        while item = Array::pop.call list
          unless item in removable
            tmp_container.push item

        if tmp_container.length
          tmp_container.reverse()
          Array::push.apply list, tmp_container

        action = {cut}
        list.events.emit 'update', {node: list, action}

        action


      ###
      Empty list

      Option used:
      - .options.record.idProperty (property/properties that define record ID)

      @event 'update' sends out message if list changes (see: {List#cut})

      @return [Array] returns the list array (chainable) or action description
      ###
      empty: (return_action) ->
        list = @

        action = {cut: []}

        list.events.halt()
        try
          for i in [0 ... list.length] by 1
            action.cut.push list.shift()
        finally
          list.events.unhalt()

        if action.cut.length
          list.events.emit 'update', {node: list, action}

        if return_action
          return action
        @


      ###
      Remove the last element

      Option used:
      - .options.record.idProperty (property/properties that define record ID)

      @event 'update' sends out message if list changes (see: {List#cut})

      @return [Record] The removed element
      ###
      pop: ->
        List.remove.call @, 'pop'


      ###
      Upsert 1 or more records - adds to the end of the list.
      Records with an ID that exists in the list already will update the
      existing one instead of being added.

      If list is auto-sorted, new elements will be added to their appropriate
      sorted position (i.e. not necessarily to the last position), see:
      {ListSorter} and {ListSorter#position}

      Options used:
      - .options.record.idProperty (property/properties that define record ID)

      @throw [TypeError] non-object element pushed
      @throw [MissingArgumentError] no items were pushed

      @event 'update' sends out message if list changes:
              events.emit 'update', {node: list, action: {add: [records...],
              upsert: [records...]}}

      @overload push(items...)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)

        @return [number] New length of list

      @overload push(items..., return_action)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)
        @param [boolean] return_action Request to return an object with
        references to the affected records:
        {insert: [records...], update: [records...]}

        @return [Object] Affected records
      ###
      push: (items..., return_action) ->
        List.add.call @, 'push', items, return_action


      ###
      Remove the first element

      Option used:
      - .options.record.idProperty (property/properties that define record ID)

      @event 'update' sends out message if list changes (see: {List#cut})

      @return [Record] The removed element
      ###
      shift: ->
        List.remove.call @, 'shift'


      ###
      Upsert 1 or more records - adds to the beginning of the list.
      Records with an ID that exists in the list already will update the
      existing one instead of being added.

      If list is auto-sorted, new elements will be added to their appropriate
      sorted position (i.e. not necessarily to the first position), see:
      {ListSorter} and {ListSorter#position}

      Options used:
      - .options.record.idProperty (property/properties that define record ID)

      @throw [TypeError] non-object element pushed
      @throw [MissingArgumentError] no items were pushed

      @event 'update' sends out message if list changes:
              events.emit 'update', {node: list, action: {add: [records...],
              upsert: [records...]}}

      @overload unshift(items...)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)

        @return [number] New length of list

      @overload unshift(items..., return_action)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)
        @param [boolean] return_action Request to return an object with
        references to the affected records:
        {insert: [records...], update: [records...]}

        @return [Object] Affected records
      ###
      unshift: (items..., return_action) ->
        List.add.call @, 'unshift', items, return_action


      ###
      Catches change event from records belonging to the list

      Moves or merges records in the map if record._id changed

      @param [object] record reference to the changed record
      @param [object] info record change event hashmap
      @option info [object] node reference to the changed record or subrecord
      @option info [object] parent (optional) appears if subrecord changed,
        references the top-level record node
      @option info [Array] path (optional) appears if subrecord changed,
        provides key literals from the top-level record to changed node
      @option info [string] action type of event: 'set', 'delete', 'revert' or
        'replace'
      @option info [string|number] key (optional) changed key (for 'set')
      @option info [Array] keys (optional) changed key(s) (for 'delete')
      @param [string|number] old_id (optional) indicates _id change if provided

      @event 'update' sends out message if record changes on list
            events.emit 'update', {node: list, action: [{update: [info]}]}

      @event 'update' sends out message if record id changes (no merge)
            events.emit 'update',
              node: list
              action:
                move: [
                  from:   {map|pseudo: old_id}
                  to:     {map|pseudo: new_id}
                  record: merged_record
                ]

      @event 'update' sends out message if record id changes (merge)
            events.emit 'update',
              node: list
              action:
                merge: [
                  from:   {map|pseudo: old_id}
                  to:     {map|pseudo: new_id}
                  record: merged_record
                  source: source_record
                ]

      @return [boolean] true if list event is emitted
      ###
      _recordChange: (record, info, old_id) ->
        unless record instanceof Record
          throw new errors.Type {record, acceptable: 'Record'}

        list = @
        map  = list.map

        remove_from_map = ->
          delete map[old_id]

        remove_from_pseudo = ->
          delete list.pseudo[record._pseudo]

        add_to_map = ->
          define_value record, '_pseudo', null
          map[record._id] = record

        add_to_pseudo = ->
          define_value list, '_pseudoCount', list._pseudoCount + 1
          define_value record, '_pseudo', list._pseudoCount
          list.pseudo[record._pseudo] = record

        action = {update: [info]}
        if old_id isnt record._id
          list.events.halt()
          try
            unless record._id? # map -> pseudo
              action.move = [
                from:   {map: old_id}
                to:     {pseudo: record._pseudo}
                record: record
              ]
              remove_from_map()
              add_to_pseudo()
            else unless old_id? # pseudo -> map
              if map[record._id] # merge
                action.merge = [
                  from:   {pseudo: record._pseudo}
                  to:     {map: record._id}
                  record: map[record._id]
                  source: record
                ]
                list.cut record
                list.push record
              else # no merge
                action.move = [
                  from:   {pseudo: record._pseudo}
                  to:     {map: record._id}
                  record: record
                ]
                remove_from_pseudo()
                add_to_map()
            else # map -> map
              if map[record._id] # with merge
                action.merge = [
                  from:   {map: old_id}
                  to:     {map: record._id}
                  record: map[record._id]
                  source: record
                ]
                list.cut old_id
                list.push record
              else # map -> map without merge
                action.move = [
                  from:   {map: old_id}
                  to:     {map: record._id}
                  record: record
                ]
                remove_from_map()
                add_to_map()
          finally
            list.events.unhalt()

        list.events.emit 'update', {node: list, action}


      ###
      Aggregate method for push/unshift

      Options used:
      - .options.record.idProperty (property/properties that define record ID)

      If list is auto-sorted, new elements will be added to their appropriate
      sorted position (i.e. not necessarily to the first/last position), see:
      {ListSorter} and {ListSorter#position}

      Expects scope to be a {List} type Array

      @param [string] orig_fn 'push' or 'unshift'
      @param [Array] items Record or vanilla objects to be added
      @param [string] return_action Triggers stat object response (not .length)

      @throw [TypeError] non-object element pushed
      @throw [MissingArgumentError] no items were pushed

      @event 'update' sends out message if list changes:
              events.emit 'update', {node: list, action: {add: [records...],
              upsert: [records...]}}

      @return [number|Object] list.length or {insert: [...], update: [...]}
      ###
      @add: (orig_fn, items, return_action) ->
        unless typeof return_action is 'boolean'
          items.push return_action
          return_action = null

        unless items.length
          throw new errors.MissingArgument {name: 'item', argument: 1}

        list = @

        action = {}
        tmp    = []
        record_opts =  list.options.record
        record_class = record_opts?.class or EditableRecord
        for item in items
          unless is_object item
            throw new errors.Type {item, acceptable: 'object'}

          unless item instanceof record_class
            if item instanceof Record
              item = new record_class item._clone(true), record_opts, list
            else
              item = new record_class item, record_opts, list

          if item._id?
            if existing = list.map[item._id]
              existing._replace item._clone true
              (action.upsert ?= []).push existing
            else
              list.map[item._id] = item
              tmp.push item
              (action.add ?= []).push item

            if item._pseudo
              define_value item, '_pseudo', null
          else
            define_value list, '_pseudoCount', list._pseudoCount + 1
            define_value item, '_pseudo', list._pseudoCount

            list.pseudo[item._pseudo] = item
            tmp.push item
            (action.add ?= []).push item

        if tmp.length
          if list.sorter # sorted (insert to position)
            for item in tmp
              pos = list.sorter.position item
              list.splice pos, 0, item
          else # not sorted (actual push/unshift)
            Array.prototype[orig_fn].apply list, tmp

        list.events.emit 'update', {node: list, action}

        if return_action
          return action

        list.length # default push/unshift return behavior

      ###
      Aggregate method for pop/shift

      Option used:
      - .options.record.idProperty (property/properties that define record ID)

      Expects scope to be a {List} type Array

      @param [string] orig_fn 'pop' or 'shift'

      @event 'update' sends out message if list changes (see: {List#cut})

      @return [Record] Removed record
      ###
      @remove: (orig_fn) ->
        list    = @
        if record = Array.prototype[orig_fn].call list
          if record._id?
            delete list.map[record._id]
          else
            delete list.pseudo[record._pseudo]
          list.events.emit 'update', {node: list, action: {cut: [record]}}
        record

      ###
      Helper method that adds properties to a vanilla Array from a List
      constructor.

      @param [Array] instance Array instance to be extended
      @param [object] prototype_container @constructor of creator class

      @return [undefined]
      ###
      @addProperties: (instance, prototype_container) ->
        for key, value of prototype_container.prototype
          if key.indexOf('constructor') is -1 and key.substr(0, 2) isnt '__'
            define_value instance, key, value, false, true
        return
]
