
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
      @method #set(index, value, next, set_type)
        Inject setter logic or set to/leave as null for default behavior
        (elements stored as-is). See second example in class def.

        @note It is also used for re-setting values after temporarly turning
          values into plain values (e.g. for using native sort() ot reverse()
          methods)

        @param [number] index of element in array
        @param [mixed] value to be set
        @param [function] next call when your biz logic is ready. Takes 0 or 1
          argument. If argument is provided that will be stored as value.
        @param [string] set_type Any of the following values:
          - 'external': coming from oustide by updating an element or adding new
          - 'move': previously processed element moved to new index (after pop,
            unshift or splice)
          - 'reload': after temporarly reloading array with processed values,
            values receive updated indexes (sort and reverse)

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

        process tracker

      ###
      Detach tracker from array, revert to plain values and restore original
      methods for pop, shift, push, unshift, splice, reverse, sort.

      @return [void]
      ###
      unload: ->
        {list, store} = tracker = @
        plainify tracker

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
            set_element tracker, i + items_len, store[i], 'move'

        for value, i in items
          set_element tracker, i + index, value
          if move_to_right
            ArrayTracker.getterify tracker, i + orig_len

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
      {ArrayTracker.add}, {process} and {ArrayTracker._splice}

      @param [ArrayTracker] tracker
      @param [number] index

      @return [void]
      ###
      @getterify: (tracker, index) ->
        define_get_set tracker.list, index,
                       (-> ArrayTracker.getElement tracker, index),
                       ((val) -> set_element tracker, index, val), 1
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
      @param [string] set_type (optional) Process name (e.g. 'reload') or new
        elements if not provided.

      @return [void]
      ###
      @process: (tracker, set_type) ->
        for value, index in tracker.list
          ArrayTracker.getterify tracker, index
          set_element tracker, index, value, set_type
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
            set_element tracker, i - 1, store[i], 'move'
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
      @param [string] set_type undefined='external' or 'move' or 'reload'

      @return [void]
      ###
      @setElement: (tracker, index, value, set_type) ->
        # console.log '@set:', index, tracker.store[index], '->', value
        work = ->
          if arguments.length
            value = arguments[0]
          if tracker.store[index] is value
            return false
          tracker.store[index] = value
          true

        if tracker.set
          tracker.set index, value, work, set_type or 'external'
        else
          work()
        return

      ###
      Override function that replaces original .pop() method of the tracked
      array. From the user's standpoint, it behaves exactly like Array::pop()

      Removes and returns the last element of the array.

      If defined on tracker, the following handlers will be triggered:
        - {ArrayTracker#get}(index, value) for the popped (last) element
        - {ArrayTracker#del}(index, value) for the last element

      @return [mixed] popped value or undefined if the array was empty
      ###
      @_pop: ->
        ArrayTracker.rm @, @list.length - 1

      ###
      Override function that replaces original .shift() method of the tracked
      array. From the user's standpoint, it behaves exactly like Array::shift()

      Removes and returns the first element of the array.

      If defined on tracker, the following handlers will be triggered:
        - {ArrayTracker#get}(index, value) for the shifted (first) element
        - {ArrayTracker#set}(index, value, next_fn, true) for all remaining
          elements as the move left
        - {ArrayTracker#del}(index, value) for the last element

      @return [mixed] popped value or undefined if the array was empty
      ###
      @_shift: ->
        ArrayTracker.rm @, 0

      ###
      Override function that replaces original .push() method of the tracked
      array. From the user's standpoint, it behaves exactly like Array::push()

      Appends element(s) to the end of the array.

      If defined on tracker, the following handler will be triggered:
        - {ArrayTracker#set}(index, value, next_fn, false) for all new elements

      @param [mixed] items... Elements to add

      @return [number] the new length of the array
      ###
      @_push: (items...) ->
        ArrayTracker.add @, items, @list.length

      ###
      Override function that replaces original .unshift() method of the tracked
      array. From the user's standpoint, it behaves exactly like
      Array::unshift()

      Prepends array with the provided element(s).

      If defined on tracker, the following handler will be triggered:
        - {ArrayTracker#set}(index, value, next_fn, false) for all new elements
        - {ArrayTracker#set}(index, value, next_fn, true) for all previously
          existing elements pushed to the right

      @param [mixed] items... Elements to add

      @return [number] the new length of the array
      ###
      @_unshift: (items...) ->
        ArrayTracker.add @, items, 0

      ###
      Override function that replaces original .splice() method of the tracked
      array. From the user's standpoint, it behaves exactly like Array::splice()

      Cuts a part out of the array and/or inserts element(s) starting at a
      provided index.

      If defined on tracker, the following handler will be triggered:
        - {ArrayTracker#get}(index, value) for the cut elements
        - {ArrayTracker#del}(index, value) for the cut elements
        - {ArrayTracker#set}(index, value, next_fn, false) for all new elements
        - {ArrayTracker#set}(index, value, next_fn, true) for all previously
          existing elements pushed to either left (if how_many > n new items) or
          right (if how_many < n new items)

      @param [number] index Index to start cutting/inserting at
      @param [number] how_many Number of elements to cut
      @param [mixed] items... Elements to add

      @return [array] a list of cut elements
      ###
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
          set_element tracker, i - how_many + items_len, store[i], 'move'

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
          ArrayTracker.add tracker, items, index, 0

        res

      ###
      Override function that replaces original .sort() method of the tracked
      array. From the user's standpoint, it behaves exactly like Array::sort()

      Sorts the array based on default sort or provided sort function.

      Will turn the array into a plain-values array based on stored values and
      {ArrayTracker#get} if defined.
      After sorting, will turn it back to a getter/setter array saving new
      values back to store and using {ArrayTracker#set} if defined.

      If defined on tracker, the following handler will be triggered:
        - {ArrayTracker#get}(index, value) for all elements
        - {ArrayTracker#set}(index, value, next_fn, false) for all elements

      @param [function] fn (optional) sort function that returns <0, 0 or >0

      @return [array] returns the tracked array itself
      ###
      @_sort: (fn) ->
        tracker = @
        plainify tracker
        res = Array::sort.call tracker.list, fn
        process tracker, 'reload'
        res

      ###
      Override function that replaces original .reverse() method of the tracked
      array. From the user's standpoint, it behaves exactly like
      Array::reverse()

      Reverses array elements.

      Will turn the array into a plain-values array based on stored values and
      {ArrayTracker#get} if defined.
      After sorting, will turn it back to a getter/setter array saving new
      values back to store and using {ArrayTracker#set} if defined.

      If defined on tracker, the following handler will be triggered:
        - {ArrayTracker#get}(index, value) for all elements
        - {ArrayTracker#set}(index, value, next_fn, false) for all elements

      @return [array] returns the tracked array itself
      ###
      @_reverse: ->
        tracker = @
        plainify tracker
        res = Array::reverse.call tracker.list
        process tracker, 'reload'
        res


    plainify    = ArrayTracker.plainify
    process     = ArrayTracker.process
    set_element = ArrayTracker.setElement


    ArrayTracker
]
