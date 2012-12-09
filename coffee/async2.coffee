module.exports = class async
  @whilst: (test, iterator, callback) ->
    _this = this
    `test() ? iterator(function(err){return err ? callback(err) : _this.whilst(test,iterator,callback)}) : callback()`

  @begin: ->
    new async()

  constructor: (@beginning_result = undefined) ->
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
    @beforeEach_callback result, err if @beforeEach_callback?
    (result, err) =>
      @processed++
      return @_call result, err if err
      @afterEach_callback result, err if @afterEach_callback?
      if not parallel or @processed is @beginning_length
        while(@_call(result, err) and parallel)
          ;
      return

  _push: (cb, parallel) ->
    @beginning_length++
    @a.push (result, err) =>
      cb.call @_pop(parallel, result, err), result, err
      if parallel and 1 isnt @a.length
        @_call result, err
      parallel # false = blocking, true = non-blocking
    return @

  serial: (cb) ->
    # TODO: detect arrays passed instead of functions, add them as if they were chained for backward compatibility with async.js
    # TODO: could even accept end as 2nd argument here
    @_push cb, false

  parallel: (cb) ->
    @_push cb, true

  do: (cb) ->
    @_push cb, !!cb.length

  end: (cb) ->
    @a.push (result, err) =>
      @afterEach_callback result, err if @afterEach_callback?
      if err and @error_callback?
        @error_callback err
      else if @success_callback?
        @success_callback result
      cb.call (->), result, err
    @_call @beginning_result, null
    return @

  for key of _ref = {
    'beforeAll': ['before'],
    'beforeEach': null
    'serial': ['series', 'blocking']
    'parallel': ['nonblocking']
    'afterEach': ['between', 'inbetween']
    'error': ['catch', 'rescue']
    'do': ['then']
    'success': null
    'end': ['finally', 'ensure', 'afterAll', 'after', 'complete', 'done']
  }
    if typeof async.prototype[key] is 'undefined'
      ((key) -> async.prototype[key] = (cb) ->
        @[key + '_callback'] = cb
        return @)(key)
    if _ref[key]?
      for key2 of _ref[key]
        async.prototype[_ref[key][key2]] = async.prototype[key]
