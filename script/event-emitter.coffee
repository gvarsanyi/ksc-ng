
ksc.factory 'ksc.EventEmitter', [
  '$interval', '$rootScope', '$timeout', 'ksc.error', 'ksc.util',
  ($interval, $rootScope, $timeout, error, util) ->

    UNSUBSCRIBER = '__unsubscriber__'

    argument_type_error = error.ArgumentType

    is_function = util.isFunction
    is_object   = util.isObject

    ###
    A class used by EventEmitter to store and manage callbacks.

    @author greg.varsanyi@kareo.com
    ###
    class EventSubscriptions
      # @property [object] names storage for subsctiptions per type
      names: undefined #DOC-ONLY#

      ###
      Emission logic

      @param [string] name event identifier
      @param [*] args... optional arguments to be passed to the callback fn

      @return [boolean] indicates if at least one callback fn was called
      ###
      emit: (name, args...) ->
        names = (@names ?= {})
        block = (names[name] ?= {})
        callback_found = false
        block.fired = (block.fired or 0) + 1
        block.lastArgs = args
        for once in [0, 1] when block[once]
          for id, callback of block[once] when is_function callback
            callback_found = true
            if once
              delete block[once][id]
            callback args...

        callback_found

      ###
      Calls the callback fn if the event was fired before (with the arguments of
      the last emission). Synchronous, will return after the callback is called.
      Used by EventEmitter.if() and EventEmitter.if1()

      @param [string] name event identifier
      @param [function] callback

      @return [boolean] indicates if a callback fn was called
      ###
      instantCall: (name, callback) ->
        names = (@names ?= {})
        if names[name]?.fired
          callback names[name].lastArgs...
          return true
        false

      ###
      Registers one ore more new event subscriptions

      @param [string] names... event identifier(s)
      @param [boolean] once indicates one-time subscription (if1 and on1)
      @param [function] callback

      @return [function] unsubscriber
      ###
      push: (names, once, callback) ->
        subscription_names = (@names ?= {})
        ids  = []
        once = if once then 1 else 0
        for name in names
          subscription_names[name] ?= {}
          block = (subscription_names[name][once] ?= i: 0)
          block[block.i] = callback
          ids.push {name, id: block.i}
          block.i += 1

        unsubscribed = false

        # create empty unsubscriber
        fn = EventEmitter::unsubscriber()

        # add this event unsubscriber
        pseudo_unsubscriber = ->
          return false if unsubscribed
          unsubscribed = true
          for inf in ids
            delete subscription_names[inf.name][once][inf.id]
          true
        pseudo_unsubscriber[UNSUBSCRIBER] = true

        fn.add pseudo_unsubscriber
        fn


    name_check = (name) ->
      unless typeof name is 'string'
        argument_type_error {name, argument: 1, required: 'string'}

      unless name
        error.Value {name, description: 'must be a non-empty string'}


    subscription_decorator = (names, unsubscribe_target, callback, next) ->
      @subscriptions ?= new EventSubscriptions

      unless is_function callback
        argument_type_error {callback, argument: 'last', required: 'function'}

      unless unsubscribe_target?[UNSUBSCRIBER] or
      (is_object(unsubscribe_target) and
       scope = $rootScope.isPrototypeOf unsubscribe_target)
        names.push unsubscribe_target
        unsubscribe_target = null

      for name in names
        name_check name

      unsubscriber_fn = next.call @

      if unsubscribe_target
        if scope
          unsubscribe_target.$on '$destroy', unsubscriber_fn
        else
          unsubscribe_target.add unsubscriber_fn
        return true

      unsubscriber_fn


    ###
    # EventEmitter

    @author greg.varsanyi@kareo.com

    This class is meant to be extended by classes that may emit events outside
    Angular controllers' $broadcast/$emit concept (like service-service
    communication).

    ## API
    1. __Classic event listener__
            unsubscriber = event_obj.on('event'[, 'event2', ...], callback)
    2. __One-time event listener__
            unsubscriber = event_obj.on1('event'[, 'event2', ...], callback)
    3. __Event listener with instant callback if the event happened before__
            unsubscriber = event_obj.if('event'[, 'event2', ...], callback)
    4. __One-time event listener OR instant callback if the event happened
    before__
            unsubscriber = event_obj.if1('event'[, 'event2', ...], callback)
    5. __Emit event__
            event_obj.emit('event'[, args...]) # args are passed to listeners
    6. __Check if event was emitted before__
            event_obj.emitted('event') # returns false or latest call args array
    7. __Unsubscribe__
    Use the returned unsubscriber function:
            unsubscriber = event_obj.on('event', callback)
            unsubscriber() # callback won't get called on 'event'
    Unsubscribers are chainable with the .add method on the function
            unsubscriber = event_obj.on('event', callback)
            unsubscriber.add other_event_obj.if1('event2', callback)
            unsubscriber() # both subscriptions get removed
    You can pass your $scope while in a controller scope:
            # triggers an unsubscription with $scope.$on('$destroy', unsub_fn)
            event_obj.on('event', $scope, callback)
    With this signiture above you can also chain unsubscriber:
            # This is the preferred way for .if() and .if1() as those may call
            # the callback fn before the unsubscribe function is created as a
            # return value
            unsubscriber = event_obj.unsubscriber()
            event_obj.if1 'event', unsubscriber, ->
              other_event_obj.if1 'event', unsubscriber, ->

    Don't forget to unsubscribe when you destroy a scope. Not unsubscribing
    prevents garbage collection from running right and calling references on
    supposedly removed objects may lead to unexpected behavior.
    ###
    class EventEmitter

      ###
      Emit event, e.g. call all functions subscribed for the specified event.

      @param [string] name event identifier
      @param [*] args... optional arguments to be passed to the callback fn

      @throw [ArgumentTypeError] name is not a string
      @throw [ValueError] name is empty

      @return [boolean] indicates if anything was called
      ###
      emit: (name, args...) ->
        name_check name

        if @_halt
          name = @_halt + '#!' + name

        (@subscriptions ?= new EventSubscriptions).emit name, args...

      ###
      Check if this even was emitted before by the object.
      If so, it returns an array of the arguments of last emission which is
      the "args..." part of the emit(name, args...) method.

      @param [string] name event identifier

      @throw [ArgumentTypeError] name is not a string
      @throw [ValueError] name is empty

      @return [boolean|Array] false or Array of arguments
      ###
      emitted: (name) ->
        name_check name

        if (subscriptions = @subscriptions?.names[name])?.fired
          return subscriptions.lastArgs
        false

      ###
      Prevent emit() from emitting.

      Bumps a counter, so you can define multi-level halters.

      Warning: all halt() calls should be coupled with exactly 1 unhalt() or
      things get messy.

      @return [number] updated halt level
      ###
      halt: ->
        @_halt = (@_halt or 0) + 1

      ###
      Enable emit() to emit again.

      Decreases the halt a counter.

      Warning: all halt() calls should be coupled with exactly 1 unhalt() or
      things get messy.

      @return [number] updated halt level
      ###
      unhalt: ->
        @_halt -= 1

      ###
      Subscribe for 1 event in the future OR the last emission if there was one

      @throw [ArgumentTypeError] name is not a string
      @throw [ValueError] name is empty
      @throw [ArgumentTypeError] callback not provided or not a function
      @throw [ArgumentTypeError] invalid unsubscribe target

      @overload if1(names..., unsubscribe_target, callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [$timeout|$interval|function] unsubscribe_target attach to
          unsubscriber event
        @param [function] callback function to call on event emission

        @return [boolean]

      @overload if1(names..., callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [function] callback function to call on event emission

        @return [function] unsubscriber
      ###
      if1: (names..., unsubscribe_target, callback) =>
        subscription_decorator.call @, names, unsubscribe_target, callback, ->
          remainder = []
          for name in names
            unless @subscriptions.instantCall name, callback
              remainder.push name

          @subscriptions.push remainder, 1, callback

      ###
      Subscribe for future events AND the last emission if there was one

      @throw [ArgumentTypeError] name is not a string
      @throw [ValueError] name is empty
      @throw [ArgumentTypeError] callback not provided or not a function
      @throw [ArgumentTypeError] invalid unsubscribe target

      @overload if(names..., unsubscribe_target, callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [$timeout|$interval|function] unsubscribe_target attach to
          unsubscriber event
        @param [function] callback function to call on event emission

        @return [boolean]

      @overload if(names..., callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [function] callback function to call on event emission

        @return [function] unsubscriber
      ###
      if: (names..., unsubscribe_target, callback) =>
        subscription_decorator.call @, names, unsubscribe_target, callback, ->
          for name in names
            @subscriptions.instantCall name, callback

          @subscriptions.push names, 0, callback

      ###
      Subscribe for 1 event in the future

      @throw [ArgumentTypeError] name is not a string
      @throw [ValueError] name is empty
      @throw [ArgumentTypeError] callback not provided or not a function
      @throw [ArgumentTypeError] invalid unsubscribe target

      @overload on1(names..., unsubscribe_target, callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [$timeout|$interval|function] unsubscribe_target attach to
          unsubscriber event
        @param [function] callback function to call on event emission

        @return [boolean]

      @overload on1(names..., callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [function] callback function to call on event emission

        @return [function] unsubscriber
      ###
      on1: (names..., unsubscribe_target, callback) =>
        subscription_decorator.call @, names, unsubscribe_target, callback, ->
          @subscriptions.push names, 1, callback

      ###
      Subscribe for events in the future

      @throw [ArgumentTypeError] name is not a string
      @throw [ValueError] name is empty
      @throw [ArgumentTypeError] callback not provided or not a function
      @throw [ArgumentTypeError] invalid unsubscribe target

      @overload on(names..., unsubscribe_target, callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [$timeout|$interval|function] unsubscribe_target attach to
          unsubscriber event
        @param [function] callback function to call on event emission

        @return [boolean]

      @overload on(names..., callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [function] callback function to call on event emission

        @return [function] unsubscriber
      ###
      on: (names..., unsubscribe_target, callback) =>
        subscription_decorator.call @, names, unsubscribe_target, callback, ->
          @subscriptions.push names, 0, callback

      ###
      Get an empty unsubscriber function you can add unsubscribers to

      @example
        unsub = MyEventEmitterObject.unsubscriber()

        unsub.add $interval(timed_fn, 100)

        # similar syntax with EventEmitter object
        unsub.add MyOtherEventEmitterObject.if('roar', lion_coming_fn)

        # this also works for EventEmitter objects
        MyOtherEventEmitterObject.if('meow', unsub, cat_coming_fn)

        # i want these events to stop firing in a minute
        $timeout unsub, 60000

      @example
        # link unsubscription to $scope lifecycle
        unsub = MyEventEmitterObject.unsubscriber $scope

        unsub.add $interval(timed_fn, 100)

        # similar syntax with EventEmitter object
        unsub.add MyOtherEventEmitterObject.if('roar', lion_coming_fn)

        # this also works for EventEmitter objects
        MyOtherEventEmitterObject.if('meow', unsub, cat_coming_fn)


      @param [Object] scope (optional) tie the lifecycle of unsubscriptions to
        controller lifecycle, i.e. will trigger unsubscribscription when
        controller receives the '$destroy' event.

      @return [function] unsubscriber
      ###
      unsubscriber: (scope) ->
        attached  = {}
        increment = 0

        ###
        Calls all added functions and cancels $interval/$timeout promises

        @return [null/bool] null = no added fn, true = all returned truthy
        ###
        fn = ->
          status = null
          for id, node of attached
            if is_function node
              status = false unless node()
            else # if is_function node?.then
              if node.$$intervalId?
                $interval.cancel node
              else # if node.$$timeoutId?
                $timeout.cancel node
          status

        if scope?
          unless $rootScope.isPrototypeOf scope
            argument_type_error {scope, required: '$rootScope descendant'}
          scope.$on '$destroy', fn

        fn[UNSUBSCRIBER] = true

        fn.add = (unsubscriber) ->
          do (increment) ->
            del = ->
              delete attached[increment]

            unknown = ->
              argument_type_error
                unsubscriber: unsubscriber
                argument:     1
                required:     ['function', 'Promise']

            if is_object unsubscriber
              if unsubscriber.$$timeoutId? and unsubscriber.finally?
                unsubscriber.finally del
              else if unsubscriber.$$intervalId? and unsubscriber.finally?
                unsubscriber.finally del
              else
                unknown()
            else unless is_function(unsubscriber) and unsubscriber[UNSUBSCRIBER]
              unknown()

            attached[increment] = unsubscriber

          increment += 1
          true

        fn
]
