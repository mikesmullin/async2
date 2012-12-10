not ((context, definition) ->
  if 'function' is typeof require and
     typeof exports is typeof module
    return module.exports = definition
  return context['async'] = definition
)(this, (->
  # constructor
  a = `function async(beginning_result) {
    if (typeof this.serial === 'undefined') {
      return new a(arguments[0]);
    }
    this.a = [];
    this.beginning_result = beginning_result || {};
    this.beginning_length = 0;
    this.processed = 0;
  };`

  # private instance methods
  a.prototype._apply = (args) ->
    if @a.length
      (if args[0] then @a.splice(0, @a.length).shift() else @a[@a.length-1]).apply (->), args

  a.prototype._next = (parallel) ->
    =>
      @processed++
      return @_apply arguments if arguments[0] # err
      @afterEach_callback.apply @_next(!@afterEach_callback.length), arguments
      if not parallel or @processed is @beginning_length
        while(@_apply(arguments) and parallel)
          ;
      return

  # public instance methods
  a.prototype._push = (args, parallel) ->
    task = args[0]
    '[object Function]' is Object.prototype.toString.call(task) and dont_end = task = [task]
    for key of task
      ((cb, parallel) =>
        @beginning_length++
        @a.push =>
          @a.pop()
          @beforeEach_callback.apply @_next(!@beforeEach_callback.length), arguments
          args = Array.prototype.slice.apply(arguments).slice 1
          cb.apply (next = @_next parallel), args.concat next
          parallel and (1 is @a.length or !!@_apply arguments)
      )(task[key], if parallel is null then not task[key].length else parallel)
    return (if dont_end then @ else @end(if typeof args[1] is 'function' then args[1] else ->))

  a.prototype.serial = a.prototype.series = a.prototype.blocking = a.prototype.waterfall = ->
    @_push arguments, false

  a.prototype.parallel = a.prototype.nonblocking = ->
    @_push arguments, true

  a.prototype.do = a.prototype.then = a.prototype.auto = ->
    @_push arguments, null

  a.prototype.end = a.prototype.finally = a.prototype.ensure = a.prototype.afterAll = a.prototype.after = a.prototype.complete = a.prototype.done = (cb) ->
    @a.push =>
      (!!arguments[0] and
        (@error_callback.apply @_next(!@error_callback.length), arguments)) or
        (@success_callback.apply @_next(!@success_callback.length), arguments)
      cb.apply (->), arguments
    @a.reverse() # 6-10x faster to push/pop than shift
    # initialize callbacks
    (@begin_callback = @begin_callback or (->)) and
      (@beforeAll_callback = @beforeAll_callback or (->)) and
      (@beforeEach_callback = @beforeEach_callback or (->)) and
      (@afterEach_callback = @afterEach_callback or (->)) and
      (@error_callback = @error_callback or (->)) and
      (@success_callback = @success_callback or (->))
    @beforeAll_callback.apply @_next(!@beforeAll_callback.length), arguments
    @_apply [null, @beginning_result]
    return @

  # public instance methods for callback functions
  (_callback = (func) -> (cb) ->
    @[func + '_callback'] = cb
    @) and
    (a.prototype.begin = a.prototype.try = a.prototype.new = _callback 'begin') and
    (a.prototype.beforeAll = a.prototype.before = _callback 'beforeAll') and
    (a.prototype.beforeEach = _callback 'beforeEach') and
    (a.prototype.afterEach = a.prototype.between = a.prototype.inbetween = _callback 'afterEach') and
    (a.prototype.error = a.prototype.catch = a.prototype.rescue = _callback 'error') and
    (a.prototype.success = a.prototype.else = _callback 'success')

  # public static functions
  # automatically instantiate a new async instance
  # and forward arguments to their corresponding public instance method above
  (_static = (func) -> ->
    (b = new a)[func].apply b, arguments) and
    (a.serial = a.series = a.blocking = a.waterfall = _static 'serial') and
    (a.parallel = a.nonblocking = _static 'parallel') and
    (a.do = a.then = a.auto = _static 'do') and
    (a.end = a.finally = a.ensure = a.afterAll = a.after = a.complete = a.done = _static 'end') and
    (a.begin = a.try = a.new = _static 'begin') and
    (a.beforeAll = a.before = _static 'beforeAll') and
    (a.beforeEach = _static 'beforeEach') and
    (a.afterEach = a.between = a.inbetween = _static 'afterEach') and
    (a.error = a.catch = a.rescue = _static 'error') and
    (a.success = a.else = _static 'success')

  # public static-only functions
  a.whilst = (test, iterator, cb) ->
    (test() and
      iterator (err) =>
        return (!!err and
          cb err) or
          @whilst test, iterator, cb
    ) or
      cb()
    return

  a
)())
