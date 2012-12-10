# Async2.js

Better asynchronous javascript flow control in [157 lines](async2/blob/master/js/async2.js).

Actually its probably half that if backward-compatibility were separated to `async-legacy.js`.

Inspired by [async](https://github.com/caolan/async),
[mini-async](https://github.com/mikesmullin/mini-async),
[Mocha](https://github.com/visionmedia/mocha),
[Chai](https://github.com/chaijs/chai),
[Should.js](https://github.com/visionmedia/should.js/), and
[IcedCoffeeScript](http://maxtaco.github.com/coffee-script/)/[TameJs](http://tamejs.org/)
libraries.

### Flow Control

* [begin / try / new](#begin) : chainable instantiation; not required but sometimes useful
* [beforeAll / before](#beforeEach) : non-blocking function called once before first task
* [beforeEach](#beforeEach) : non-blocking function called once before each task
* [serial / series / blocking / waterfall](#serial) : blocking function called in order; results optionally waterfalled.
* [parallel / nonblocking](#parallel) : non-blocking function called in order
* [do / then / auto](#serial) : optionally blocking function called in order; determined by length of arguments callback expects
* [afterEach / between / inbetween](#afterEach) : non-blocking function called once after each task
* [error / catch / rescue](#rescue) : blocking function called when error occurs
* [success / else](#success) : non-blocking function called after all tasks have completed, but only if no errors occur
* [end / finally / ensure / afterAll / after / complete / done](#end) : blocking function called after all tasks have completed
* [whilst](#whilst) : provide test, iterator, and callback functions. will iterate until test passes, then execute callback

## Quick Examples

### First, reflect upon our haiku mantra:

> "thoughtful single-chain

> order of operations

> escape callback hell!"

### a simply beautiful example
<a name="begin" />
```coffeescript
results = [],
check = (what, done) ->
  console.log "checking #{what}..."
  setTimeout (->
    console.log "done with #{what}"
    results.push what
    done what
  ), 1000)

async
  .before((done) -> check 'awake', done )
  .beforeEach((done) -> check 'ready to switch focus', done )
  .do((done) -> check 'mobile', done )
  .then(-> check 'email', @ )
  .then(-> check 'Fbook', @ )
  .then(-> check 'GPlus', @ )
  .afterEach(-> check 'cleaned up after task' )
  .end ->
    console.log "finished #{results.join(', ')}. ready to work!"
    done()
```

### an overcomplicated display of flexibility
```coffeescript
a = async.new()
for i in [1..10]
  ((i) -> a[(f = if i%3 then 'parallel' else 'serial')] (result, err) ->
    done = @; setTimeout (-> console.log "#{f} #{i}"; done()), 1000)(i)
a.end (result, err) ->
  console.log 'try this in async.js!'
```

### a few familiar examples
```coffeescript
# similar to jQuery.ajax()
async
  .beforeAll(-> loading.show() )
  # TODO: going to have to flip my callback order to (err, data)
  # if i want to be compatible with node.js core here
  .serial((done) -> fs.readFile done)
  .parallel((data) -> tweet data, @ )
  .parallel((data) -> fbook data, @ )
  .parallel((data) -> gplus data, @ )
  .error((err) -> alert err )
  .success((data) -> console.log data )
  .complete(-> loading.hide() )

# similar to javascript try/catch/finally exception handling
# also works with begin/rescue/else/ensure
async.try()
  .series((done) -> salmon done)
  .series((done) -> catfish done)
  .catch((e) -> console.log "something fishy: #{err}")
  .finally ->
    console.log 'ready to eat!'

(next) # serial
(next, err) #
(err, result) #
(result, err) #
(err)
(result)
(next, err, result)

```

### everything but the kitchen sink example
```coffeescript
b = undefined # global scope
a = async
  a.series((result, err) ->
    setTimeout (=>
      doSomething()
      @ result, err # `this` object is the done() function
    ), 1000)
  .parallel(-> "chaining with (result, err) is normal but sometimes you don't care." )
  .parallel((result, err) -> sometimesYourDelegatesImplementForYou @, result, err )
  .series(-> sometimesDelegatesOnlyReturnAResult @ )
  .series((result) -> result['unique'] = "end could receive results merged inside the chain"; @ result )
  .parallel(-> "unless chaining results, executing parallel callbacks is only required if errors occur." )
  .parallel(-> b = "you could also pass results via the global scope" )
  .inbetween((result, err) -> console.log "processing... #{a.processed} of #{a.beginning_length} or #{a.processed / a.beginning_length * 100}% complete")
  .rescue((err) -> console.log "An error occurred: #{err}")
  .success((result) -> console.log "The results are in: #{result}")
  .end (result, err) ->
    console.log "The wait is over.")
```

### legacy backward-compatibility
```coffeescript
async.parallel [
  -> blah
  -> blah
], ->
  # done
```

For the latest examples, review [./test/test.coffee](async2/blob/master/test/test.coffee)

TODO
----

* potential node.js madness: each series becomes its own cpu thread, each parallel becomes its own gpu thread.

> "GPUs have evolved to the point where many real-world applications are easily implemented on them and run significantly faster than on multi-core systems. Future computing architectures will be hybrid systems with parallel-core GPUs working in tandem with multi-core CPUs.'
-- [Professor Jack Dongarra](http://www.nvidia.com/object/what-is-gpu-computing.html),
Director of the Innovative Computing Laboratory,
The University of Tennessee
