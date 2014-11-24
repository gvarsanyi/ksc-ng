
ksc.factory 'ksc.trackArray', [
  'ksc.error', 'ksc.util',
  (error, util) ->

    define_get_set = util.defineGetSet
    define_value   = util.defineValue
    has_own        = util.hasOwn


    define_getter = (tracker, list, store, index) ->
      define_get_set list, index, (-> get_fn store, tracker.getter, index),
                     ((val) -> set_fn store, tracker.setter, index, val), 1

    get_fn = (store, getter, index) ->
      if getter
        getter index, store[index]
      store[index]

    set_fn = (store, setter, index, value) ->
      work = ->
        if arguments.length
          value = arguments[0]
        if store[index] is value
          return false
        store[index] = value
        true

      if setter
        setter index, value, work
      else
        work()


    class TrackedArray
      get:   undefined
      list:  undefined
      set:   undefined
      store: undefined

      constructor: (@list, @store={}, setter, getter) ->
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
          unless fn?
            fn = null
          else unless typeof fn is 'function'
            error.Type {fn, 'Must be a function'}
          fn

        getter = fnize getter
        setter = fnize setter

        define_get_set tracker, 'get', getter, ((fn) -> getter = fnize fn), 1
        define_get_set tracker, 'set', setter, ((fn) -> setter = fnize fn), 1

        for value, index in list
          define_getter tracker, list, store, index
          set_fn store, setter, index, value

        return list


    (args...) ->
      new TrackedArray args...




      for fn in ['push', 'unshift', 'splice']
        orig_fn = arr[fn]
        do (orig_fn, fn) ->
          decor = (args...) ->
            orig_len = cache_arr.length
            cache    = {}
            for k, v of store
              cache[k] = v

            for item, i in arr
              define_value arr, i, get_fn(i), 1, 1

            try
              res = orig_fn.apply @, args
              check_indexes()
            catch err
              Util.empty arr, store
              arr.push (item for item in cache_arr)...
              for k, v of cache_store
                store[k] = v
              throw err
            res
          define_value arr, fn, decor, 0

      define_value arr, 'pop', ->
        idx = arr.length - 1
        res = arr[idx]
        delete store[idx]
        arr.length = idx
        res

      define_value arr, 'shift', ->
        idx = arr.length - 1
        res = arr[idx]
        for i in [0 ... idx] by 1
          store[i] = store[i + 1]
        delete store[idx]
        arr.length = idx
        res

      define_value arr, 'splice', (start, cut, add...) ->
        len = arr.length
        if start < 0
          start = Math.min 0, len + start
        else if start > len
          start = len

        for i in [0 ... idx] by 1
          store[i] = store[i + 1]

        idx = arr.length - 1
        res = arr[idx]
        for i in [0 ... idx] by 1
          store[i] = store[i + 1]
        delete store[idx]
        arr.length = idx
        res

      arr
]
