async = require '../coffee/async2'
chai = require 'chai'
assert = chai.assert

class Debugger
  @started: new Date()
  @log: (s) ->
    if console?
      current = new Date()
      s.unshift "[#{(current - @started) / 1000}s]"
      console.log s

delay=(s,f)->setTimeout f,s
rdelay=(f)->setTimeout f,Math.random()*100*Math.random()*10
since=(d)->new Date-d

# you can accomplish anything you want in a single hierarchy
# just by reordering the order of operations
# no real need to nest two asyncs

describe 'Async2', ->

  start = undefined

  beforeEach ->
    start = new Date
    slowFunc = (log, sec, done) ->
      delay sec, ->
        console.log "[#{(new Date - start)/1000}s] #{log}"
        done()

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
    async
      .parallel(->( get_data = (cb) -> delay 10, cb )(@))
      .serial(->( make_folder = (cb) -> delay 50, cb )(@)) # same time as get_data
      .serial(->( write_file = (cb) -> delay 100, cb )(@)) # after get_data and make_folder
      .serial(->( email_link = (cb) -> delay 250, cb )(@)) # after write_file
      .end ->
        assert.closeTo Math.max(10,50)+100+250, since(start), 25
        done()

  it 'can accomplish async.js::waterfall() with serial()', (done) ->
    # see also: https://github.com/caolan/async#waterfall
    async
      .serial(-> delay 50, @ 'async.js is silly. pass it on.' )
      .serial((result)-> delay 50, @ result )
      .serial((result)-> delay 50, @ result + ' ok maybe its not too silly.' )
      .end (result) ->
        assert.equal result, 'async.js is silly. pass it on. ok maybe its not too silly.'
        done()

  it 'accepts enumerable objects as task input, executing immediately', (done) ->
    # legacy async.js backward compatibility
    async.series [
     -> delay 100, @
     -> delay 50, @
    ], ->
      assert.closeTo 100+50, since(start), 25
      done()

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

  #it 'even whilst()', (done) ->
  #  console.log 'starting whilst example... should see 0 1 2 3 4 done'
  #  a = 0
  #  async.whilst (-> a < 5 ),
  #    ((done)-> delay 500, -> console.log "a is #{a}"; a++; done() ),
  #    (-> console.log 'done'; done())
