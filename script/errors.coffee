
app.factory 'ksc.Errors', ->

  info_to_string = (options) ->
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
    msg


  class ArgumentTypeError extends Error
    name: 'ArgumentTypeError'
    constructor: (options) ->
      @message = info_to_string options

  class ContractBreakError extends Error
    name: 'ContractBreakError'
    constructor: (options) ->
      @message = info_to_string options

  class HttpError extends Error
    name: 'HttpError'
    constructor: (options) ->
      @message = info_to_string options

  class KeyError extends Error
    name: 'KeyError'
    constructor: (options) ->
      @message = info_to_string options

  class MissingArgumentError extends Error
    name: 'MissingArgumentError'
    constructor: (options) ->
      @message = info_to_string options

  class TypeError extends Error
    name: 'TypeError'
    constructor: (options) ->
      @message = info_to_string options

  class ValueError extends Error
    name: 'ValueError'
    constructor: (options) ->
      @message = info_to_string options


  class Errors
    @ArgumentType:    ArgumentTypeError
    @ContractBreak:   ContractBreakError
    @Http:            HttpError
    @Key:             KeyError
    @MissingArgument: MissingArgumentError
    @Type:            TypeError
    @Value:           ValueError
