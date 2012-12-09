module.exports = class async
  @begin: ->
    new async()

  constructor: ->
    @a = []
    @beginning_length = 0
    @processed = 0

  _call: (result, err) ->
    if err
      a = @a[@a.length-1] # skip to end callback
      @a = []
    else if @a.length
      a = @a[0]
    if typeof a isnt 'undefined'
      a.call (->), result, err

  _pop: (parallel, result, err) ->
    current = @a.shift()
    next = @a[0]
    (result, err) =>
      @processed++
      return @_call result, err if err
      if not parallel or @processed is @beginning_length
        while(@_call(result, err) and parallel)
          ;
      return

  _push: (cb, parallel) ->
    @beginning_length++
    @a.push (result, err) =>
      @inbetween_cb result, err if @inbetween_cb?
      cb.call @_pop(parallel, result, err), result, err
      if parallel and 1 isnt @a.length
        @_call result, err
      parallel # false = blocking, true = non-blocking
    return @

  serial: (cb) ->
    @_push cb, false

  parallel: (cb) ->
    @_push cb, true

  inbetween: (@inbetween_cb) ->
    return @

  rescue: (@rescue_cb) ->
    return @

  success: (@success_cb) ->
    return @

  end: (cb) ->
    @a.push (result, err) =>
      @inbetween_cb result, err if @inbetween_cb?
      if err and @rescue_cb?
        @rescue_cb(err)
      else if @success_cb?
        @success_cb(result)
      cb.call (->), result, err
    @_call undefined, null
    return @
