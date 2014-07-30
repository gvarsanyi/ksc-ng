
app.factory 'ksc.RecordContract', [
  'ksc.errors', 'ksc.utils',
  (errors, utils) ->

    has_own   = utils.hasOwn
    is_object = utils.isObject


    class RecordContract
      constructor: (contract) ->
        if contract is null or contract instanceof RecordContract
          return contract
        unless is_object contract
          throw new errors.Type {contract, acceptable: 'object'}

        # integrity check
        for key, desc of contract
          if key.substr(0, 1) is '_'
            throw new errors.Key {key, description: 'can not start with "_"'}

          @[key] = desc

          if desc.nullable
            desc.nullable = true
          else
            delete desc.nullable

          if desc.type is 'object' and not is_object desc.contract
            throw new errors.Type contract:    desc.contract
                                  acceptable:  'object'
                                  description: 'object type requires contract'
          if desc.contract
            if has_own(desc, 'type') and desc.type isnt 'object'
              throw new errors.Type contract:   desc.contract
                                    acceptable: 'object'
            if has_own desc, 'default'
              throw new errors.Value default:     desc.default
                                     contract:    desc.contract
                                     description: 'subcontract can not have ' +
                                                  'default value'
            delete desc.type
            desc.contract = new RecordContract desc.contract
          else
            if has_own(desc, 'default') and not has_own(desc, 'type') and
            RecordContract.typeDefaults[typeof desc.default]?
              desc.type = typeof desc.default
            unless RecordContract.typeDefaults[desc.type]?
              throw new errors.Type type:       desc.type
                                    acceptable: ['boolean', 'number', 'object',
                                                 'string']

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
        throw new errors.ContractBreak {key, value, contract: desc}


      @finalizeRecord: (record) ->
        if record._options.contract and Object.isExtensible record
          Object.preventExtensions record

      @typeDefaults:
        boolean: false
        number:  0
        string:  ''
]
