class global.Debugger
  @started: new Date()
  @log: (s) ->
    if console?
      current = new Date()
      s.unshift "[#{(current - @started) / 1000}s]"
      console.log s

global.delay = (s,f) ->
  setTimeout f, s

global.rdelay = (f) ->
  setTimeout f, Math.random() * 100 * Math.random() * 10

global.since = (d) ->
  new Date - d

global.slowFunc = (log, sec, done) ->
  delay sec, ->
    Debugger.log log
    done()
