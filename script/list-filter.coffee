
app.factory 'ksc.ListFilter', [
  'ksc.EventEmitter', 'ksc.List', 'ksc.ListSorter', 'ksc.utils',
  (EventEmitter, List, ListSorter, utils) ->

    define_value = utils.defineValue

    ###
    Helper function that adds element to list in a sort-sensitive way when
    needed

    Expects scope to be a {ListFilter} instance

    @param [Record] record Item to be injected

    @return [undefined]
    ###
    add_to_list = (record) ->
      list = @
      if list.sorter # sorted (insert to position)
        pos = list.sorter.position record
        Array::splice.call list, pos, 0, record
      else
        Array::push.call list, record
      return

    ###
    Helper function that handles all kinds of event mutations coming from the
    parent (source) list

    Action types: 'add', 'cut', 'update'
    Targets and sources may or may not should be or had been on filtered list,
    so this function may or may not transform (or drop) the event before it
    emits to its own listeners.

    Expects scope to be a {ListFilter} instance

    @param [Object] info Event information object

    @event 'update' See {List#_recordChange}, {List#add} and {List#remove} for
      possible event emission object descriptions

    @return [undefined]
    ###
    event_update = (info) ->
      list      = @
      action    = null
      cut       = []
      filter_fn = list.filter
      incoming  = info.action

      {map, pseudo, source} = list

      add_action = (name, info) ->
        ((action ?= {})[name] ?= []).push info

      adder = (record) ->
        add_to_list.call list, record
        add_action 'add', record

      cutter = (id, pseudo_id, record) ->
        target = map
        if pseudo_id?
          id = pseudo_id
          target = pseudo
        if target[id]
          add_action 'cut', record
          cut.push record
          delete target[id]

      delete_if_on = (map_id, pseudo_id) ->
        if map_id? # from map
          if map[map_id] # was on filtered
            delete map[map_id]
            return true
        else
          if pseudo[pseudo_id] # was on filtered
            delete pseudo[pseudo_id]
            return true
        false

      find_and_add = (map_id, pseudo_id, record) ->
        if map_id? # moves to map
          if map[map_id]
            found = true
          map[map_id] = record
        else # moves to pseudo
          if pseudo[pseudo_id]
            found = true
          pseudo[pseudo_id] = record
        !!found

      if incoming.cut
        for record in incoming.cut
          cutter record._id, record._pseudo, record

      if incoming.add
        for record in incoming.add when filter_fn record
          find_and_add record._id, record._pseudo, record
          adder record

      if incoming.update
        for info in incoming.update
          {record, info, merge, move, source} = info
          from = to = null
          if remapper = merge or move
            {from, to} = remapper
          if filter_fn record # update or add
            source_found = from and delete_if_on from.map, from.pseudo
            if to
              target_found = find_and_add to.map, to.pseudo, record
            else
              target_found = find_and_add record._id, record._pseudo, record
            if source_found and target_found
              add_action 'update', {record, info, merge: remapper, source}
              cut.push source
            else if source_found
              add_action 'update', {record, info, move: remapper}
            else if target_found
              update_info = {record}
              for key, value of {info, source} when value?
                update_info[key] = value
              add_action 'update', update_info
            else
              adder record
          else # remove if found
            if merge
              cutter from.map, from.pseudo, source
              cutter to.map, to.pseudo, record
            else if move
              cutter from.map, from.pseudo, record
            else
              cutter record._id, record._pseudo, record

      unless list.sorter
        while Array::pop.call list
          true
        for record in list.source when map[record._id] or pseudo[record._pseudo]
          Array::push.call list, record
      else if cut.length
        tmp_container = []
        while record = Array::pop.call list
          unless record in cut
            tmp_container.push record
        if tmp_container.length
          tmp_container.reverse()
          Array::push.apply list, tmp_container

      if action
        list.events.emit 'update', {node: list, action}

      return

    ###
    Filtered list that picks up changes from parent (source) {List} instance
    automatically but may have its own sorter.

    Adding to or removing from a filtered list is not allowed, all of those
    operations are supposed to happen on the parent list.

    This list also emits appropriate events on changes, just like {List} does.

    @example
            list = new List
            list.push {id: 1, x: 'aaa'}, {id: 2, x: 'baa'}, {id: 3, x: 'ccc'}

            filter_fn = (record) -> # filter to .x properties that have char 'a'
              String(record.x).indexOf('a') > -1

            sublist = new ListFilter list, filter_fn
            console.log sublist # {id: 1, x: 'aaa'}, {id: 2, x: 'baa'}

            list.map[1].x = 'xxx' # should remove item form sublist as it does
                                  # not meet the filter_fn requirement any more

            console.log sublist # {id: 2, x: 'baa'}

    @author Greg Varsanyi
    ###
    class ListFilter

      # @property [EventEmitter] reference to related event-emitter instance
      events: null

      ###
      @property [function] function with signiture `(record) ->` and boolean
        return value indicating if record should be in the filtered list
      ###
      filter: null

      # @property [object] hash map of records (keys being record ._id values)
      map: null

      # @property [object] filtered list related options
      options: null

      # @property [object] hash map of records without ._id keys
      pseudo: null

      # @property [ListSorter] (optional) list auto-sort logic see: {ListSorter}
      sorter: null

      # @property [object] reference to parent list
      source: null


      ###
      Creates a vanilla Array instance (e.g. []), disables methods like
      pop/shift/push/unshift since thes are supposed to be used on the source
      (aka parent) list only

      @param [Object] source reference to parent list
      @param [function] filter function with signiture `(record) ->` and boolean
        return value indicating if record should be in the filtered list

      @return [Array] returns plain [] with filtered contents
      ###
      constructor: (source, filter, options={}) ->
        list = []

        List.addProperties list, @constructor

        for key in ['push', 'unshift', 'pop', 'shift', 'splice']
          define_value list, key, undefined

        define_value list, 'events', new EventEmitter, false, true

        define_value list, 'filter', filter, false, true

        define_value list, 'map', {}, false, true

        define_value list, 'options', options

        define_value list, 'pseudo', {}, false, true

        define_value list, 'source', source, false, true

        define_value list, 'unsubscriber', source.events.on 'update', (info) ->
          event_update.call list, info

        ListSorter.register list, options.sorter
        delete options.sorter # list.sorter is created and holds sorter info

        for record in source when filter record
          if record._id?
            list.map[record._id] = record
          else
            list.pseudo[record._pseudo] = record

          add_to_list.call list, record

        return list

      ###
      Unsubscribes from list, destroy all properties and freeze

      @return [undefined]
      ###
      destroy: ->
        list = @

        list.unsubscriber()

        while Array::pop.call list
          true

        for key of list
          delete list[key]

        delete list.options
        delete list.unsubscriber

        Object.freeze list
        true
]
