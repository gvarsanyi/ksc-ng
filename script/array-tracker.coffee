
ksc.factory 'ksc.ArrayTracker', [
  'ksc.error', 'ksc.util',
  (error, util) ->

    define_get_set = util.defineGetSet
    define_value   = util.defineValue
    has_own        = util.hasOwn


    class ArrayTracker
      get:    undefined
      list:   undefined
      origFn: undefined
      set:    undefined
      store:  undefined

      constructor: (list, store={}, functions={}) ->
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
        define_value tracker, 'origFn', orig_fn = {}

        fnize = (fn) ->
          if fn?
            unless typeof fn is 'function'
              error.Type {fn, 'Must be a function'}
          else
            fn = null
          fn

        for key in fns = ['del', 'get', 'set']
          functions[key] ?= null
        for key, fn of functions
          unless key in fns
            error.Value {fn: key, description: 'handled: ' + fns}
          functions[key] = fnize fn
          do (key) ->
            define_get_set tracker, key, (-> functions[key] or null),
                           ((fn) -> functions[key] = fnize fn), 1

        for key, fn of ArrayTracker when key.substr(0, 1) is '_'
          key = key.substr 1
          orig_fn[key] = if has_own(list, key) then {v: list[key]} else {n: 1}
          do (key) ->
            define_value list, key, (args...) ->
              ArrayTracker['_' + key].apply tracker, args

        tracker.process()

      plainify: ->
        {list, store} = @
        copy = (store[i] for i in [0 ... list.length] by 1)
        list.length = 0
        Array::push.apply list, copy
        return

      process: ->
        tracker = @
        for value, index in tracker.list
          ArrayTracker.getterify tracker, index
          ArrayTracker.set tracker, index, value
        return

      unload: ->
        {list, store} = tracker = @
        tracker.plainify()

        for key, inf of tracker.origFn
          if inf.n
            delete list[key]
          else
            define_value list, key, inf.v

        delete tracker.list._tracker
        delete tracker.list

        util.empty store
        return

      @getterify: (tracker, index) ->
        define_get_set tracker.list, index,
                       (-> ArrayTracker.get tracker, index),
                       ((value) -> ArrayTracker.set tracker, index, value), 1

      @get: (tracker, index) ->
        # console.log '@get:', index, tracker.store[index], '::'
        if tracker.get
          return tracker.get index, tracker.store[index]
        tracker.store[index]

      @set: (tracker, index, value, moving) ->
        # console.log '@set:', index, tracker.store[index], '->', value
        work = ->
          if arguments.length
            value = arguments[0]
          if tracker.store[index] is value
            return false
          tracker.store[index] = value
          true

        if tracker.set
          tracker.set index, value, work, moving
        else
          work()

      @add: (tracker, items, index, move_to_right=true) ->
        {list, store} = tracker
        items_len = items.length
        orig_len  = list.length

        # copy to right
        if move_to_right and orig_len > index
          for i in [orig_len - 1 .. index] by -1
            ArrayTracker.set tracker, i + items_len, store[i], true

        for value, i in items
          if move_to_right
            ArrayTracker.getterify tracker, i + orig_len
          ArrayTracker.set tracker, i + index, value

        list.length

      @del: (tracker, index) ->
        {list, store} = tracker
        if list.length
          orig_len  = list.length
          res       = list[index]
          for i in [index + 1 ... orig_len] by 1
            ArrayTracker.set tracker, i - 1, store[i], true
          if del = tracker.del
            deletable = store[orig_len - 1]
          delete store[orig_len - 1]
          list.length = orig_len - 1
          del? orig_len - 1, deletable
          res

      @_pop: ->
        ArrayTracker.del @, @list.length - 1

      @_shift: ->
        ArrayTracker.del @, 0

      @_push: (items...) ->
        ArrayTracker.add @, items, @list.length

      @_unshift: (items...) ->
        ArrayTracker.add @, items, 0

      @_splice: (index, how_many, items...) ->
        {list, store} = tracker = @

        items_len = items.length
        orig_len  = list.length

        index = parseInt(index, 10) or 0
        if index < 0
          index = Math.max 0, orig_len + index
        else
          index = Math.min index, orig_len

        how_many = parseInt(how_many, 10) or 0
        how_many = Math.max 0, Math.min how_many, orig_len - index

        res = list[index ... index + how_many]

        move = (i) ->
          ArrayTracker.set tracker, i - how_many + items_len, store[i], true

        if how_many > items_len # cut_count >= 1
          for i in [index + how_many ... orig_len] by 1
            move i
          for i in [orig_len - how_many + items_len ... orig_len] by 1
            ArrayTracker.del tracker, i
        else if how_many < items_len # copy to right
          for i in [orig_len - 1 .. index + how_many] by -1
            move i

        if items_len
          for i in [how_many ... items_len] by 1
            ArrayTracker.getterify tracker, i + orig_len
          ArrayTracker.add tracker, items, index, false

        res

      @_sort: (args...) ->
        tracker = @
        tracker.plainify()
        res = Array::sort.apply tracker.list, args
        tracker.process()
        res

      @_reverse: ->
        tracker = @
        tracker.plainify()
        res = Array::reverse.call tracker.list
        tracker.process()
        res
]
