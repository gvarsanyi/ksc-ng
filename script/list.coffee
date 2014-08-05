
app.factory 'ksc.List', [
  'ksc.EditableRecord', 'ksc.EventEmitter', 'ksc.ListSorter', 'ksc.Record',
  'ksc.errors', 'ksc.utils',
  (EditableRecord, EventEmitter, ListSorter, Record,
   errors, utils) ->

    define_value = utils.defineValue
    is_object    = utils.isObject

    normalize_return_action = (items, return_action) ->
      unless typeof return_action is 'boolean'
        items.push return_action
        return_action = false
      return_action

    emit_action = (list, action) ->
      list.events.emit 'update', {node: list, action}

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

      # @property [ListSorter] (optional) list auto-sort logic see: {ListSorter}
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

        ListSorter.register list, options.sorter
        delete options.sorter # list.sorter is created and holds sorter info

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
        emit_action list, action

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
          emit_action list, action

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
      Upsert 1 or more records - adds to the end of the list if unsorted.

      Upsert means update or insert. Updates if a record is found in the list
      with identical ._id property. Inserts otherwise.

      If list is auto-sorted, new elements will be added to their appropriate
      sorted position (i.e. not necessarily to the last position), see:
      {ListSorter} and {ListSorter#position}

      Options used:
      - .options.record.idProperty (property/properties that define record ID)

      @throw [TypeError] non-object element pushed
      @throw [MissingArgumentError] no items were pushed

      @event 'update' sends out message if list changes:
              events.emit 'update', {node: list, action: {add: [records...],
              update: [{record: record}, ...]}}

      @overload push(items...)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)

        @return [number] New length of list

      @overload push(items..., return_action)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)
        @param [boolean] return_action Request to return an object with
        references to the affected records:
        {add: [records...], update: [records...]}

        @return [Object] Affected records
      ###
      push: (items..., return_action) ->
        return_action = normalize_return_action items, return_action

        list = @

        action = List.add.call list, items, list.length

        if return_action
          return action
        list.length


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
      Upsert 1 or more records - adds to the beginning of the list if unsorted.

      Upsert means update or insert. Updates if a record is found in the list
      with identical ._id property. Inserts otherwise.

      If list is auto-sorted, new elements will be added to their appropriate
      sorted position (i.e. not necessarily to the first position), see:
      {ListSorter} and {ListSorter#position}

      Options used:
      - .options.record.idProperty (property/properties that define record ID)

      @throw [TypeError] non-object element pushed
      @throw [MissingArgumentError] no items were pushed

      @event 'update' sends out message if list changes:
              events.emit 'update', {node: list, action: {add: [records...],
              update: [{record: record}, ...]}}

      @overload unshift(items...)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)

        @return [number] New length of list

      @overload unshift(items..., return_action)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)
        @param [boolean] return_action Request to return an object with
        references to the affected records:
        {add: [records...], update: [records...]}

        @return [Object] Affected records
      ###
      unshift: (items..., return_action) ->
        return_action = normalize_return_action items, return_action

        list = @

        action = List.add.call list, items, 0

        if return_action
          return action
        list.length

      ###
      Cut and/or upsert 1 or more records. Inserts to position if unsorted.

      Upsert means update or insert. Updates if a record is found in the list
      with identical ._id property. Inserts otherwise.

      If list is auto-sorted, new elements will be added to their appropriate
      sorted position (i.e. not necessarily to the first position), see:
      {ListSorter} and {ListSorter#position}

      Options used:
      - .options.record.idProperty (property/properties that define record ID)

      @throw [ArgumentTypeError] pos or count does not meet requirements
      @throw [TypeError] non-object element pushed

      @event 'update' sends out message if list changes:
              events.emit 'update', {node: list, action: {cut: [records...],
              add: [records...], update: [{record: record}, ...]}}

      @overload unshift(items...)
        @param [number] pos Index of cut/insert start
        @param [number] count Number of elements to cut
        @param [Object] items... Record or vanilla object that will be turned
          into a Record (based on .options.record.class)

        @return [Array] removed elements

      @overload unshift(items..., return_action)
        @param [Object] items... Record or vanilla object that will be turned
          into a Record (based on .options.record.class)
        @param [boolean] return_action Request to return an object with
          references to the affected records: {cut: [records..],
          add: [records...], update: [records...]}

        @return [Object] Actions taken (see event description: action)
      ###
      splice: (pos, count, items..., return_action) ->
        return_action = normalize_return_action items, return_action

        if typeof items[0] is 'undefined' and items.length is 1
          items.pop()

        if typeof count is 'boolean' and not items.length
          return_action = count
          count = null

        positive_int_or_zero = (value, i) ->
          unless typeof value is 'number' and (value > 0 or value is 0) and
          value is Math.floor value
            throw new errors.ArgumentType
              value:    value
              argument: i
              required: 'Positive number or 0'

        action = {}
        list   = @
        len    = list.length

        if pos < 0
          pos = Math.max len + pos, 0
        positive_int_or_zero pos
        pos = Math.min len, pos

        if count?
          positive_int_or_zero count
          count = Math.min len - pos, count
        else
          count = len - pos

        list.events.halt()
        try
          if count > 0
            action = list.cut (list.slice pos, pos + count)...
          if items.length
            utils.mergeIn action, List.add.call list, items, pos
        finally
          list.events.unhalt()

        if action.cut or action.add or action.update
          emit_action list, action

        if return_action
          return action

        action.cut or [] # default splice behavior: return removed elements


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
      _recordChange: (record, record_info, old_id) ->
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
          define_value record, '_pseudo', utils.uid 'record.pseudo'
          list.pseudo[record._pseudo] = record

        info = {record, info: record_info}
        if old_id isnt record._id
          list.events.halt()
          try
            unless record._id? # map -> pseudo
              remove_from_map()
              add_to_pseudo()
              info.move =
                from: {map: old_id}
                to:   {pseudo: record._pseudo}
            else unless old_id? # pseudo -> map
              if map[record._id] # merge
                info.merge =
                  from: {pseudo: record._pseudo}
                  to:   {map: record._id}
                info.record = map[record._id]
                info.source = record
                list.cut record
                list.push record
              else # no merge
                info.move =
                  from: {pseudo: record._pseudo}
                  to:   {map: record._id}
                remove_from_pseudo()
                add_to_map()
            else # map -> map
              if map[record._id] # with merge
                info.merge =
                  from: {map: old_id}
                  to:   {map: record._id}
                info.record = map[record._id]
                info.source = record
                list.cut old_id
                list.push record
              else # no merge
                info.move =
                  from: {map: old_id}
                  to:   {map: record._id}
                remove_from_map()
                add_to_map()
          finally
            list.events.unhalt()

        if list.sorter # find the proper place for the updated record
          record = info.record
          for item, pos in list when item is record
            Array::splice.call list, pos, 1
            new_pos = list.sorter.position record
            Array::splice.call list, new_pos, 0, record
            break

        emit_action list, {update: [info]}


      ###
      Aggregate method for push/unshift

      Options used:
      - .options.record.idProperty (property/properties that define record ID)

      If list is auto-sorted, new elements will be added to their appropriate
      sorted position (i.e. not necessarily to the first/last position), see:
      {ListSorter} and {ListSorter#position}

      Expects scope to be a {List} type Array

      @param [Array] items Record or vanilla objects to be added
      @param [number] pos position to inject new element to

      @throw [TypeError] non-object element pushed
      @throw [MissingArgumentError] no items were pushed

      @event 'update' sends out message if list changes:
              events.emit 'update', {node: list, action: {add: [records...],
              update: [{record: record}, ...]}}

      @return [Object] action description: {add: [...], update: [...]}
      ###
      @add: (items, pos) ->
        unless items.length
          throw new errors.MissingArgument {name: 'item', argument: 1}

        action = {}
        list   = @

        list.events.halt()
        try
          tmp = []
          record_opts  = list.options.record
          record_class = record_opts?.class or EditableRecord
          for item in items
            original = item
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
                (action.update ?= []).push {record: existing, source: original}
              else
                list.map[item._id] = item
                tmp.push item
                (action.add ?= []).push item

              if item._pseudo
                define_value item, '_pseudo', null
            else
              define_value item, '_pseudo', utils.uid 'record.pseudo'

              list.pseudo[item._pseudo] = item
              tmp.push item
              (action.add ?= []).push item

          if tmp.length
            if list.sorter # sorted (insert to position)
              for item in tmp
                pos = list.sorter.position item
                Array::splice.call list, pos, 0, item
            else # not sorted (actual push/unshift)
              Array::splice.call list, pos, 0, tmp...
        finally
          list.events.unhalt()

        emit_action list, action

        action

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
          emit_action list, {cut: [record]}
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
