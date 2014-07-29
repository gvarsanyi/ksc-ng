
app.factory 'ksc.ContractBreakError', ->

  class ContractBreakError extends Error

    constructor: (key, value, contract_desc) ->
      msg 'Value `' + value + '` breaks contract for key `' + key + '`'
      if typeof contract_desc is 'object'
        for k, v of contract_desc
          msg += '\n' + k + ': ' + v
      super msg
