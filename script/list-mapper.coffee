
app.factory 'ksc.ListMapper', [
  'ksc.utils',
  (utils) ->

    define_value = utils.defineValue


    ###
    A helper class that features creating look-up objects for mappable lists
    like {List} and {ListFilter}.

    On construction, it creates .map={} (for {Record}s with ._id) and .pseudo={}
    (for {Record}s with no valid ._id but with valid ._pseudo ID) on the parent.

    @note Methods are prepped to handle multiple named sources for {ListFilter}.
      If multi-sourced, .map and .pseudo will have sub-objects with keys being
      the source names. See: {ListFilter}

    @note This class - being just an extension - has no error handling. All
      error cases should be handled by the callers

    @author Greg Varsanyi
    ###
    class ListMapper

      # @property [Object] key-value (recordId: {Record}) mapping
      map: null

      ###
      @property [boolean] indicates multiple named sources on parent
      ###
      multi: false

      # @property [List/ListFilter] parent {List} or {ListFilter}
      parent: null

      ###
      # @property [Object] key-value (recordPseudoId: {Record}) mapping
      ###
      pseudo: null


      ###
      Creates containers for records with valid ._id (.map) and pseudo records
      (.pseudo)

      Adds references to itself (as ._mapper) and .map and .pseudo to parent.

      @param [List/ListFilter] list reference to parent {List} or {ListFilter}
      ###
      constructor: (@parent) ->
        mapper = @

        source = parent.source

        mapper.map    = {}
        mapper.pseudo = {}
        mapper.multi  = source and not source._

        if mapper.multi
          for source_name, source_list of source
            mapper.map[source_name]    = {}
            mapper.pseudo[source_name] = {}

        define_value parent, '_mapper', mapper,        false, true
        define_value parent, 'map',     mapper.map,    false, true
        define_value parent, 'pseudo',  mapper.pseudo, false, true


      ###
      Add record to .map or .pseudo (whichever fits)

      @param [Record] record reference to a record
      @param [string] source_name (optional) named source identifier

      @return [Record] the added record
      ###
      add: (record, source_name) ->
        mapper = @

        if record._id?
          id     = record._id
          target = mapper.map
        else
          id     = record._pseudo
          target = mapper.pseudo

        if mapper.multi
          target = target[source_name]

        target[id] = record


      ###
      Delete record from .map or .pseudo (whichever fits)

      @overload del(map_id, pseudo_id, source_name)
        @param [string|number] map_id (optional) ._id of record
        @param [string|number] pseudo_id (optional) ._pseudo ID of record
        @param [string] source_name (optional) named source identifier
      @overload del(record, na, source_name)
        @param [Record] record reference to a record on .map or .pseudo
        @param [null] na (skipped)
        @param [string] source_name (optional) named source identifier

      @return [undefined]
      ###
      del: (map_id, pseudo_id, source_name) ->
        mapper = @

        if utils.isObject map_id
          pseudo_id = map_id._pseudo
          map_id    = map_id._id

        if pseudo_id?
          target = mapper.pseudo
          map_id = pseudo_id
        else
          target = mapper.map

        if mapper.multi
          target = target[source_name]

        delete target[map_id]
        return


      ###
      Find a record on .map or .pseudo (whichever fits)

      @overload has(map_id, pseudo_id, source_name)
        @param [string|number] map_id (optional) ._id of record
        @param [string|number] pseudo_id (optional) ._pseudo ID of record
        @param [string] source_name (optional) named source identifier
      @overload has(record, na, source_name)
        @param [Record] record reference to a record on .map or .pseudo
        @param [null] na (skipped)
        @param [string] source_name (optional) named source identifier

      @return [Record|false] found record or false if not found
      ###
      has: (map_id, pseudo_id, source_name) ->
        mapper = @

        if utils.isObject map_id
          pseudo_id = map_id._pseudo
          map_id    = map_id._id

        if pseudo_id?
          id     = pseudo_id
          target = mapper.parent.pseudo
        else
          id     = map_id
          target = mapper.parent.map

        if mapper.multi
          target = target[source_name]

        target[id] or false
]
