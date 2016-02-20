# Async2.js

Better asynchronous javascript flow control in [132 lines (5.7KB)](https://github.com/mikesmullin/async2/blob/stable/js/async2.js) or [4KB minified](https://raw.github.com/mikesmullin/async2/stable/js/async2.min.js) or [1285 bytes gzipped](https://raw.github.com/mikesmullin/async2/stable/js/async2.min.js.gz).

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
* [serial / series / blocking / waterfall](#find-examples-in-the-tests) : blocking function called in order; results always waterfalled
* [parallel / nonblocking](#find-examples-in-the-tests) : non-blocking function called in order
* [do / then / try / begin / start / auto](#find-examples-in-the-tests) : optionally blocking function called in order; determined by length of arguments callback expects
* [afterEach / between / inbetween](#find-examples-in-the-tests) : non-blocking function called once after each task
* [error / catch / rescue](#find-examples-in-the-tests) : blocking function called when error occurs
* [success / else](#find-examples-in-the-tests) : non-blocking function called after all tasks have completed, but only if no errors occur
* [end / finally / ensure / afterAll / after / complete / done / go](#find-examples-in-the-tests) : blocking function called after all tasks have completed
* [whilst](#find-examples-in-the-tests) : provide test, iterator, and callback functions. will iterate until test passes, then execute callback
* [delay](#find-examples-in-the-tests) : inverts argument order to `setTimeout()` for easier CoffeeScript markup
* [push / nextTickGroup](#find-examples-in-the-tests) : serially-queued automatic-kick-start execution like `nextTick()` or `setTimeout(f,0)`, but grouped

## Quick Examples

### First, reflect upon our haiku mantra:

    5  thoughtful single-chain
    7  order of operations
    5  escape callback hell!

<a name="find-examples-in-the-tests" />

### Then, observe in action:

Partially backward-compatible with async.js:

```coffeescript
async.series [
 -> async.delay 100, @
 -> async.delay 50, @
], ->
  assert.closeTo 100+50, since(start), 25

  async.parallel [
   -> async.delay 100, @
   -> async.delay 50, @
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
    assert.deepEqual results, [ 1, 2, 3, 4, 5, 6 ]
    done()
```

In fact, way better:

```coffeescript
flow = new async
for i in [1..10]
  ((i) ->
    method = if i%3 then 'parallel' else 'serial' # an overcomplicated display of flexibility
    flow[method] (next) ->
      async.delay 25, ->
        console.log "#{method} #{i}"
        next()
  )(i)
flow.go (err, results...) ->
  console.log 'try this in async.js!'
  done()
```

It really makes you wonder: how long have we needed a good asynchronous flow control library, and not known it?

Exhibit A: Look familiar to any jQuery.ajax() developers?

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

Exhibit B: How about to you JavaScript developers?

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

Exhibit C: Any Rubists in the audience?

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

Additionally, `nextTick()` users will appreciate the lazy man's grouped blocking serial execution:

```coffeescript
async.push 'A', (next) ->
  setTimeout (-> console.log 'second'; next()), 100
async.push 'B', (next) ->
  setTimeout (-> console.log 'first'; next()), 10
async.push 'A', (next) ->
  setTimeout (-> console.log 'third'; next()), 1
# outputs:
# first
# second
# third
```

These are just a few of all the things it can do.

For the latest examples, review the easy-to-follow [./test/test.coffee](https://github.com/mikesmullin/async2/blob/stable/test/test.coffee).

Or try it immediately in your browser with [codepen](http://codepen.io/mikesmullin/pen/tscfD).

## FAQ

 * **great another high horsed coffeescripter!**
   i just prefer to author in coffee. the .js and .js.min versions are in here too.
   you can do all the same things; in fact it is partially backward-compatible with async.js
   but in less lines of .js
   less bytes i should say; its a minimalist implementation
   with some improvements.

 * **have you tried pull requests to the async repo?**
   i may if i get positive response
   but its 100% refactor from ground-up; its not just a pull request.
   also any snide remarks are meant to encourage spirited but constructive debate.
   i'm not trying to be divisive. just had a need with a short timeline :)
   i know a lot of people get used to the way things are...

