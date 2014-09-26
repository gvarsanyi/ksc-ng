
app.factory 'ksc.ListSorter', [
  'ksc.error', 'ksc.util',
  (error, util) ->

    define_value   = util.defineValue
    is_key_conform = util.isKeyConform

    ###
    Class definition for auto-sort definition at {List#sorter}

    @example
        # must return a numeric value, preferrably -1, 0 or 1
        my_sorter_fn = (a, b) -> # sort by id
          if a._id >= b._id then 1 else -1

        list = new list
        list.sorter = my_sorter_fn

        # you may also pass it as part of the options argument, the result
        # will be moved to list.sorter though
        list = new list
          sorter: my_sorter_fn

    @example
        # strings or arrays will be turned into sorter description objects
        list = new list
        list.sorter = 'name'
        # will be turned into:
        # list.sorter = # [ListSorter]
        #   key:     'name'
        #   reverse: false # A -> Z
        #   type:    'natural'

    @example
        list = new list
        list.sorter =
          key:     ['lastName', 'firstName']
          reverse: true # Z -> A
          type:    'natural' # other possible values: 'number', 'byte'

    @author Greg Varsanyi
    ###
    class ListSorter

      # @property [function] sorter function with signiture `(a, b) ->` that
      #   should return a number, preferrably -1, 0 and 1
      #   can be an external function or generated off of description object
      fn: null

      # @property [string|Array] key or keys used for sorting (null if external
      #   function is used)
      key: null

      # @property [Array] reference to array created by {List}
      list: null

      # @property [boolean] triggers reverse-ordering
      #   (null if external function is used)
      reverse: null

      ###
      @property [string] sorting type, possible values
        - 'byte': compare based on ASCII/UTF8 character value (stringifies vals)
        - 'natural': human-perceived "natural" order, case-insensitive (default)
        - 'number': number-ordering, falls back to natural for non-numbers
        (null if external function is used)
      ###
      type: null


      ###
      Creates ListSorter object

      @param [List] list reference to Array created by {List}
      @param [string|Array|object|function] description external sort function
        or sort logic description
      @option sorter [string|Array] key key or keys used for sorting
      @option sorter [boolean] reverse sorting order (defaults to false)
      @option sorter [string] type sort method: 'natural', 'number', 'byte' -
        see: {ListSorter#type}

      @throw [ValueError] if a sorter value is errorous
      ###
      constructor: (list, description) ->
        sorter = @

        define_value sorter, 'list', list, 0, 0

        if typeof description is 'function'
          sorter.fn = description
        else # description
          if is_key_conform(description) or description instanceof Array
            description = key: description

          unless util.isObject(description) and
          (is_key_conform(key = description.key) or key instanceof Array)
            error.Value
              sorter:      description
              requirement: 'function or string or array or object: ' +
                           '{key: <string|array>, reverse: <bool>, type: ' +
                           '\'natural|number|byte\'}'

          if type = description.type
            unless type in ['byte', 'natural', 'number']
              error.Value {type, required: 'byte, natural or number'}
          else
            type = 'natural'

          define_value sorter, 'key',     key, 0, 1
          define_value sorter, 'reverse', !!description.reverse, 0, 1
          define_value sorter, 'type',    type, 0, 1

          define_value sorter, 'fn', ListSorter.getSortFn(sorter), 0, 1

        Object.preventExtensions sorter


      ###
      Find a new Record's position in a sorted list

      @param [Record] record Instance of record that needs a position

      @throw [TypeError] If the sorter function returns a non-numeric value

      @return [number] position
      ###
      position: (record) ->
        sorter  = @
        compare = sorter.fn
        list    = sorter.list

        unless len = list.length
          return 0

        min = 0
        max = len - 1

        cmp_check = (value) ->
          if typeof value isnt 'number' or isNaN value
            error.Type {sort_fn_output: value, required: 'number'}
          value

        if cmp_check(compare record, list[min]) < 0
          return min
        if len is 1
          return 1

        if cmp_check(compare record, list[max]) >= 0
          return max + 1

        find_in = (min, max) ->
          if min < max - 1 # has item(s) in between
            mid = Math.floor (max - min) / 2 + min

            if cmp_check(compare record, list[mid]) < 0
              return find_in min, mid
            return find_in mid, max

          max # pushes the bigger one to right

        find_in min, max


      ###
      Helper method that generates a sorter/comparison function

      Type 'number' sorts fall back to natural sort on anything that is either
      - (not typeof 'number' or 'string') or
      - typeof 'string' but is empty or Number(anything) returns NaN

      Natural sort will produce the same result on numbers as 'number' sort, but
      'number' on numbers is faster.

      @param [ListSorter] sorter ListSorter instance to get sorter function for

      @return [function] sorter/comparison function with signiture `(a, b) ->`
      ###
      @getSortFn: (sorter) ->
        {key, reverse, type} = sorter

        reverse = if reverse then -1 else 1

        joint = (obj, parts) ->
          (obj[part] for part in parts when obj[part]?).join ' '

        numerify = (n) ->
          unless typeof n is 'number'
            if typeof n is 'string' and n isnt ''
              return Number n
            else
              return NaN
          n

        natural_cmp = (as, bs) ->
          as = String(as).toLowerCase()
          bs = String(bs).toLowerCase()

          i  = 0
          rx = /(\.\d+)|(\d+(\.\d+)?)|([^\d.]+)|(\.\D+)|(\.$)/g

          if as is bs
            return 0

          a = as.toLowerCase().match rx
          b = bs.toLowerCase().match rx
          L = if a? then a.length else 0
          while (i < L)
            if (not b?) or b[i] is undefined
              return 1

            a1 = a[i]
            b1 = b[i]
            i += 1

            n = a1 - b1
            unless isNaN n
              return n

            return if a1 >= b1 then 1 else -1
          -1

        # sort function
        (a, b) ->
          if is_key_conform key
            a = a[key]
            b = b[key]
          else # Array
            a = joint a, key
            b = joint b, key

          if type is 'number'
            _a = a
            _b = b
            a = numerify a
            b = numerify b
            if isNaN a
              if isNaN b
                return natural_cmp(_a, _b) * reverse
              return -1 * reverse
            if isNaN b
              return 1 * reverse
          else
            a ?= ''
            b ?= ''

          if type is 'natural'
            return natural_cmp(a, b) * reverse
          else if type is 'byte'
            a = String a
            b = String b

          if a is b
            return 0

          (if a > b then 1 else -1) * reverse

      ###
      Helper method that registers a sorter getter/setter on an Array created
      by {List} or {ListMask}

      @param [List] list reference to the list (not) to be auto-sorted
      @param [null|function|object|string|Array] description sort logic
        description, see: {ListSorter} and {ListSorter#constructor}

      @return [undefined]
      ###
      @register: (list, description) ->
        sorter = null

        if description
          sorter = new ListSorter list, description

        getter = ->
          sorter

        setter = (description) ->
          if description
            sorter = new ListSorter list, description
            Array::sort.call list, sorter.fn # re-sort
            list.events.emit 'update', {node: list, action: {sort: true}}
          else
            sorter = null

        util.defineGetSet list, 'sorter', getter, setter, 1
        util.defineGetSet list.options, 'sorter', getter, setter, 1

        return
]
