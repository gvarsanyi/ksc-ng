
ksc.factory 'ksc.ListMapper', [
  'ksc.util',
  (util) ->

    define_value = util.defineValue


    ###
    A helper class that features creating look-up objects for mappable lists
    like {List} and {ListMask}.

    On construction, it creates .idMap={} (for {Record}s with ._id) and
    .pseudoMap={} (for {Record}s with no valid ._id but with valid ._pseudo ID)
    on the parent.

    @note Methods are prepped to handle multiple named sources for {ListMask}.
      If multi-sourced, .idMap and .pseudoMap will have sub-objects with keys
      being the source names. See: {ListMask}

    @note This class - being just an extension - has no error handling. All
      error cases should be handled by the callers

    @author Greg Varsanyi
    ###
    class ListMapper

      # @property [Object] key-value (recordId: {Record}) mapping
      idMap: undefined #DOC-ONLY#

      ###
      @property [boolean|undefined] indicates multiple named sources on parent.
        Set to boolean if parent is {ListMask} or undefined {List}.
      ###
      multi: undefined #DOC-ONLY#

      # @property [List/ListMask] parent {List} or {ListMask}
      parent: undefined #DOC-ONLY#

      # @property [Object] key-value (recordPseudoId: {Record}) mapping
      pseudoMap: undefined #DOC-ONLY#


      ###
      Creates containers for records with valid ._id (.idMap) and pseudo records
      (.pseudoMap)

      Adds references to itself (as ._mapper) and .idMap and .pseudoMap to
      parent.

      @param [List/ListMask] list reference to parent {List} or {ListMask}
      ###
      constructor: (@parent) ->
        mapper = @

        source = parent.source

        define_value mapper, 'multi',    (source and not source._), 0, 1
        define_value mapper, '_sources', [], 0, 1

        has_mapped_source = (target) ->
          if target.source
            for k, ref of target.source when has_mapped_source ref
              return true
            return false
          target.idProperty?

        if mapped = has_mapped_source parent
          define_value mapper, 'idMap',     {}, 0, 1
          define_value mapper, 'pseudoMap', {}, 0, 1

        build_maps = (parent, target_map={}, target_pseudo={}, names) ->
          if src = parent.source # chained ListMask
            if src._ # ListMask with no named sources
              build_maps src._, target_map, target_pseudo, names
            else # named sources, append names to .idMap and .pseudoMap
              for source_name, source_list of src
                if mapped and has_mapped_source parent
                  target_map[source_name]    = {}
                  target_pseudo[source_name] = {}
                subnames = (item for item in names)
                subnames.push source_name
                build_maps source_list, target_map[source_name],
                           target_pseudo[source_name], subnames
          else
            mapper._sources.push {names, source: parent}
        build_maps parent, mapper.idMap, mapper.pseudoMap, []

        Object.freeze mapper._sources


      ###
      Add record to .idMap or .pseudoMap (whichever fits) as getter/setter

      @param [Record] record reference to a record
      @param [Array<string>] source_names (optional) named source identifier

      @return [Record] the added record
      ###
      add: (record, source_names) ->
        mapper = @

        if record._id?
          id     = record._id
          target = mapper.idMap
        else
          id     = record._pseudo
          target = mapper.pseudoMap

        target = ListMapper.deepTarget target, source_names

        util.defineGetSet target,
                          id,
                          (-> record),
                          ((value) -> record._replace value),
                          1

        record


      ###
      Delete record from .idMap or .pseudoMap (whichever fits)

      @overload del(map_id, pseudo_id, source_names)
        @param [string|number] map_id (optional) ._id of record
        @param [string|number] pseudo_id (optional) ._pseudo ID of record
        @param [Array<string>] source_names (optional) named source identifier
      @overload del(record, na, source_names)
        @param [Record] record reference to a record on .idMap or .pseudoMap
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
          target = mapper.pseudoMap
          map_id = pseudo_id
        else
          target = mapper.idMap

        target = ListMapper.deepTarget target, source_names

        delete target[map_id]
        return


      ###
      Find a record on .idMap or .pseudoMap (whichever fits)

      @overload has(map_id, pseudo_id, source_names)
        @param [string|number] map_id (optional) ._id of record
        @param [string|number] pseudo_id (optional) ._pseudo ID of record
        @param [Array<string>] source_names (optional) named source identifier
      @overload has(record, na, source_names)
        @param [Record] record reference to a record on .idMap or .pseudoMap
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
          target = mapper.parent.pseudoMap
        else
          id     = map_id
          target = mapper.parent.idMap

        target = ListMapper.deepTarget target, source_names

        target[id] or false

      ###
      Helper function that looks up named source references on .idMap and
      .pseudoMap hierarchies (aka target)

      @param [Object] target .idMap or .pseudoMap
      @param [Array] source_names (optional) list of source_names that ID target

      @return [undefined]
      ###
      @deepTarget = (target, source_names) ->
        if source_names
          for source_name in source_names
            target = target[source_name]
        target


      ###
      Helper method that creates and registers mapper objects (.idMap,
      .pseudoMap and ._mapper) on provided Array instances created by {List}
      or {ListMask}

      @param [List] list reference to the list

      @return [undefined]
      ###
      @register: (list) ->
        mapper = new ListMapper list

        define_value list, '_mapper', mapper
        if mapper.idMap
          define_value list, 'idMap',     mapper.idMap
          define_value list, 'pseudoMap', mapper.pseudoMap

        return
]
