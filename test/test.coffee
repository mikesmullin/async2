async = require '../coffee/async2'
assert = require('chai').assert

describe 'async2', ->
  start = undefined
  beforeEach ->
    start = new Date

  it 'auto-instantiates a new async', ->
    a = async
      .serial(-> 'hello')
    assert.notEqual async, a

  it 'allows chainable manual instantiation', ->
    a = async.new() # alternative to (new async).
    assert.notEqual async, a

  it 'allows explicit blocking with serial()', (done) ->
    async
      .serial(-> delay 100, @ )
      .serial(-> delay 50, @ )
      .end ->
        assert.closeTo 100+50, since(start), 25
        done()

  it 'allows explicit non-blocking with parallel()', (done) ->
    async
      .parallel(-> delay 100, @ )
      .parallel(-> delay 50, @ )
      .end ->
        assert.closeTo Math.max(100,50), since(start), 25
        done()

  it 'allows auto-blocking with then() based on function argument length', (done) ->
    async
      .then((result) -> delay 200, @ ) # serial
      .then(-> delay 100, @ ) # parallel
      .then(-> delay 50, @ ) # parallel
      .end ->
        assert.closeTo 200+Math.max(100,50), since(start), 25
        done()

  it 'can accomplish async.js::auto() with chain ordering', (done) ->
    # see also: https://github.com/caolan/async#auto
    async.auto
      get_data: -> # no args; parallel
        # async code to get some data
        delay 10, @
      make_folder: (result) -> # args; serial
        # async code to create a directory to store a file in
        # this is run at the same time as getting the data
        delay 50, @
      write_file: (result) -> # args; serial
        # once there is some data and the directory exists
        # write the data to a file in the directory
        delay 100, @
      email_link: (result) -> # args; serial
        # once the file is written let's email a link to it...
        # results.write_file contains the filename returned by write_file
        delay 250, @
      end: -> # couple different ways this last part could have been done
        assert.closeTo Math.max(10,50)+100+250, since(start), 25
        done()

  it 'can accomplish async.js::waterfall() with serial()', (done) ->
    # see also: https://github.com/caolan/async#waterfall
    async
      .serial(-> @ null, 'async.js is silly. pass it on.' )
      .serial((result) -> @ null, result + ' hehe.')
      .serial((result) -> @ null, result + ' ok maybe its not too silly.' )
      .end (err, result) ->
        assert.equal result, 'async.js is silly. pass it on. hehe. ok maybe its not too silly.'
        done()

  it 'accepts enumerable objects as task input, executing immediately', (done) ->
    # legacy async.js backward compatibility
    async.series [
     -> delay 100, @
     -> delay 50, @
    ], ->
      assert.closeTo 100+50, since(start), 25
      done()

  it 'follows node (results..., cb) and (err, results..., cb) conventions', (done) ->
    fs =
      readFile: (path, done) ->
        delay 20, -> done null, "tons o' data from #{path}."
    tweet = fbook = gplus = (data, done) -> done null, data
    results = {}
    async('pretend/path/to/file')
      .serial(fs.readFile)
      .parallel [ tweet, fbook, gplus ],
        (err, data) ->
          assert.equal "tons o' data from pretend/path/to/file.", data
          done()

  it 'can process callbacks before, beforeEach, afterEach', (done) ->
    results = []
    check = (what, done) ->
      setTimeout (->
        results.push what
        done null, what
      ), 50
    async
      .before((result) -> 'awake' )
      .beforeEach((result) -> 'ready to switch focus' )
      .do((result) -> check 'mobile', @ )
      .then(-> check 'email', @ )
      .then(-> check 'Fbook', @ )
      .then(-> check 'GPlus', @ )
      .afterEach((result) -> 'cleaned up after task' )
      .end (err) ->
        assert.equal 'mobile email Fbook GPlus', results.join ' '
        assert.closeTo 50+Math.max(50,50,50), since(start), 25
        done()

  it 'can do whilst()', (done) ->
    a = 0
    out = []
    async.whilst (-> a < 5 ),
      ((done) -> delay 50, -> out.push a++; done() ), ->
        assert.equal '0 1 2 3 4', out.join ' '
        assert.closeTo 5*50, since(start), 25
        done()

  it 'takes callback as the only argument in the first serial', (done) ->
    async.flow()
      .serial((next) ->
        assert.typeOf next, 'function'
        done()
      )
      .finally()

  it 'takes callback as the last argument of a variable length of arguments based upon the previous serial of a subsequent serial'
  it 'takes err, result as only arguments to finally in a series'
  # it 'can do nextTick(f)' # why? node does it fine
  it 'can do immediate serial execution push(f)'
  it 'can do grouped immediate serial execution push("name", f)'



  # TODO: uncomment this; it should work
  #### an overcomplicated display of flexibility
  #```coffeescript
  #a = async.new()
  #for i in [1..10]
  #  ((i) -> a[(f = if i%3 then 'parallel' else 'serial')] (result, err) ->
  #    done = @; setTimeout (-> console.log "#{f} #{i}"; done()), 1000)(i)
  #a.end (result, err) ->
  #  console.log 'try this in async.js!'
  #```

  #### a few familiar examples
  #```coffeescript
  ## similar to jQuery.ajax()
  #async
  #  .beforeAll(-> loading.show() )
  #  # TODO: going to have to flip my callback order to (err, data)
  #  # if i want to be compatible with node.js core here
  #  .serial((done) -> fs.readFile done)
  #  .parallel((data) -> tweet data, @ )
  #  .parallel((data) -> fbook data, @ )
  #  .parallel((data) -> gplus data, @ )
  #  .error((err) -> alert err )
  #  .success((data) -> console.log data )
  #  .complete(-> loading.hide() )

  ## similar to javascript try/catch/finally exception handling
  ## also works with begin/rescue/else/ensure
  #async.try()
  #  .series((done) -> salmon done)
  #  .series((done) -> catfish done)
  #  .catch((e) -> console.log "something fishy: #{err}")
  #  .finally ->
  #    console.log 'ready to eat!'
  #```

  #### everything but the kitchen sink example
  #```coffeescript
  #b = undefined # global scope
  #a = async
  #  a.series((result, err) ->
  #    setTimeout (=>
  #      doSomething()
  #      @ result, err # `this` object is the done() function
  #    ), 1000)
  #  .parallel(-> "chaining with (result, err) is normal but sometimes you don't care." )
  #  .parallel((result, err) -> sometimesYourDelegatesImplementForYou @, result, err )
  #  .series(-> sometimesDelegatesOnlyReturnAResult @ )
  #  .series((result) -> result['unique'] = "end could receive results merged inside the chain"; @ result )
  #  .parallel(-> "parallel calling the done() callback is still required. sry"; @() )
  #  .parallel(-> b = "you could also pass results via the global scope"; @() )
  #  .inbetween((result, err) -> console.log "processing... #{a.processed} of #{a.beginning_length} or #{a.processed / a.beginning_length * 100}% complete")
  #  .rescue((err) -> console.log "An error occurred: #{err}")
  #  .success((result) -> console.log "The results are in: #{result}")
  #  .end (result, err) ->
  #    console.log "The wait is over.")
  #```

  #it 'can do everything', (done) ->
  #  console.log 'starting serial/parallel example... should be a A b c d e f D F g h G success end'
  #  a = async.begin()
  #  a.serial((result, err) -> Debugger.log ['0 a', @, result, err]; delay 1000, => Debugger.log ['0 A', @, result, err]; @ 1, err)
  #    .serial((result, err) -> Debugger.log ['1 b', @, result, err]; @ 2, err)
  #    .parallel((result, err) -> Debugger.log ['2 c', @, result, err]; @ 3, err)
  #    .parallel((result, err) -> Debugger.log ['3 d', @, result, err]; delay 1000, => Debugger.log ['3 D', @, result, err]; @ 4, err)
  #    .serial((result, err) -> Debugger.log ['4 e', @, result, err]; @ 5, err)
  #    .serial((result, err) -> Debugger.log ['5 f', @, result, err]; delay 1000, => Debugger.log ['5 F', @, result, err]; @ 6, err)
  #    .parallel((result, err) -> Debugger.log ['6 g', @, result, err]; delay 1000, => Debugger.log ['6 G', @, result, err]; @ 7, err)
  #    .parallel((result, err) -> Debugger.log ['7 h', @, result, err]; @ 8, err)
  #    .inbetween((result, err) -> Debugger.log ["processing... #{a.processed} of #{a.beginning_length} or #{a.processed / a.beginning_length * 100}% complete", result, err])
  #    .rescue((err) -> Debugger.log ['rescue', err])
  #    .success((result) -> Debugger.log ['success', result])
  #    .end (result, err) ->
  #      Debugger.log ['8 end', @, result, err]
  #      done()
