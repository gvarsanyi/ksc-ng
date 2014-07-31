
app.service 'ksc.errors', ->

  ###
  Custom error archetype class
  ###
  class CustomError extends Error

    ###
    Takes over constructor so that messages can be formulated off of an option
    hashmap or plain string (or no argument)

    @param [object] options
    ###
    constructor: (options) ->
      # NOTE: un-remark the following line if you want even caught errors thrown
      #       here to be displayed on console.error:
      # console.error msg, options

      msg = ''
      if options and typeof options is 'object'
        for key, value of options
          try
            value = JSON.stringify value, null, 2
          catch
            value = String value
          msg += '\n  ' + key + ': ' + value
      else if options?
        msg += String options

      @message = msg


  ###
  Error for argument type mismatch
  @example
      unless typeof param is 'string'
        throw new errors.ArgumentType {param, argument: 1, acceptable: 'string'}
  ###
  class ArgumentTypeError extends CustomError

  ###
  Error in attempt to change contracted data set
  @example
      unless rules.match key, value
        throw new errors.ContractBreak {key, value, contract: rules[key]}
  ###
  class ContractBreakError extends CustomError

  ###
  HTTP request/response error
  @example
      promise.catch (response) ->
        throw new errors.Http response
  ###
  class HttpError extends CustomError

  ###
  Key related errors (like syntax requirement fails etc)
  @example
      if key.substr(0, 1) is '_'
        throw new errors.Key {key, description: 'keys can not start with "_"'}
  ###
  class KeyError extends CustomError

  ###
  Required argument is missing
  @example
      unless param?
        throw new errors.MissingArgument {name: 'param', argument: 1}
  ###
  class MissingArgumentError extends CustomError

  ###
  Perimission related errors
  @example
      if key.substr(0, 1) is '_'
        throw new errors.Perimission {key, description: 'property is off-limit'}
  ###
  class PermissionError extends CustomError

  ###
  Type mismatch
  @example
      if typeof param is 'function'
        throw new errors.Type {param, notAcceptable: 'function'}
  ###
  class TypeError extends CustomError

  ###
  Value does not meet requirements
  @example
      unless param and typeof param is 'string'
        throw new errors.Value {param, description: 'must be non-empty string'}
  ###
  class ValueError extends CustomError


  ###
  Container of error types
  Errors are stored by their class names minus 'Error'
  ###
  errors =
    ArgumentType:    ArgumentTypeError
    ContractBreak:   ContractBreakError
    Http:            HttpError
    Key:             KeyError
    MissingArgument: MissingArgumentError
    Permission:      PermissionError
    Type:            TypeError
    Value:           ValueError

  # set ::name properties for the listed error classes
  for name, ref of errors
    ref::name = name + 'Error'

  # return the interface class instance
  errors
