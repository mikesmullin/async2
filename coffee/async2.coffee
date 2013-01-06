not ((context, definition) ->
  if 'function' is typeof require and
     typeof exports is typeof module
    return module.exports = definition
  return context['async'] = definition
)(this, (->
  # constructor
  # the if statement is for jQuery-like instantiation
  A = `function async(beginning_result) {
    if (typeof this.serial === 'undefined') {
      var a = new A(), k;
      for (k in arguments[0]) {
        a[k](arguments[0][k]);
      }
      return a;
    }
    this.a = [];
    this.beginning_result = beginning_result
    this.beginning_length = 0;
    this.processed = 0;
    this.q = {};
    this.processing = false;
  };`

  # private instance methods
  A::_apply = (args) ->
    if @a.length
      (if args[0] then @a.splice(0, @a.length).shift() else @a[@a.length-1]).apply {}, args

  A::_next = (parallel) ->
    =>
      @processed++
      return @_apply arguments if arguments[0] # err
      @afterEach_callback.apply @_next(!@afterEach_callback.length), arguments
      if not parallel or @processed is @beginning_length
        while(@_apply(arguments) and parallel)
          ;
      return

  A::_push = (args, parallel) ->
    task = args[0]
    '[object Function]' is Object::toString.call(task) and dont_end = task = [task]
    for key of task
      ((cb, parallel) =>
        @beginning_length++
        @a.push =>
          @a.pop()
          @beforeEach_callback.apply @_next(!@beforeEach_callback.length), arguments
          args = Array::slice.apply(arguments).slice 1
          cb.apply (next = @_next parallel), args.concat next
          parallel and (1 is @a.length or !!@_apply arguments)
      )(task[key], if parallel is null then not task[key].length else parallel)
    return (if dont_end then @ else @end(if typeof args[1] is 'function' then args[1] else ->))

  # public instance methods
  A::end = A::finally = A::ensure = A::afterAll = A::after = A::complete = A::done = A::go = (cb) ->
    return if @processing # must not already be going
    @processing = true
    @a.push =>
      if arguments[0]
        @error_callback.apply @_next(!@error_callback.length), arguments
      else
        @success_callback.apply @_next(!@success_callback.length), arguments
      @processing = false
      cb.apply null, arguments if typeof cb is 'function'
    @a.reverse() # 6-10x faster to push/pop than shift
    # initialize callbacks
    (@begin_callback = @begin_callback or ->) and
      (@beforeAll_callback = @beforeAll_callback or ->) and
      (@beforeEach_callback = @beforeEach_callback or ->) and
      (@afterEach_callback = @afterEach_callback or ->) and
      (@error_callback = @error_callback or ->) and
      (@success_callback = @success_callback or ->)
    @beforeAll_callback.apply @_next(!@beforeAll_callback.length), arguments
    @_apply if (typeof @beginning_result)[0] is 'u' then [ null ] else [ null, @beginning_result ]
    return @

  A::serial = A::series = A::blocking = A::waterfall = ->
    @_push arguments, false

  A::parallel = A::nonblocking = ->
    @_push arguments, true

  A::do = A::then = A::try = A::begin = A::start = A::auto = ->
    @_push arguments, null

  A::new = A::flow = A::with = (b) ->
    @beginning_result = b
    @

  A::nextTickGroup = A::push = (g, f) ->
    @q[g] = @q[g] or new A
    @q[g].serial(f).go()
    @

  # public instance methods for callback functions
  (_callback = (func) -> (cb) ->
    @[func + '_callback'] = cb
    @) and
    (A::beforeAll = A::before = _callback 'beforeAll') and
    (A::beforeEach = _callback 'beforeEach') and
    (A::afterEach = A::between = A::inbetween = _callback 'afterEach') and
    (A::error = A::catch = A::rescue = _callback 'error') and
    (A::success = A::else = _callback 'success')

  # public static functions
  # automatically instantiate a new async instance
  # and forward arguments to their corresponding public instance method above
  (_static = (func) -> ->
    (b = new A)[func].apply b, arguments) and
    (A.serial = A.series = A.blocking = A.waterfall = _static 'serial') and
    (A.parallel = A.nonblocking = _static 'parallel') and
    (A.do = A.then = A.try = A.begin = A.start = A.auto = _static 'do') and
    (A.end = A.finally = A.ensure = A.afterAll = A.after = A.complete = A.done = A.go = _static 'end') and
    (A.new = A.flow = A.with = _static 'new') and
    (A.beforeAll = A.before = _static 'beforeAll') and
    (A.beforeEach = _static 'beforeEach') and
    (A.afterEach = A.between = A.inbetween = _static 'afterEach') and
    (A.error = A.catch = A.rescue = _static 'error') and
    (A.success = A.else = _static 'success') and
    (A.nextTickGroup = A.push = _static 'push')

  # public static-only functions
  A.whilst = (test, iterator, cb) ->
    (test() and
      iterator (err) =>
        return (!!err and
          cb err) or
          @whilst test, iterator, cb
    ) or
      cb()
    return

  A.delay = (ms, f) ->
    setTimeout f, ms

  A
)())
