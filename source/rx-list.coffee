
CalendarCtrl.factory 'RxList', [
  'RxEditableRecord', 'RxRecord',
  (RxEditableRecord, RxRecord) ->

    add = (list, orig_fn, items..., return_records) ->
      if typeof return_records is 'boolean'
        return_records = {}
      else
        items.push return_records
        return_records = null

      record_class = list.constructorPrototype.recordClass or RxEditableRecord
      for item in items
        unless item and typeof item is 'object'
          throw new Error 'RxList can only contain objects. `' + item +
                          '` is ' + (typeof item) + 'type.'

        unless item instanceof record_class
          if item instanceof RxRecord
            item = new record_class item._clone true
          else
            item = new record_class item

        if existing = list.map[item._id]
          existing._replace item._clone true
          if return_records
            (return_records.update ?= []).push item
        else
          list.map[item._id] = item
          orig_fn.call list, item
          if return_records
            (return_records.insert ?= []).push item

      sort list # auto-sort based on list.sortBy

      return return_records if return_records
      @length # default push/unshift return behavior

    remove = (list, orig_fn) ->
      record = orig_fn.call list
      delete list.map[record.id]
      record

    sort = (list) ->
      return unless sort_by = list.sortBy

      if typeof sort_by is 'string' or sort_by instanceof Array
        sort_by = property: sort_by

      list.sort (a, b) ->
        return unless a? and b?
        if sort_by.method
          a = a[sort_by.method]?()
          b = b[sort_by.method]?()
        else if typeof (property = sort_by.property) is 'string'
          a = a.data[property]
          b = b.data[property]
        else if property instanceof Array
          a = (a.data[part] for part in property when a.data[part]).join ' '
          b = (b.data[part] for part in property when b.data[part]).join ' '

        if sort_by.type is 'number'
          a ?= 0
          b ?= 0
        else
          a ?= ''
          b ?= ''

        switch sort_by.type
          when 'natural'
            a_priority = String(a).toLowerCase() > String(b).toLowerCase()
          when 'number'
            a_priority = Number(a) > Number b
          else
            a_priority = a > b

        a_priority = not a_priority if sort_by.desc

        return 1 if a_priority
        -1


    class RxList
      constructor: (args...) ->
        @list = list = []

        list[k] = v for k, v of options
        list.map = {}

        list.constructorPrototype = @constructor.prototype

        for k, v of @constructor.prototype
          if k isnt 'constructor' and typeof v is 'function'
            unless list[k]?
              list[k] = v
            else # push, pop, shift, unshift
              do (k, v) ->
                orig_fn = list[k]
                list[k] = (args...) ->
                  v.apply list, [orig_fn].concat args

        list.push(args...) if args.length
        return list

      cut: (records...) ->
        deleting = {}
        cut = []
        for record in records
          record = @map[record] unless record and typeof record is 'object'
          continue unless @map[record?._id]
          delete @map[record._id]
          deleting[record._id] = true
          cut.push record

        if cut.length
          for record, pos in @ when deleting[record._id]?
            tmp_container = []
            while @length > pos
              item = @pop()
              tmp_container.push(item) unless deleting[item._id]
            while tmp_container.length
              @push tmp_container.shift()
            break

        {cut}

      empty: ->
        @pop() for k of @map
        @

      filter: (fn) ->
        list = []
        list.map = {}
        for item in @ when fn item
          list.push item
          list.map[item._id] = item
        list

      pop: (orig_fn) ->
        remove @, orig_fn

      push: (orig_fn, items..., return_records) ->
        add @, orig_fn, items..., return_records

      shift: (orig_fn) ->
        remove @, orig_fn

      unshift: (orig_fn, items..., return_records) ->
        add @, orig_fn, items..., return_records
]
