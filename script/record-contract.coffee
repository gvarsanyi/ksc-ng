
app.factory 'ksc.RecordContract', [
  'ksc.Utils',
  (Utils) ->

    has_own   = Utils.hasOwn
    is_object = Utils.isObject


    class RecordContract
      constructor: (contract) ->
        if contract is null or contract instanceof RecordContract
          return contract
        unless is_object contract
          throw new Error 'invalid contract definition'

        # integrity check
        for key, desc of contract
          if key.substr(0, 1) is '_'
            throw new Error 'contract keys must not start with underscore "_"'

          @[key] = desc

          if desc.nullable
            desc.nullable = true
          else
            delete desc.nullable

          if desc.type is 'object' and not is_object desc.contract
            throw new Error 'subcontract specification required for objects'
          if desc.contract
            if has_own(desc, 'type') and desc.type isnt 'object'
              throw new Error 'subcontract must be object type'
            if has_own desc, 'default'
              throw new Error 'subcontracts can not have default values'
            delete desc.type
            desc.contract = new RecordContract desc.contract
          else
            if has_own(desc, 'default') and not has_own(desc, 'type') and
            RecordContract.typeDefaults[typeof desc.default]?
              desc.type = typeof desc.default
            unless RecordContract.typeDefaults[desc.type]?
              throw new Error 'contract keys type unset or invalid (must be ' +
                              'boolean, number, object or string)'

          @_match key, @_default key # checks default value

        Object.freeze @

      _default: (key) ->
        desc = @[key]
        if has_own desc, 'default'
          return desc.default
        if desc.nullable
          return null
        if desc.contract
          value = {}
          for own key of desc.contract
            value[key] = desc.contract._default key
          return value
        RecordContract.typeDefaults[desc.type]

      _match: (key, value) ->
        desc = @[key]
        if desc?
          if (desc.contract and is_object value) or typeof value is desc.type
            return true
          if value is null and desc.nullable
            return true
        throw new Error 'Value breaks contract for ' + key + ' = ' + value


      @finalizeRecord: (record) ->
        if record._options.contract and Object.isExtensible record
          Object.preventExtensions record

      @typeDefaults:
        boolean: false
        number:  0
        string:  ''
]
