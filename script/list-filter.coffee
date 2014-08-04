
app.factory 'ksc.ListFilter', [
  'ksc.EventEmitter', 'ksc.List', 'ksc.ListSorter', 'ksc.errors', 'ksc.utils',
  (EventEmitter, List, ListSorter, errors, utils) ->

    define_value = utils.defineValue

    ###
    TODO: class desc

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
          ListFilter.eventUpdate.call list, info

        for record in source when filter record
          if record._id?
            list.map[record._id] = record
          else
            list.pseudo[record._pseudo] = record
          Array::push.call list, record

        ListSorter.register list, options.sorter
        delete options.sorter # list.sorter is created and holds sorter info

        return list

      destroy: ->
        @unsubscriber()

      @eventUpdate: (info) ->
        list      = @

        action    = null
        cut       = []
        filter_fn = list.filter
        incoming  = info.action

        {map, pseudo, source} = list

        add_action = (name, info) ->
          ((action ?= {})[name] ?= []).push info

        adder = (record) ->
          Array::push.call list, record
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
            if utils.isObject record
              cutter record._id, record._pseudo, record
            else if map[record]
              cutter record, null, map[record]

        if incoming.add
          for record in incoming.add when filter_fn record
            find_and_add record._id, record._pseudo, record
            adder record

        if incoming.upsert
          for record in incoming.upsert
            if filter_fn record
              add_action 'upsert', record
            else
              cutter record._id, record._pseudo, record

        if incoming.move
          for info in incoming.move
            source_found_on_filter = false
            {from, to, record} = info
            if filter_fn record # eligible
              source_found_on_filter = delete_if_on from.map, from.pseudo
              find_and_add to.map, to.pseudo, record
              if source_found_on_filter
                add_action 'move', info
              else
                adder record
            else
              cutter from.map, from.pseudo, record

        if incoming.merge
          for info in incoming.merge
            {from, to, record, source} = info
            source_found_on_filter = false
            target_found_on_filter = false
            if filter_fn record # eligible
              source_found_on_filter = delete_if_on from.map, from.pseudo
              target_found_on_filter = find_and_add to.map, to.pseudo, record
              if source_found_on_filter and target_found_on_filter
                add_action 'merge', info
                cut.push source
              else if source_found_on_filter
                add_action 'move', {from, to, record}
              else if target_found_on_filter
                add_action 'update', {node: record, action: 'replace'}
              else
                adder record
            else
              cutter from.map, from.pseudo, source
              cutter to.map to.pseudo, record

        if incoming.update
          for info in incoming.update
            record = info.node
            target_found_on_filter = false
            if filter_fn record # eligible
              if find_and_add record._id, record._pseudo, record
                add_action 'update', info
              else
                adder record
            else
              cutter record._id, record._pseudo, record

        if cut.length
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
]
