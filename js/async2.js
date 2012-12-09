// Generated by CoffeeScript 1.4.0
(function() {
  var async;

  module.exports = async = (function() {

    async.whilst = function(test, iterator, callback) {
      var _this;
      _this = this;
      return test() ? iterator(function(err){return err ? callback(err) : _this.whilst(test,iterator,callback)}) : callback();
    };

    async.begin = function() {
      return new async();
    };

    function async() {
      this.a = [];
      this.beginning_length = 0;
      this.processed = 0;
    }

    async.prototype._call = function(result, err) {
      var a;
      if (err) {
        a = this.a[this.a.length - 1];
        this.a = [];
      } else if (this.a.length) {
        a = this.a[0];
      }
      if (typeof a !== 'undefined') {
        return a.call((function() {}), result, err);
      }
    };

    async.prototype._pop = function(parallel, result, err) {
      var current, next,
        _this = this;
      current = this.a.shift();
      next = this.a[0];
      return function(result, err) {
        _this.processed++;
        if (err) {
          return _this._call(result, err);
        }
        if (!parallel || _this.processed === _this.beginning_length) {
          while (_this._call(result, err) && parallel) {}
        }
      };
    };

    async.prototype._push = function(cb, parallel) {
      var _this = this;
      this.beginning_length++;
      this.a.push(function(result, err) {
        if (_this.inbetween_cb != null) {
          _this.inbetween_cb(result, err);
        }
        cb.call(_this._pop(parallel, result, err), result, err);
        if (parallel && 1 !== _this.a.length) {
          _this._call(result, err);
        }
        return parallel;
      });
      return this;
    };

    async.prototype.serial = function(cb) {
      return this._push(cb, false);
    };

    async.prototype.parallel = function(cb) {
      return this._push(cb, true);
    };

    async.prototype.inbetween = function(inbetween_cb) {
      this.inbetween_cb = inbetween_cb;
      return this;
    };

    async.prototype.rescue = function(rescue_cb) {
      this.rescue_cb = rescue_cb;
      return this;
    };

    async.prototype.success = function(success_cb) {
      this.success_cb = success_cb;
      return this;
    };

    async.prototype.end = function(cb) {
      var _this = this;
      this.a.push(function(result, err) {
        if (_this.inbetween_cb != null) {
          _this.inbetween_cb(result, err);
        }
        if (err && (_this.rescue_cb != null)) {
          _this.rescue_cb(err);
        } else if (_this.success_cb != null) {
          _this.success_cb(result);
        }
        return cb.call((function() {}), result, err);
      });
      this._call(void 0, null);
      return this;
    };

    return async;

  })();

}).call(this);
