not ((name, context, definition) ->
  if typeof require is 'function' and
     typeof exports is 'object' and
     typeof module is 'object'
    module.exports = definition
  else
    context[name] = definition
)('async', this, class async
  constructor: (beginning_result) ->
    if typeof @serial is 'undefined'
      return new async arguments[0]
    else
      @a = []
      @beginning_result = if beginning_result? then beginning_result else {}
      @beginning_length = 0
      @processed = 0

  _apply: (args) ->
    if @a.length
      (if args[0] then @a.splice(0, @a.length).shift() else @a[@a.length-1]).apply (->), args

  _next: (parallel) ->
    =>
      @processed++
      return @_apply arguments if arguments[0] # err
      @_callback 'afterEach', arguments
      if not parallel or @processed is @beginning_length
        while(@_apply(arguments) and parallel)
          ;
      return

  _push: (args, parallel) ->
    if Object.prototype.toString.call(args[0]) is '[object Function]'
      args[0] = [args[0]]
      dont_end = true
    for own key of args[0]
      ((cb, parallel) =>
        @beginning_length++
        @a.push =>
          @_callback 'beforeEach', arguments
          args = Array.prototype.slice.apply(arguments).slice 1
          @a.pop()
          next = @_next parallel
          args.push next
          cb.apply next, args
          if parallel and 1 isnt @a.length
            @_apply arguments
          parallel # false = blocking, true = non-blocking
      )(args[0][key], if parallel is null then not args[0][key].length else parallel)
    @end(if typeof args[1] is 'function' then args[1] else ->) unless dont_end?
    return @

  _callback: (name, args) ->
    if typeof @[name += '_callback'] is 'function'
      @[name].apply @_next(!@[name].length), args

  serial: ->
    @_push arguments, false

  parallel: ->
    @_push arguments, true

  then: ->
    @_push arguments, null

  end: (cb) ->
    @a.push =>
      if arguments[0]
        @_callback 'error', arguments
      else
        @_callback 'success', arguments
      cb.apply (->), arguments
    @a.reverse() # 6-10x faster to push/pop than shift
    @_callback 'beforeAll', arguments
    @_apply [null, @beginning_result]
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

  @whilst: (test, iterator, callback) ->
    if test()
      iterator (err) =>
        if err
          callback err
        else
          @whilst test, iterator, callback
    else
      callback()
    return
)
