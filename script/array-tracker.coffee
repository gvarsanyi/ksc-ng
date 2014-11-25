
ksc.factory 'ksc.ArrayTracker', [
  'ksc.error', 'ksc.util',
  (error, util) ->

    define_get_set = util.defineGetSet
    define_value   = util.defineValue
    has_own        = util.hasOwn


    class ArrayTracker
      get:   undefined
      list:  undefined
      set:   undefined
      store: undefined

      constructor: (list, store={}, setter, getter) ->
        if has_own list, '_tracker'
          error.Value {list, description: 'List is already tracked'}
        unless Array.isArray list
          error.Type {list, description: 'Must be an array'}
        unless typeof store is 'object'
          error.Type {store, description: 'Must be an object'}

        tracker = @
        define_value list, '_tracker', tracker
        define_value tracker, 'list',  list,  0, 1
        define_value tracker, 'store', store, 0, 1

        fnize = (fn) ->
          if fn?
            unless typeof fn is 'function'
              error.Type {fn, 'Must be a function'}
          else
            fn = null
          fn

        getter = fnize getter
        setter = fnize setter

        define_get_set tracker, 'get', (-> getter),
                       ((fn) -> getter = fnize fn), 1
        define_get_set tracker, 'set', (-> setter),
                       ((fn) -> setter = fnize fn), 1

        for key, fn of ArrayTracker when key.substr(0, 1) is '_'
          do (key) ->
            define_value list, key.substr(1), (args...) ->
              ArrayTracker[key].apply tracker, args

        for value, index in list
          ArrayTracker.getterify tracker, index
          ArrayTracker.set tracker, index, value


      @getterify: (tracker, index) ->
        define_get_set tracker.list, index,
                       (-> ArrayTracker.get tracker, index),
                       ((value) -> ArrayTracker.set tracker, index, value), 1

      @get: (tracker, index) ->
        # console.log 'get:', index, tracker.store[index]
        if tracker.get
          return tracker.get index, tracker.store[index]
        tracker.store[index]

      @set: (tracker, index, value) ->
        # console.log 'set:', index, tracker.store[index], '->', value
        work = ->
          if arguments.length
            value = arguments[0]
          if tracker.store[index] is value
            return false
          tracker.store[index] = value
          true

        if tracker.set
          tracker.set index, value, work
        else
          work()

      @add: (tracker, items, index) ->
        {list, store} = tracker
        items_len = items.length
        orig_len  = list.length

        # copy to right
        for i in [orig_len - 1 .. index] by -1
          store[i + items_len] = store[i]

        for item, i in items
          list[i + orig_len] = null
          ArrayTracker.getterify tracker, i + orig_len
          ArrayTracker.set tracker, i + index, item

        list.length

      @_pop: ->
        {list, store} = @
        if (index = list.length - 1) > -1
          res = list[index]
          list.length = index
          delete store[index]
          return res

      @_shift: ->
        {list, store} = @
        if (index = list.length - 1) > -1
          res = list[0]
          for i in [1 .. index] by 1
            store[i - 1] = store[i]
          list.length = index
          delete store[index]
          return res

      @_push: (items...) ->
        ArrayTracker.add @, items, @list.length

      @_unshift: (items...) ->
        ArrayTracker.add @, items, 0

      @_splice: (index, how_many, items...) ->
        {list, store} = @

        res = []

        orig_len = list.length

        index = parseInt(index, 10) or 0
        if index < 0
          index = Math.max 0, orig_len + index
        else
          index = Math.min index, orig_len

        how_many = parseInt(how_many, 10) or 0
        how_many = Math.max 0, Math.min how_many, orig_len - index

        if how_many
          for i in [index ... index + how_many] by 1
            res.push list[i]
            delete store[orig_len + i - index]
          for i in [index ... orig_len] by 1
            store[i] = store[i + how_many]
          list.length = orig_len - how_many

        if items.length
          ArrayTracker.add @, items, index

        res

      @_sort: (args...) ->
        {list, store} = tracker = @
        copy = (store[i] for i in [0 ... list.length] by 1)
        list.length = 0
        Array::push.apply list, copy
        res = Array::sort.apply list, args
        for value, index in list
          ArrayTracker.getterify tracker, index
          ArrayTracker.set tracker, index, value
        res
]
