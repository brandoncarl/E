
# ### Introduction
# The E module provides a a foundation for custom errors. In particular,
# it enhances the error object in 3 ways:
# 1. It provides an additional error code
# 2. It allows custom errors to be abstracted and named.
# 3. It formats those errors in a manner amenable to output.
#
# This module consists of two primary parts: the global E module and the AbstractError class.
#


# #### Dependencies
util   = require 'util'



# ### Error module

module.exports = E = {}

# #### Global transports
E.transports = E.transports or []

# #### function registerError
# Allows new errors to be added. Spaces are removed in description to create
# error type. Options include ability to prevent logging (using silent).
E.registerError = (type, options, description) ->

  # Set defaults
  options ?= { silent : false, ignore : [] }

  if /\s/.test type
    if "undefined" == typeof description then description = type
    type = type.replace /\s/g, ''

  if "undefined" != typeof E[type] then return new Error "#{type} already exists."

  # Helper function to assist with constructor splats
  __extend = (arr) ->
    for i in [1...arr.length]
      if "object" != typeof arr[i] then continue
      for key, val of arr[i]
        arr[0][key] = val
    return arr[0]

  # Constructor
  E[type] = (errOrMessage, data...) ->

    data = if data.length then __extend(data) else {}

    # If another type of custom error is already being passed in, do not override it
    if errOrMessage instanceof Error
      if errOrMessage.isCustom then return errOrMessage

    # Otherwise create error of custom type
    E[type].super_.call @, errOrMessage, @constructor

    # Report error to loggers
    data.fxn ?= "<anonymous>"
    if @log then E.report @, data, @ignore

    return @

  util.inherits E[type], E.AbstractError

  # Type variable stored in name to retain consistency with Error object
  # Note that name/desc is used to maintain compatibility with existing error object.
  E[type].prototype.name   = type
  E[type].prototype.desc   = description
  E[type].prototype.log    = not options.silent
  E[type].prototype.ignore = options.ignore


# #### function is
# Allows "is" to be called against normal errors.
E.is = (err, type) ->
  return !!((err instanceof Error) and err.is and err.is(type))


# #### function report
# Reports errors to all attached transports. The ignore parameter is an array of
# transports to name by array.
E.report = (err, data, ignore = []) ->
  for own name, transport of E.transports
    transport.log(err, data) unless ignore.indexOf(name) > -1


# #### function addTransport
# Adds a transport to the global object.
E.addTransport = (transport) ->

  if not transport.name then return new Error "Transport must have a name"
  E.transports[transport.name] = transport


# #### function removeTransport
# Removes a transport if exists.
E.removeTransport = (transport) ->

  if not transport.name then return new Error "Transport must have a name"
  delete E.transports[transport.name]




# ### Abstract Error class

# #### function AbstractError
# Provides template for all other errors
E.AbstractError = AbstractError = (errOrMessage, con) ->

  if "undefined" == typeof errOrMessage or null == errOrMessage then errOrMessage = ""

  # If errOrMessage.message is not undefined, argument must be an error
  if "undefined" != typeof errOrMessage.message
    errOrMessage = errOrMessage.message.replace /^Error: /, ""

  Error.captureStackTrace @, con or @
  @message = errOrMessage or "Error"

  if not @isCustom then @isCustom = true

# Ensure AbstractError has necessary inheritance
util.inherits AbstractError, Error


# type and [desc]ription are our custom properties to track these errors
AbstractError.prototype.type = "AbstractError"
AbstractError.prototype.desc = "Abstract Error"


# Ensure that Abstract Error forms string correctly
AbstractError.prototype.inspect = AbstractError.prototype.toString = ->
  conjunction = if @code then ' ' + @code else ''
  return "[" + @desc + conjunction + ": " + @message + "]"


AbstractError.prototype.is = (otherType) ->

  # Handle generic error objects
  if 'Error' == otherType or "undefined" != typeof otherType.captureStackTrace
    return true

  # Handle strings
  if 'string' == typeof otherType
    otherType = E[otherType.trim()]
    if not otherType then return false

  return @ instanceof otherType



