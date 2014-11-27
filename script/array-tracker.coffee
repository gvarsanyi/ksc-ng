
ksc.factory 'ksc.ArrayTracker', [
  'ksc.error', 'ksc.util',
  (error, util) ->

    define_get_set = util.defineGetSet
    define_value   = util.defineValue
    has_own        = util.hasOwn
    is_array       = Array.isArray
    is_object      = util.isObject


    ###
    Almost proper getter/setter support for native JavaScript Arrays.

    Pass a vanilla Array to constructor and it will:
    - attach itself to the array as ._tracker
    - replace all elements with getters and setters while move actual values to
      a store object
    - replace methods that change contents: pop, shift, push, unshift, splice,
      sort, reverse
    - provide event handlers allowing extra logic in element get, set, delete

    @example
        # Stringify output but store original value
        arr = [1, 2, 3]
        new ArrayTracker arr,
          get: (index, value) ->
            return String value
        console.log arr # ["1", "2", "3"]

        # >=1 number only array
        arr = [1, 2, 3]
        new ArrayTracker arr,
          set: (index, value, next) ->
            unless value >= 1
              throw new Error 'Values must be numbers >= 1'
            next()
        arr.push 4    # OK
        arr.push true # Error!

    @note Adding element to a new position can not be tracked.
    @example
        arr = [1, 2, 3]
        new ArrayTracker arr
        arr.push 4 # proper way of adding an element
        arr[4] = 5 # will just store plain value, not a getter/setter

    @author Greg Varsanyi
    ###
    class ArrayTracker

      ###
      @method #del(index, value)
        Indicates that element was deleted from a certain index (always the end
        of the array)

        @param [number] index of deleted element in array
        @param [mixed] stored value of the element

        @return [mixed] whetever you define. Return value will not be used
      ###

      ###
      @method #get(index, value)
        Inject getter logic for array elements (see first example in class def)

        @note It is also used for reading values when temporarly turning values
          into plain values (e.g. for using native sort() ot reverse() methods)

        @param [number] index of element in array
        @param [mixed] value stored for the element

        @return [mixed] this will be used as element value in the array
      ###

      ###
      @method #set(index, value)
        Inject setter logic or set to/leave as null for default behavior
        (elements stored as-is). See second example in class def.

        @note It is also used for re-setting values after temporarly turning
          values into plain values (e.g. for using native sort() ot reverse()
          methods)

        @param [number] index of element in array
        @param [mixed] value to be set
        @param [function] call when your biz logic is ready. Takes 0 or 1
          argument. If argument is provided that will be stored as value.
        @param [boolean] True indicates that value is originated in the store
          (i.e. was already altered if you alter values). It happens when
          elements move to the left or to the right (for example when .shift()
          or .unshift() methods are used and elements move around)

        @return [mixed] whetever you define. Return value will not be used
      ###

      # @property [Array] reference to the original array
      list: undefined

      # @property [Object] store for original/overridden properties of the
      #   referenced array (hidden: not enumerable)
      origFn: undefined

      # @property [Object] reference to value store object
      store: undefined


      ###
      Create the ArrayTracker instance and attach it to the provided array

      @throw [ArgumentTypeError] list, options type mismatch
      @throw [ValueError] if array is already tracked

      @param [array] Array to track
      @param [object] options (optional) you may add handler functions and/or
        a store object here: del, get, set and sotre will be picked up.

      ###
      constructor: (list, options={}) ->
        if has_own list, '_tracker'
          error.Value {list, description: 'List is already tracked'}
        unless is_array list
          error.ArgumentType
            argument:    1
            list:        list
            description: 'Must be an array'
        unless is_object options
          error.ArgumentType
            argument:    2
            options:     options
            description: 'Must be an object'

        store = if has_own(options, 'store') then options.store else {}
        unless is_object store
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

        functions = {}
        for key in ['del', 'get', 'set']
          functions[key] = options[key] or null
        for key, fn of functions
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

        ArrayTracker.process tracker

      ###
      Detach tracker from array, revert to plain values and restore original
      methods for pop, shift, push, unshift, splice, reverse, sort.

      @return [void]
      ###
      unload: ->
        {list, store} = tracker = @
        ArrayTracker.plainify tracker

        for key, inf of tracker.origFn
          if inf.n
            delete list[key]
          else
            define_value list, key, inf.v

        delete tracker.list._tracker
        delete tracker.list

        util.empty store
        return


      ###
      Helper function that inserts elements to a given index while pushing
      existing elements to the right (if needed). Used by {ArrayTracker._push},
      {ArrayTracker._unshift} and {ArrayTracker._splice}

      @param [ArrayTracker] tracker
      @param [array] items Values to be inserted
      @param [number] index Insertation point
      @param [boolean] move_to_right Whether to push elements to the right.
        {ArrayTracker._splice} has its own logic to do that, hence the need for
        this flag

      @return [number] new length of the array
      ###
      @add: (tracker, items, index, move_to_right=true) ->
        {list, store} = tracker
        items_len = items.length
        orig_len  = list.length

        # copy to right
        if move_to_right and orig_len > index
          for i in [orig_len - 1 .. index] by -1
            ArrayTracker.setElement tracker, i + items_len, store[i], 1

        for value, i in items
          if move_to_right
            ArrayTracker.getterify tracker, i + orig_len
          ArrayTracker.setElement tracker, i + index, value

        list.length

      ###
      Helper function that is used by element getters and element reading
      functions to return stored value or - if defined - trigger user-defined
      {ArrayTracker#get} function

      @param [ArrayTracker] tracker
      @param [number] index

      @return [mixed] value
      ###
      @getElement: (tracker, index) ->
        # console.log '@get:', index, tracker.store[index], '::'
        if tracker.get
          return tracker.get index, tracker.store[index]
        tracker.store[index]

      ###
      Helper function that turns an element into getter/setter. Used by
      {ArrayTracker.add}, {ArrayTracker.process} and {ArrayTracker._splice}

      @param [ArrayTracker] tracker
      @param [number] index

      @return [void]
      ###
      @getterify: (tracker, index) ->
        define_get_set tracker.list, index,
                       (-> ArrayTracker.getElement tracker, index),
                       ((val) -> ArrayTracker.setElement tracker, index, val), 1
        return

      ###
      Helper function that updates array with plain values. Used by
      {ArrayTracker#unload}, {ArrayTracker._reverse} and {ArrayTracker._sort}

      @param [ArrayTracker] tracker

      @return [void]
      ###
      @plainify: (tracker) ->
        {list, store} = tracker
        copy = (store[i] for i in [0 ... list.length] by 1)
        list.length = 0
        Array::push.apply list, copy
        return

      ###
      Helper function that turns plain values into getters/setters and stores
      values. Used by {ArrayTracker#constructor}, {ArrayTracker._reverse} and
      {ArrayTracker._sort}

      @param [ArrayTracker] tracker

      @return [void]
      ###
      @process: (tracker) ->
        for value, index in tracker.list
          ArrayTracker.getterify tracker, index
          ArrayTracker.setElement tracker, index, value
        return

      ###
      Helper function that removes an element from index while pushing
      existing elements to the left (if needed). Used by {ArrayTracker._pop},
      {ArrayTracker._shift} and {ArrayTracker._splice}

      @param [ArrayTracker] tracker
      @param [number] index Insertation point

      @return [mixed] stored value of the removed element (or void if nothing
        was removed e.g. when array is empty.
      ###
      @rm: (tracker, index) ->
        {list, store} = tracker
        if list.length
          orig_len  = list.length
          res       = list[index]
          for i in [index + 1 ... orig_len] by 1
            ArrayTracker.setElement tracker, i - 1, store[i], 1
          if del = tracker.del
            deletable = store[orig_len - 1]
          delete store[orig_len - 1]
          list.length = orig_len - 1
          del? orig_len - 1, deletable
          res

      ###
      Helper function that is used by element setters and functions that
      store values. If provided, it triggers a user defined {ArrayTracker#set}
      method. Otherwise it will store value as-is.

      @param [ArrayTracker] tracker
      @param [number] index
      @param [mixed] value
      @param [boolean] moving Indicates if element was moved around (e.g. value
        reflects previously processed stored value, not new incoming value)

      @return [void]
      ###
      @setElement: (tracker, index, value, moving) ->
        # console.log '@set:', index, tracker.store[index], '->', value
        work = ->
          if arguments.length
            value = arguments[0]
          if tracker.store[index] is value
            return false
          tracker.store[index] = value
          true

        if tracker.set
          tracker.set index, value, work, !!moving
        else
          work()
        return

      @_pop: ->
        ArrayTracker.rm @, @list.length - 1

      @_shift: ->
        ArrayTracker.rm @, 0

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
          ArrayTracker.setElement tracker, i - how_many + items_len, store[i], 1

        if how_many > items_len # cut_count >= 1
          for i in [index + how_many ... orig_len] by 1
            move i
          for i in [0 ... how_many - items_len] by 1
            ArrayTracker.rm tracker, orig_len - i - 1
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
        ArrayTracker.plainify tracker
        res = Array::sort.apply tracker.list, args
        ArrayTracker.process tracker
        res

      @_reverse: ->
        tracker = @
        ArrayTracker.plainify tracker
        res = Array::reverse.call tracker.list
        ArrayTracker.process tracker
        res
]
