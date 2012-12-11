# Async2.js

Better asynchronous javascript flow control in [98 lines](https://github.com/mikesmullin/async2/blob/production/js/async2.js) or [2.59KB minified (990 bytes gzipped)](https://raw.github.com/mikesmullin/async2/production/js/async2.min.js).

Inspired by [async](https://github.com/caolan/async),
[mini-async](https://github.com/mikesmullin/mini-async),
[Mocha](https://github.com/visionmedia/mocha),
[Chai](https://github.com/chaijs/chai),
[Should.js](https://github.com/visionmedia/should.js/), and
[IcedCoffeeScript](http://maxtaco.github.com/coffee-script/)/[TameJs](http://tamejs.org/)
libraries.

### Flow Control

* [begin / try / new](#find-examples-in-the-tests) : chainable instantiation; not required but sometimes useful
* [beforeAll / before](#find-examples-in-the-tests) : non-blocking function called once before first task
* [beforeEach](#find-examples-in-the-tests) : non-blocking function called once before each task
* [serial / series / blocking / waterfall](#find-examples-in-the-tests) : blocking function called in order; results optionally waterfalled.
* [parallel / nonblocking](#find-examples-in-the-tests) : non-blocking function called in order
* [do / then / auto](#find-examples-in-the-tests) : optionally blocking function called in order; determined by length of arguments callback expects
* [afterEach / between / inbetween](#find-examples-in-the-tests) : non-blocking function called once after each task
* [error / catch / rescue](#find-examples-in-the-tests) : blocking function called when error occurs
* [success / else](#find-examples-in-the-tests) : non-blocking function called after all tasks have completed, but only if no errors occur
* [end / finally / ensure / afterAll / after / complete / done](#find-examples-in-the-tests) : blocking function called after all tasks have completed
* [whilst](#find-examples-in-the-tests) : provide test, iterator, and callback functions. will iterate until test passes, then execute callback

## Quick Examples

### First, reflect upon our haiku mantra:

> "thoughtful single-chain

> order of operations

> escape callback hell!"

<a name="find-examples-in-the-tests" />
For the latest examples, review the easy-to-follow [./test/test.coffee](https://github.com/mikesmullin/async2/blob/production/js/async2.js).

Or try it immediately in your browser with [codepen](http://codepen.io/mikesmullin/pen/tscfD).

TODO
----

* potential node.js madness: each series becomes its own cpu thread, each parallel becomes its own gpu thread.

> "GPUs have evolved to the point where many real-world applications are easily implemented on them and run significantly faster than on multi-core systems. Future computing architectures will be hybrid systems with parallel-core GPUs working in tandem with multi-core CPUs.'
-- [Professor Jack Dongarra](http://www.nvidia.com/object/what-is-gpu-computing.html),
Director of the Innovative Computing Laboratory,
The University of Tennessee
