
app.factory 'ksc.RecordContract', [
  'ksc.errors', 'ksc.utils',
  (errors, utils) ->

    has_own   = utils.hasOwn
    is_object = utils.isObject


    ###
    Contract, integrity checkers and matchers for {Record} and descendants

    Restricts record properties to the ones specified in the contract.

    Requires data types to match

    Allows specifing defaults and if the values are nullable

    Does not ever allow undefined values on contract nor it will allow nulls on
    non-nullable properties.

    Sets default values to properties not specified in construction or data
    replacement time (see: {Record#_replace} and {EditableRecord#_replace})

    @example
      record = new Record {c: false},
        contract:
          a: {type: 'number'}
          b: {type: 'string', nullable: true}
          c: {type: 'boolean', default: true}
      console.log record # {a: 0, b: null, c: false}

    @author Greg Varsanyi
    ###
    class RecordContract

      ###
      Construct RecordContract instance off of provided description (or return
      the existing RecordContract instance if that was passed)

      Checks integrity of escription

      @throw [KeyError] keys can not start with underscore
      @throw [TypeError] type is not supported or mismatches with default value
      @throw [ValueError] subcontracts can not have default values

      @param [object] contract description object
      ###
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
            throw new errors.Type
              contract:    desc.contract
              acceptable:  'object'
              description: 'object type requires contract'

          if desc.contract
            if has_own(desc, 'type') and desc.type isnt 'object'
              throw new errors.Type
                contract:   desc.contract
                acceptable: 'object'

            if has_own desc, 'default'
              throw new errors.Value
                default:     desc.default
                contract:    desc.contract
                description: 'subcontract can not have default value'

            delete desc.type
            desc.contract = new RecordContract desc.contract
          else
            if has_own(desc, 'default') and not has_own(desc, 'type') and
            RecordContract.typeDefaults[typeof desc.default]?
              desc.type = typeof desc.default
            unless RecordContract.typeDefaults[desc.type]?
              throw new errors.Type
                type:       desc.type
                acceptable: ['boolean', 'number', 'object', 'string']

          @_match key, @_default key # checks default value

        Object.freeze @

      ###
      Get default value for property from contract definition or from type
      defaults (see: {RecordContract#typeDefaults})

      @param [string] key name of property

      @throw [KeyError] key not found on contract

      @return [any type] default value for property
      ###
      _default: (key) ->
        desc = @[key]

        unless desc
          throw new errors.Key {key, description: 'Key not found on contract'}

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

      ###
      Check if value matches contract requirements (value type, nullable)

      NOTE: It throws an error on mismatch, i.e. it returns true OR throws an
      error.

      @param [string] key name of property
      @param [any type] value value to match against contract requirements

      @throw [ContractBreakError] key not found or value contract mismatch

      @return [boolean] true on success
      ###
      _match: (key, value) ->
        desc = @[key]

        if desc?
          if (desc.contract and is_object value) or typeof value is desc.type
            return true
          if value is null and desc.nullable
            return true
        throw new errors.ContractBreak {key, value, contract: desc}


      ###
      Helper method used by {Record} (and classes that extend it) that prevents
      further properties from being added to the record (i.e. having a contract
      comes with the requirement of finalizing the Record instance once all
      properties and methods are added)

      @param [Record] record object to finalize

      @return [undefined]
      ###
      @finalizeRecord: (record) ->
        if record._options.contract and Object.isExtensible record
          Object.preventExtensions record
        return

      # @property [object] supported primitive types and their default values
      @typeDefaults:
        boolean: false
        number:  0
        string:  ''
]
