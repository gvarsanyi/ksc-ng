
angular.module('ksc').factory 'ksc.ListMapper', [
  'ksc.util',
  (util) ->

    define_value = util.defineValue


    ###
    Helper function that looks up named source references on .map and .pseudo
    hierarchies (aka target)

    @param [Object] target .map or .pseudo
    @param [Array] source_names (optional) list of source_names that ID target

    @return [undefined]
    ###
    deep_target = (target, source_names) ->
      if source_names
        for source_name in source_names
          target = target[source_name]
      target


    ###
    A helper class that features creating look-up objects for mappable lists
    like {List} and {ListMask}.

    On construction, it creates .map={} (for {Record}s with ._id) and .pseudo={}
    (for {Record}s with no valid ._id but with valid ._pseudo ID) on the parent.

    @note Methods are prepped to handle multiple named sources for {ListMask}.
      If multi-sourced, .map and .pseudo will have sub-objects with keys being
      the source names. See: {ListMask}

    @note This class - being just an extension - has no error handling. All
      error cases should be handled by the callers

    @author Greg Varsanyi
    ###
    class ListMapper

      # @property [Object] key-value (recordId: {Record}) mapping
      map: null

      ###
      @property [boolean|undefined] indicates multiple named sources on parent.
        Set to boolean if parent is {ListMask} or undefined {List}.
      ###
      multi: null

      # @property [List/ListMask] parent {List} or {ListMask}
      parent: null

      # @property [Object] key-value (recordPseudoId: {Record}) mapping
      pseudo: null


      ###
      Creates containers for records with valid ._id (.map) and pseudo records
      (.pseudo)

      Adds references to itself (as ._mapper) and .map and .pseudo to parent.

      @param [List/ListMask] list reference to parent {List} or {ListMask}
      ###
      constructor: (@parent) ->
        mapper = @

        source = parent.source

        define_value mapper, 'map',      {}, 0, 1
        define_value mapper, 'pseudo',   {}, 0, 1
        define_value mapper, 'multi',    (source and not source._), 0, 1
        define_value mapper, '_sources', [], 0, 1

        build_maps = (parent, target_map, target_pseudo, names) ->
          if src = parent.source # chained ListMask
            if src._ # ListMask with no named sources
              build_maps src._, target_map, target_pseudo, names
            else # named sources, append names to .map and .pseudo
              for source_name, source_list of src
                target_map[source_name]    = {}
                target_pseudo[source_name] = {}
                subnames = (item for item in names)
                subnames.push source_name
                build_maps source_list, target_map[source_name],
                           target_pseudo[source_name], subnames
          else
            mapper._sources.push {names, source: parent}
        build_maps parent, mapper.map, mapper.pseudo, []

        Object.freeze mapper._sources


      ###
      Add record to .map or .pseudo (whichever fits)

      @param [Record] record reference to a record
      @param [Array<string>] source_names (optional) named source identifier

      @return [Record] the added record
      ###
      add: (record, source_names) ->
        mapper = @

        if record._id?
          id     = record._id
          target = mapper.map
        else
          id     = record._pseudo
          target = mapper.pseudo

        target = deep_target target, source_names

        target[id] = record


      ###
      Delete record from .map or .pseudo (whichever fits)

      @overload del(map_id, pseudo_id, source_names)
        @param [string|number] map_id (optional) ._id of record
        @param [string|number] pseudo_id (optional) ._pseudo ID of record
        @param [Array<string>] source_names (optional) named source identifier
      @overload del(record, na, source_names)
        @param [Record] record reference to a record on .map or .pseudo
        @param [null] na (skipped)
        @param [Array<string>] source_names (optional) named source identifier

      @return [undefined]
      ###
      del: (map_id, pseudo_id, source_names) ->
        mapper = @

        if util.isObject map_id
          pseudo_id = map_id._pseudo
          map_id    = map_id._id

        if pseudo_id?
          target = mapper.pseudo
          map_id = pseudo_id
        else
          target = mapper.map

        target = deep_target target, source_names

        delete target[map_id]
        return


      ###
      Find a record on .map or .pseudo (whichever fits)

      @overload has(map_id, pseudo_id, source_names)
        @param [string|number] map_id (optional) ._id of record
        @param [string|number] pseudo_id (optional) ._pseudo ID of record
        @param [Array<string>] source_names (optional) named source identifier
      @overload has(record, na, source_names)
        @param [Record] record reference to a record on .map or .pseudo
        @param [null] na (skipped)
        @param [Array<string>] source_names (optional) named source identifier

      @return [Record|false] found record or false if not found
      ###
      has: (map_id, pseudo_id, source_names) ->
        mapper = @

        if util.isObject map_id
          pseudo_id = map_id._pseudo
          map_id    = map_id._id

        if pseudo_id?
          id     = pseudo_id
          target = mapper.parent.pseudo
        else
          id     = map_id
          target = mapper.parent.map

        target = deep_target target, source_names

        target[id] or false


      ###
      Helper method that creates and registers mapper objects (.map, .pseudo and
      ._mapper) on provided Array instances created by {List} or {ListMask}

      @param [List] list reference to the list

      @return [undefined]
      ###
      @register: (list) ->
        mapper = new ListMapper list

        define_value list, '_mapper', mapper,        0, 1
        define_value list, 'map',     mapper.map,    0, 1
        define_value list, 'pseudo',  mapper.pseudo, 0, 1

        return
]
