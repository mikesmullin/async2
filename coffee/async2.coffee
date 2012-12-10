not ((name, context, definition) ->
  if typeof require is 'function' and
     typeof exports is 'object' and
     typeof module is 'object'
    module.exports = definition
  else
    context[name] = definition
)('async', this, class async
  @whilst: (test, iterator, callback) ->
    _this = this
    `test() ? iterator(function(err){return err ? callback(err) : _this.whilst(test,iterator,callback)}) : callback()`

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

  _push: (args, parallel) ->
    if Object.prototype.toString.call(args[0]) is '[object Function]'
      args[0] = [args[0]]
      dont_end = true
    for own key of args[0]
      ((cb, parallel) =>
        @beginning_length++
        @a.push (result, err) =>
          cb.call @_pop(parallel, result, err), result, err
          if parallel and 1 isnt @a.length
            @_call result, err
          parallel # false = blocking, true = non-blocking
      )(args[0][key], if parallel is null then not args[0][key].length else parallel)
    @end(if typeof args[1] is 'function' then args[1] else ->) unless dont_end?
    return @

  serial: ->
    # TODO: detect arrays passed instead of functions, add them as if they were chained for backward compatibility with async.js
    # TODO: could even accept end as 2nd argument here
    @_push arguments, false

  parallel: ->
    @_push arguments, true

  then: ->
    @_push arguments, null

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
    'begin': ['new', 'try'],
    'beforeAll': ['before'],
    'beforeEach': null
    'serial': ['series', 'blocking', 'waterfall']
    'parallel': ['nonblocking']
    'then': ['do', 'auto']
    'afterEach': ['between', 'inbetween']
    'error': ['catch', 'rescue']
    'success': ['else']
    'end': ['finally', 'ensure', 'afterAll', 'after', 'complete', 'done']
  }
    ((key) ->
      if typeof async.prototype[key] is 'undefined' # optional callbacks
        async.prototype[key] = (cb) ->
          @[key + '_callback'] = cb
          return @
      async[key] = -> # static method placeholders
        # instantiate new async object and
        # forward arguments to instance method
        # by the same name
        (a = new async)[key].apply a, arguments
    )(key)
    if _ref[key]? # method aliases
      for key2 of _ref[key]
        async.prototype[_ref[key][key2]] = async.prototype[key]
        async[_ref[key][key2]] = async[key]
)
