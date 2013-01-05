# Async2.js

Better asynchronous javascript flow control in [98 lines](https://github.com/mikesmullin/async2/blob/stable/js/async2.js) or [2.59KB minified (990 bytes gzipped)](https://raw.github.com/mikesmullin/async2/stable/js/async2.min.js).

Inspired by [async](https://github.com/caolan/async),
[mini-async](https://github.com/mikesmullin/mini-async),
[Mocha](https://github.com/visionmedia/mocha),
[Chai](https://github.com/chaijs/chai),
[Should.js](https://github.com/visionmedia/should.js/), and
[IcedCoffeeScript](http://maxtaco.github.com/coffee-script/)/[TameJs](http://tamejs.org/)
libraries.

### Flow Control

* [new / flow / with](#find-examples-in-the-tests) : optional chainable instantiator; receives beginning result; useful in series
* [beforeAll / before](#find-examples-in-the-tests) : non-blocking function called once before first task
* [beforeEach](#find-examples-in-the-tests) : non-blocking function called once before each task
* [serial / series / blocking / waterfall](#find-examples-in-the-tests) : blocking function called in order; results optionally waterfalled
* [parallel / nonblocking](#find-examples-in-the-tests) : non-blocking function called in order
* [do / then / try / begin / start / auto](#find-examples-in-the-tests) : optionally blocking function called in order; determined by length of arguments callback expects
* [afterEach / between / inbetween](#find-examples-in-the-tests) : non-blocking function called once after each task
* [error / catch / rescue](#find-examples-in-the-tests) : blocking function called when error occurs
* [success / else](#find-examples-in-the-tests) : non-blocking function called after all tasks have completed, but only if no errors occur
* [end / finally / ensure / afterAll / after / complete / done / go](#find-examples-in-the-tests) : blocking function called after all tasks have completed
* [whilst](#find-examples-in-the-tests) : provide test, iterator, and callback functions. will iterate until test passes, then execute callback

## Quick Examples

### First, reflect upon our haiku mantra:

> "thoughtful single-chain

> order of operations

> escape callback hell!"

<a name="find-examples-in-the-tests" />

### Then, observe in action:

Backward-compatible with async.js:

```coffeescript
async.series [
 -> delay 100, @
 -> delay 50, @
], ->
  assert.closeTo 100+50, since(start), 25

  async.parallel [
   -> delay 100, @
   -> delay 50, @
  ], ->
    assert.closeTo (100+50)+100, since(start), 25
    done()
```

But better thanks to several improvements:

```coffeescript
async
  .serial((next) ->
    assert.typeOf next, 'function'
    next null, 'async data' # e.g., fs.readFile(), or jQuery.ajax()
  )
  .parallel((data, next) ->
    assert.equal data, 'async data'
    assert.typeOf next, 'function'
    next null
  )
  .parallel((data, next) ->
    assert.equal data, 'async data'
    assert.typeOf next, 'function'
    next null
  )
  .serial(->
    assert.typeOf @, 'function' # `this` === `next`
    @ null, 1, 2, 3, 4, 5, 6
  )
  .end (err, results...) ->
    assert.equal err, null
    assert.deepEqual s, [ 1, 2, 3, 4, 5, 6 ]
    done()
```

In fact, way better:

```coffeescript
delay = (s,f) -> setTimeout f, s
flow = new async
for i in [1..10]
  ((i) ->
    method = if i%3 then 'parallel' else 'serial' # an overcomplicated display of flexibility
    flow[method] (next) ->
      delay 25, ->
        console.log "#{method} #{i}"
        next()
  )(i)
flow.go (err, results...) ->
  console.log 'try this in async.js!'
  done()
```

It really makes you wonder, how long have you been needing a good flow control library, and not known it?

Look familiar to any jQuery.ajax() developers?

```coffeescript
called = false
async
  before: ->
    #loading.show()
    called = true
  do: (next) ->
    # main logic
    assert.ok called
    next 'err', 'result'
  error: (err) ->
    assert.equal 'err', 'err'
    #alert err
  success: (result) ->
    assert false, 'success() should not have been called here'
    #console.log data
  complete: (err, result) ->
    assert.equal err, 'err'
    assert.equal result, 'result'
    #loading.hide()
    done()
```

How about to you JavaScript developers?

```coffeescript
called = false
async
  .try(->
    @ new Error 'thrown node cb style'
  )
  .catch((err) ->
    called = true
    assert.equal ''+err, 'Error: thrown node cb style'
  )
  .finally (err, result) ->
    assert.ok called
    assert.equal ''+err, 'Error: thrown node cb style'
    assert.typeOf result, 'undefined'
    done()
```

Any Rubists in the audience?

```coffeescript
called = false
async
  .begin(->
    @ new Error 'thrown node cb style'
  )
  .rescue((err) ->
    called = true
    assert.equal ''+err, 'Error: thrown node cb style'
  )
  .else((result) ->
    console.log 'Else'
    assert false, 'else() should not have been called here'
  )
  .ensure (err, result) ->
    assert.ok called
    assert.equal ''+err, 'Error: thrown node cb style'
    assert.typeOf result, 'undefined'
    done()
```

These are just a few things it can do.

For the latest examples, review the easy-to-follow [./test/test.coffee](https://github.com/mikesmullin/async2/blob/stable/test/test.coffee).

Or try it immediately in your browser with [codepen](http://codepen.io/mikesmullin/pen/tscfD).

TODO
----

* potential node.js madness: each series becomes its own cpu thread, each parallel becomes its own gpu thread.

> "GPUs have evolved to the point where many real-world applications are easily implemented on them and run significantly faster than on multi-core systems. Future computing architectures will be hybrid systems with parallel-core GPUs working in tandem with multi-core CPUs.'
-- [Professor Jack Dongarra](http://www.nvidia.com/object/what-is-gpu-computing.html),
Director of the Innovative Computing Laboratory,
The University of Tennessee
