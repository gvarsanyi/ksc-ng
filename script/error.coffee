
ksc.service 'ksc.error', ->

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
      # NOTE: un-remark the following line if you want even caught errors to be
      #       displayed on console.error output:
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
        error.ArgumentType {param, argument: 1, required: 'string'}
  ###
  class ArgumentTypeError extends CustomError

  ###
  Error in attempt to change contracted data set
  @example
      unless rules.match key, value
        error.ContractBreak {key, value, contract: rules[key]}
  ###
  class ContractBreakError extends CustomError

  ###
  HTTP request/response error
  @example
      promise.catch (response) ->
        error.Http response
  ###
  class HttpError extends CustomError

  ###
  Key related errors (like syntax requirement fails etc)
  @example
      if key.substr(0, 1) is '_'
        error.Key {key, description: 'keys can not start with "_"'}
  ###
  class KeyError extends CustomError

  ###
  Required argument is missing
  @example
      unless param?
        error.MissingArgument {name: 'param', argument: 1}
  ###
  class MissingArgumentError extends CustomError

  ###
  Perimission related errors
  @example
      if key.substr(0, 1) is '_'
        error.Perimission {key, description: 'property is off-limit'}
  ###
  class PermissionError extends CustomError

  ###
  Type mismatch
  @example
      if typeof param is 'function'
        error.Type {param, description: 'must not be function'}
  ###
  class TypeError extends CustomError

  ###
  Value does not meet requirements
  @example
      unless param and typeof param is 'string'
        error.Value {param, description: 'must be non-empty string'}
  ###
  class ValueError extends CustomError


  ###
  Common named error types

  All-static class: error type classes are attached to ErrorTypes class instance

  This is going to be accessible via the ksc.error service:
  @example
        # use MissingArgumentError class
        throw new error.type.MissingArgument {name: 'result', argument: 1}

        # shorthand for auto-throw:
        error.MissingArgument {name: 'result', argument: 1}
  ###
  class ErrorTypes
    @ArgumentType: ArgumentTypeError
    @ContractBreak: ContractBreakError
    @Http: HttpError
    @Key: KeyError
    @MissingArgument: MissingArgumentError
    @Permission: PermissionError
    @Type: TypeError
    @Value: ValueError


  error =
    type: ErrorTypes

  # set ::name properties for the listed error type classes
  for name, class_ref of ErrorTypes
    class_ref::name = name + 'Error'
    do (class_ref) ->
      error[name] = (description) ->
        throw new class_ref description

  # return the interface class instance
  error
