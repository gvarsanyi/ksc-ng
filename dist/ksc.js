
/**
 * These are the consolidated coffee-script helper functions used across
 * the ksc objects.
 * Coffee-script compiler adds these functions as needed to each compiled
 * files header. In the concatenation process those get removed and this
 * consolidated version gets used: no more helper function dupes.
 */

var __hasProp = {}.hasOwnProperty,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  __slice = [].slice;


ksc = angular.module('ksc', []);



ksc.factory('ksc.ArrayTracker', [
  'ksc.error', 'ksc.util', function(error, util) {
    var ArrayTracker, define_get_set, define_value, has_own;
    define_get_set = util.defineGetSet;
    define_value = util.defineValue;
    has_own = util.hasOwn;
    return ArrayTracker = (function() {
      ArrayTracker.prototype.get = void 0;

      ArrayTracker.prototype.list = void 0;

      ArrayTracker.prototype.set = void 0;

      ArrayTracker.prototype.store = void 0;

      function ArrayTracker(list, store, setter, getter) {
        var fn, fnize, index, key, tracker, value, _i, _len;
        if (store == null) {
          store = {};
        }
        if (has_own(list, '_tracker')) {
          error.Value({
            list: list,
            description: 'List is already tracked'
          });
        }
        if (!Array.isArray(list)) {
          error.Type({
            list: list,
            description: 'Must be an array'
          });
        }
        if (typeof store !== 'object') {
          error.Type({
            store: store,
            description: 'Must be an object'
          });
        }
        tracker = this;
        define_value(list, '_tracker', tracker);
        define_value(tracker, 'list', list, 0, 1);
        define_value(tracker, 'store', store, 0, 1);
        fnize = function(fn) {
          if (fn != null) {
            if (typeof fn !== 'function') {
              error.Type({
                fn: fn,
                'Must be a function': 'Must be a function'
              });
            }
          } else {
            fn = null;
          }
          return fn;
        };
        getter = fnize(getter);
        setter = fnize(setter);
        define_get_set(tracker, 'get', (function() {
          return getter;
        }), (function(fn) {
          return getter = fnize(fn);
        }), 1);
        define_get_set(tracker, 'set', (function() {
          return setter;
        }), (function(fn) {
          return setter = fnize(fn);
        }), 1);
        for (key in ArrayTracker) {
          fn = ArrayTracker[key];
          if (key.substr(0, 1) === '_') {
            (function(key) {
              return define_value(list, key.substr(1), function() {
                var args;
                args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
                return ArrayTracker[key].apply(tracker, args);
              });
            })(key);
          }
        }
        for (index = _i = 0, _len = list.length; _i < _len; index = ++_i) {
          value = list[index];
          ArrayTracker.getterify(tracker, index);
          ArrayTracker.set(tracker, index, value);
        }
      }

      ArrayTracker.getterify = function(tracker, index) {
        return define_get_set(tracker.list, index, (function() {
          return ArrayTracker.get(tracker, index);
        }), (function(value) {
          return ArrayTracker.set(tracker, index, value);
        }), 1);
      };

      ArrayTracker.get = function(tracker, index) {
        if (tracker.get) {
          return tracker.get(index, tracker.store[index]);
        }
        return tracker.store[index];
      };

      ArrayTracker.set = function(tracker, index, value) {
        var work;
        work = function() {
          if (arguments.length) {
            value = arguments[0];
          }
          if (tracker.store[index] === value) {
            return false;
          }
          tracker.store[index] = value;
          return true;
        };
        if (tracker.set) {
          return tracker.set(index, value, work);
        } else {
          return work();
        }
      };

      ArrayTracker.add = function(tracker, items, index) {
        var i, item, items_len, list, orig_len, store, _i, _j, _len, _ref;
        list = tracker.list, store = tracker.store;
        items_len = items.length;
        orig_len = list.length;
        for (i = _i = _ref = orig_len - 1; _i >= index; i = _i += -1) {
          store[i + items_len] = store[i];
        }
        for (i = _j = 0, _len = items.length; _j < _len; i = ++_j) {
          item = items[i];
          list[i + orig_len] = null;
          ArrayTracker.getterify(tracker, i + orig_len);
          ArrayTracker.set(tracker, i + index, item);
        }
        return list.length;
      };

      ArrayTracker._pop = function() {
        var index, list, res, store;
        list = this.list, store = this.store;
        if ((index = list.length - 1) > -1) {
          res = list[index];
          list.length = index;
          delete store[index];
          return res;
        }
      };

      ArrayTracker._shift = function() {
        var i, index, list, res, store, _i;
        list = this.list, store = this.store;
        if ((index = list.length - 1) > -1) {
          res = list[0];
          for (i = _i = 1; _i <= index; i = _i += 1) {
            store[i - 1] = store[i];
          }
          list.length = index;
          delete store[index];
          return res;
        }
      };

      ArrayTracker._push = function() {
        var items;
        items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return ArrayTracker.add(this, items, this.list.length);
      };

      ArrayTracker._unshift = function() {
        var items;
        items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return ArrayTracker.add(this, items, 0);
      };

      ArrayTracker._splice = function() {
        var how_many, i, index, items, list, orig_len, res, store, _i, _j, _ref;
        index = arguments[0], how_many = arguments[1], items = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
        list = this.list, store = this.store;
        res = [];
        orig_len = list.length;
        index = parseInt(index, 10) || 0;
        if (index < 0) {
          index = Math.max(0, orig_len + index);
        } else {
          index = Math.min(index, orig_len);
        }
        how_many = parseInt(how_many, 10) || 0;
        how_many = Math.max(0, Math.min(how_many, orig_len - index));
        if (how_many) {
          for (i = _i = index, _ref = index + how_many; _i < _ref; i = _i += 1) {
            res.push(list[i]);
            delete store[orig_len + i - index];
          }
          for (i = _j = index; _j < orig_len; i = _j += 1) {
            store[i] = store[i + how_many];
          }
          list.length = orig_len - how_many;
        }
        if (items.length) {
          ArrayTracker.add(this, items, index);
        }
        return res;
      };

      ArrayTracker._sort = function() {
        var args, copy, i, index, list, res, store, tracker, value, _i, _len, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _ref = tracker = this, list = _ref.list, store = _ref.store;
        copy = (function() {
          var _i, _ref1, _results;
          _results = [];
          for (i = _i = 0, _ref1 = list.length; _i < _ref1; i = _i += 1) {
            _results.push(store[i]);
          }
          return _results;
        })();
        list.length = 0;
        Array.prototype.push.apply(list, copy);
        res = Array.prototype.sort.apply(list, args);
        for (index = _i = 0, _len = list.length; _i < _len; index = ++_i) {
          value = list[index];
          ArrayTracker.getterify(tracker, index);
          ArrayTracker.set(tracker, index, value);
        }
        return res;
      };

      return ArrayTracker;

    })();
  }
]);
ksc.service('ksc.batchLoaderRegistry', [
  'ksc.error', 'ksc.util', function(error, util) {

    /*
    A registry service for {BatchLoader} instances and interface for $http.get
    users to try and use a batch loader
    
    @note This is meant to be a low-level service, no high level code should be
      using this API
    
    @author Greg Varsanyi
     */
    var BatchLoaderRegistry;
    BatchLoaderRegistry = (function() {
      function BatchLoaderRegistry() {}

      BatchLoaderRegistry.prototype.map = {};


      /*
      Add a GET request to a {BatchLoader} instance request list if there is one
      to accept it and return its promise (or false if none found to take it)
      
      @param [string] url url string without query parameters
      @param [Object] query_parameters (optional) key-value map of query params
      
      @return [false|Promise] Promise from a {BatchLoader#get} if any
       */

      BatchLoaderRegistry.prototype.get = function(url, query_parameters) {
        var endpoint, loader, promise, _ref;
        _ref = this.map;
        for (endpoint in _ref) {
          loader = _ref[endpoint];
          if (promise = loader.get(url, query_parameters)) {
            return promise;
          }
        }
        return false;
      };


      /*
      Register a {BatchLoader} instance using its {BatchLoader#endpoint}
      property as key on map
      
      @param [BatchLoader] loader {BatchLoader} instance to be registered
      
      @throw [KeyError] if loader is already registered or key is bugous
      
      @return [BatchLoader] registered {BatchLoader} instance
       */

      BatchLoaderRegistry.prototype.register = function(loader) {
        var endpoint;
        if (!(typeof (endpoint = loader != null ? loader.endpoint : void 0) === 'string' && util.isKeyConform(endpoint))) {
          error.Key({
            endpoint: endpoint,
            required: 'url'
          });
        }
        if (this.map[endpoint]) {
          error.Key({
            endpoint: endpoint,
            description: 'already registered'
          });
        }
        return this.map[endpoint] = loader;
      };


      /*
      Unregister a {BatchLoader} instance using its {BatchLoader#endpoint}
      property as key on map
      
      @param [BatchLoader] loader {BatchLoader} instance to be unregistered
      
      @return [boolean] indicates if removal has happened
       */

      BatchLoaderRegistry.prototype.unregister = function(loader) {
        if (!this.map[loader.endpoint]) {
          return false;
        }
        return delete this.map[loader.endpoint];
      };

      return BatchLoaderRegistry;

    })();
    return new BatchLoaderRegistry;
  }
]);
ksc.factory('ksc.BatchLoader', [
  '$http', '$q', 'ksc.batchLoaderRegistry', 'ksc.error', 'ksc.util', function($http, $q, batchLoaderRegistry, error, util) {
    var BatchLoader, argument_type_error, is_object;
    argument_type_error = error.ArgumentType;
    is_object = util.isObject;

    /*
    Batch loader class that can take GET requests for predefined URLs and
    create individual promises, send the joint request and resolve all
    individual promises
    
    The joint rquest is sent with method PUT
    
    Also supports states (open: true|false)
    
    Suggested use: bootstrap implementations with many HTTP GET requests
    
    @author Greg Varsanyi
     */
    return BatchLoader = (function() {
      BatchLoader.prototype.endpoint = null;

      BatchLoader.prototype.map = null;

      BatchLoader.prototype.open = true;

      BatchLoader.prototype.requests = null;


      /*
      
      @param [string] endpoint URL of
      @param [object] map key-value map of endpoint keys and URL matchers
      
      @throw [ArgumentTypeError] missing or mismatching endpoint or map
      @throw [TypeError] invalid map entry
       */

      function BatchLoader(endpoint, map) {
        var key, loader, open, setter, url;
        this.endpoint = endpoint;
        this.map = map;
        loader = this;
        if (!(endpoint && typeof endpoint === 'string')) {
          argument_type_error({
            endpoint: endpoint,
            required: 'string'
          });
        }
        if (!is_object(map)) {
          argument_type_error({
            map: map,
            required: 'object'
          });
        }
        for (key in map) {
          url = map[key];
          if (typeof url !== 'string' || !key) {
            error.Type({
              key: key,
              url: url,
              required: 'url string'
            });
          }
        }
        open = true;
        setter = function(value) {
          if (open && !value) {
            loader.flush();
          }
          return open = !!value;
        };
        util.defineGetSet(loader, 'open', (function() {
          return open;
        }), setter, 1);
        util.defineValue(loader, 'requests', [], 0, 1);
        batchLoaderRegistry.register(loader);
      }


      /*
      Add to the request list if the request is acceptable
      
      @param [string] url individual requests URL
      @param [object] query_parameters query arguments on a key-value map
      
      @throw [ArgumentTypeError] if url is not a string or invalid query params
      
      @return [false|Promise] individual mock promise for http response
       */

      BatchLoader.prototype.get = function(url, query_parameters) {
        var deferred, key, loader, matched_key, requests, value, _ref;
        loader = this;
        requests = loader.requests;
        if (!(url && typeof url === 'string')) {
          argument_type_error({
            url: url,
            required: 'string'
          });
        }
        if ((query_parameters != null) && !is_object(query_parameters)) {
          argument_type_error({
            query_parameters: query_parameters,
            required: 'object'
          });
        }
        if (!loader.open) {
          return false;
        }
        _ref = loader.map;
        for (key in _ref) {
          value = _ref[key];
          if (!(url === value)) {
            continue;
          }
          matched_key = key;
          break;
        }
        if (!matched_key) {
          return false;
        }
        deferred = $q.defer();
        requests.push({
          resource: matched_key,
          deferred: deferred
        });
        if (query_parameters) {
          requests[requests.length - 1].query = query_parameters;
        }
        return deferred.promise;
      };


      /*
      Flush requests (if any)
      
      @return [false|Promise] joint request promise (or false on no request)
       */

      BatchLoader.prototype.flush = function() {
        var batch_promise, defers, loader, request, requests, _i, _len;
        loader = this;
        requests = loader.requests;
        defers = [];
        for (_i = 0, _len = requests.length; _i < _len; _i++) {
          request = requests[_i];
          if (!request.deferred) {
            continue;
          }
          defers.push(request.deferred);
          delete request.deferred;
        }
        if (!defers.length) {
          return false;
        }
        batch_promise = $http.put(loader.endpoint, requests);
        batch_promise.success(function(data, status, headers, config) {
          var deferred, i, raw, res, _j, _len1, _ref;
          for (i = _j = 0, _len1 = defers.length; _j < _len1; i = ++_j) {
            deferred = defers[i];
            if ((res = data[i]) == null) {
              deferred.reject({
                data: data,
                status: status,
                headers: headers,
                config: config
              });
              continue;
            }
            raw = {
              data: res.body,
              status: res.status,
              headers: headers,
              config: config
            };
            if ((200 <= (_ref = res.status) && _ref < 400)) {
              deferred.resolve(raw);
            } else {
              deferred.reject(raw);
            }
          }
        });
        return batch_promise.error(function(data, status, headers, config) {
          var deferred, _j, _len1;
          for (_j = 0, _len1 = defers.length; _j < _len1; _j++) {
            deferred = defers[_j];
            deferred.reject({
              data: data,
              status: status,
              headers: headers,
              config: config
            });
          }
        });
      };

      return BatchLoader;

    })();
  }
]);

ksc.factory('ksc.EditableRecord', [
  'ksc.Record', 'ksc.error', 'ksc.util', function(Record, error, util) {
    var CHANGED_KEYS, CHANGES, DELETED_KEYS, EDITED, EVENTS, EditableRecord, OPTIONS, PARENT, PARENT_KEY, SAVED, define_value, has_own, is_enumerable, is_object;
    CHANGES = '_changes';
    CHANGED_KEYS = '_changedKeys';
    DELETED_KEYS = '_deletedKeys';
    EDITED = '_edited';
    EVENTS = '_events';
    OPTIONS = '_options';
    PARENT = '_parent';
    PARENT_KEY = '_parentKey';
    SAVED = '_saved';
    define_value = util.defineValue;
    has_own = util.hasOwn;
    is_enumerable = util.isEnumerable;
    is_object = util.isObject;

    /*
    Stateful record (overrides and extensions for {Record})
    
    Also supports contracts (see: {RecordContract})
    
    @example
        record = new EditableRecord {a: 1, b: 1}
        record.a = 2
        console.log record._changes # 1
        console.log record._changedKeys # {a: true}
        record._revert()
        console.log record.a # 1
        console.log record._changes # 0
    
    Options that may be used
    - .options.contract
    - .options.idProperty
    - .options.subtreeClass
    
    @author Greg Varsanyi
     */
    return EditableRecord = (function(_super) {
      __extends(EditableRecord, _super);

      EditableRecord.prototype._changedKeys = null;

      EditableRecord.prototype._changes = 0;

      EditableRecord.prototype._deletedKeys = null;

      EditableRecord.prototype._edited = null;


      /*
      Create the EditableRecord instance with initial data and options
      
      @throw [ArgumentTypeError] data, options, parent, parent_key type mismatch
      
      Possible errors thrown at {Record#_replace}
      @throw [TypeError] Can not take functions as values
      @throw [KeyError] Keys can not start with underscore
      
      @param [object] data (optional) initital (saved) data set for the record
      @param [object] options (optional) options to define endpoint, contract,
        id key property etc
      @param [object] parent (optional) reference to parent (list or
        parent record)
      @param [number|string] parent_key (optional) parent record's key
       */

      function EditableRecord(data, options, parent, parent_key) {
        if (data == null) {
          data = {};
        }
        if (options == null) {
          options = {};
        }
        if (!is_object(options)) {
          error.ArgumentType({
            options: options,
            argument: 2,
            required: 'object'
          });
        }
        options.subtreeClass = EditableRecord;
        EditableRecord.__super__.constructor.call(this, data, options, parent, parent_key);
      }


      /*
      Clone record or contents
      
      @param [boolean] return_plain_object (optional) return a vanilla js Object
      @param [boolean] saved_only (optional) return only saved-state data
      
      @return [Object|EditableRecord] the new instance with identical data
       */

      EditableRecord.prototype._clone = function(return_plain_object, saved_only) {
        var clone, deleted_keys, key, record, source, value;
        if (return_plain_object == null) {
          return_plain_object = false;
        }
        if (saved_only == null) {
          saved_only = false;
        }
        record = this;
        if (return_plain_object) {
          clone = {};
          source = saved_only ? record[SAVED] : record;
          for (key in source) {
            value = source[key];
            if (value instanceof Record) {
              value = value._clone(true, saved_only);
            }
            clone[key] = value;
          }
          return clone;
        }
        clone = new record.constructor(record[SAVED]);
        if (!saved_only) {
          for (key in record) {
            if (record[CHANGED_KEYS][key] || !has_own(record[SAVED], key)) {
              value = record[key];
              if (is_object(value)) {
                value = value._clone(true);
              }
              clone[key] = value;
            }
          }
          if (deleted_keys = record[DELETED_KEYS]) {
            for (key in record[DELETED_KEYS]) {
              clone._delete(key);
            }
          }
        }
        return clone;
      };


      /*
      Mark property as deleted, remove it from the object, but keep the original
      data (saved status) for the property.
      
      @param [string|number] keys... One or more keys to delete
      
      @throw [ArgumentTypeError] Provided key is not string or number
      @throw [ContractBreakError] Tried to delete on a contracted record
      @throw [MissingArgumentError] No key was provided
      
      @event 'update' sends out message on changes:
        events.emit 'update', {node: record, action: 'delete', keys: [keys]}
      
      @return [boolean] delete success indicator
       */

      EditableRecord.prototype._delete = function() {
        var changed, contract, i, id_property, key, keys, record, _i, _len;
        keys = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (!keys.length) {
          error.MissingArgument({
            name: 'key',
            argument: 1
          });
        }
        record = this;
        changed = [];
        for (i = _i = 0, _len = keys.length; _i < _len; i = ++_i) {
          key = keys[i];
          if (!util.isKeyConform(key)) {
            error.Key({
              key: key,
              argument: i,
              required: 'key conform value'
            });
          }
          if (!i && (contract = record[OPTIONS].contract)) {
            error.ContractBreak({
              key: key,
              value: value,
              contract: contract[key]
            });
          }
          if ((id_property = record[OPTIONS].idProperty) === key || (id_property instanceof Array && __indexOf.call(id_property, key) >= 0)) {
            error.Permission({
              key: key,
              description: '._options.idProperty keys can not be deleted'
            });
          }
          if (has_own(record[SAVED], key)) {
            if (record[DELETED_KEYS][key]) {
              continue;
            }
            record[DELETED_KEYS][key] = true;
            if (!record[CHANGED_KEYS][key]) {
              define_value(record, CHANGES, record[CHANGES] + 1);
              define_value(record[CHANGED_KEYS], key, true, 0, 1);
            }
            delete record[EDITED][key];
            Object.defineProperty(record, key, {
              enumerable: false
            });
            changed.push(key);
          } else if (has_own(record, key)) {
            if (!is_enumerable(record, key)) {
              error.Key({
                key: key,
                description: 'can not be changed'
              });
            }
            delete record[key];
            changed.push(key);
          }
        }
        if (changed.length) {
          Record.emitUpdate(record, 'delete', {
            keys: changed
          });
        }
        return !!changed.length;
      };


      /*
      (Re)define the initial data set (and drop changes)
      
      @param [object] data Key-value map of data
      
      Possible errors thrown at {Record#_replace}
      @throw [TypeError] Can not take functions as values
      @throw [KeyError] Keys can not start with underscore
      
      @event 'update' sends out message on changes:
        events.emit 'update', {node: record, action: 'replace'}
      
      @return [boolean] indicates change in data
       */

      EditableRecord.prototype._replace = function(data) {
        var changed, contract, dropped, events, key, record, value;
        record = this;
        if (events = record[EVENTS]) {
          events.halt();
        }
        try {
          dropped = record._revert(false);
          if (changed = EditableRecord.__super__._replace.call(this, data, false)) {
            contract = record[OPTIONS].contract;
            define_value(record, EDITED, {});
            define_value(record, CHANGES, 0);
            define_value(record, CHANGED_KEYS, {});
            define_value(record, DELETED_KEYS, contract ? null : {});
            define_value(record, SAVED, {});
            for (key in record) {
              value = record[key];
              define_value(record[SAVED], key, value, 0, 1);
              EditableRecord.setProperty(record, key);
            }
            Object.freeze(record[SAVED]);
          }
        } finally {
          if (events) {
            events.unhalt();
          }
        }
        if (dropped || changed) {
          Record.emitUpdate(record, 'replace');
        }
        return dropped || changed;
      };


      /*
      Return to saved state
      
      Drops deletions, edited and added properties (if any)
      
      @param [boolean] emit_event if replace should trigger event emission
        (defaults to true)
      
      @event 'update' sends out message on changes:
        events.emit 'update', {node: record, action: 'revert'}
      
      @return [boolean] indicates change in data
       */

      EditableRecord.prototype._revert = function(emit_event) {
        var changed, key, record;
        if (emit_event == null) {
          emit_event = true;
        }
        changed = false;
        record = this;
        for (key in record[DELETED_KEYS]) {
          delete record[DELETED_KEYS][key];
          delete record[CHANGED_KEYS][key];
          changed = true;
        }
        for (key in record[EDITED]) {
          delete record[EDITED][key];
          delete record[CHANGED_KEYS][key];
          changed = true;
        }
        for (key in record) {
          if (!(!has_own(record[SAVED], key))) {
            continue;
          }
          delete record[key];
          changed = true;
        }
        if (changed && emit_event) {
          define_value(record, CHANGES, 0);
          Record.emitUpdate(record, 'revert');
        }
        return changed;
      };


      /*
      Define getter/setter property on record based on {Record#_saved} and
      {EditableRecord#_edited} and {EditableRecord#_deleted}
      
      @param [object] record reference to object
      @param [string|number] key on record (and ._saved map)
      
      @return [undefined]
       */

      EditableRecord.setProperty = function(record, key) {
        var contract, edited, getter, options, saved, setter;
        saved = record[SAVED];
        edited = record[EDITED];
        options = record[OPTIONS];
        contract = options.contract;
        getter = function() {
          if (!contract && record[DELETED_KEYS][key]) {
            return;
          }
          if (has_own(edited, key)) {
            return edited[key];
          }
          return saved[key];
        };
        setter = function(update) {
          var changed, id_property, k, res, subopts, v, was_changed, _ref;
          if (typeof update === 'function') {
            error.Type({
              update: update,
              description: 'must not be function'
            });
          }
          if ((id_property = record[OPTIONS].idProperty) === key || (id_property instanceof Array && __indexOf.call(id_property, key) >= 0)) {
            if (!(update === null || ((_ref = typeof update) === 'string' || _ref === 'number'))) {
              error.Value({
                update: update,
                required: 'string or number or null'
              });
            }
          }
          if (util.identical(saved[key], update)) {
            delete edited[key];
            changed = true;
          } else if (!util.identical(edited[key], update)) {
            if (contract != null) {
              contract._match(key, update);
            }
            res = update;
            if (is_object(update)) {
              if (is_object(saved[key])) {
                res = saved[key];
                for (k in res) {
                  if (is_enumerable(res, k) && !has_own(update, k)) {
                    res._delete(k);
                  }
                }
              } else {
                subopts = {};
                if (contract) {
                  subopts.contract = contract[key].contract;
                }
                res = new EditableRecord({}, subopts, record, key);
              }
              for (k in update) {
                v = update[k];
                res[k] = v;
              }
            }
            edited[key] = res;
            changed = true;
          }
          if (edited[key] === saved[key]) {
            delete edited[key];
          }
          was_changed = record[CHANGED_KEYS][key];
          if ((is_object(saved[key]) && saved[key]._changes) || (has_own(edited, key) && !util.identical(saved[key], edited[key]))) {
            if (!was_changed) {
              define_value(record, CHANGES, record[CHANGES] + 1);
              define_value(record[CHANGED_KEYS], key, true, 0, 1);
            }
          } else if (was_changed) {
            define_value(record, CHANGES, record[CHANGES] - 1);
            delete record[CHANGED_KEYS][key];
          }
          if (changed) {
            if (record[PARENT_KEY]) {
              EditableRecord.subChanges(record[PARENT], record[PARENT_KEY], record[CHANGES]);
            }
            Object.defineProperty(record, key, {
              enumerable: true
            });
            return Record.emitUpdate(record, 'set', {
              key: key
            });
          }
        };
        util.defineGetSet(record, key, getter, setter, 1);
      };


      /*
      Event handler for child-object data change events
      Also triggers change event call upwards if state of changes gets modified
      in this level.
      
      @param [object] record reference to record or subrecord object
      @param [string|number] key key on this layer (e.g. parent) record
      @param [number] n number of changes in the child record
      
      @return [undefined]
       */

      EditableRecord.subChanges = function(record, key, n) {
        var changed;
        if (record[CHANGED_KEYS][key]) {
          if (!n) {
            define_value(record, CHANGES, record[CHANGES] - 1);
            delete record[CHANGED_KEYS][key];
            changed = true;
          }
        } else if (n) {
          define_value(record, CHANGES, record[CHANGES] + 1);
          define_value(record[CHANGED_KEYS], key, true, 0, 1);
          changed = true;
        }
        if (changed && record[PARENT_KEY]) {
          EditableRecord.subChanges(record[PARENT], record[PARENT_KEY], record[CHANGES]);
        }
      };

      return EditableRecord;

    })(Record);
  }
]);

ksc.factory('ksc.EditableRestRecord', [
  '$http', 'ksc.EditableRecord', 'ksc.Mixin', 'ksc.RestRecord', function($http, EditableRecord, Mixin, RestRecord) {

    /*
    Stateful record with REST bindings (load and save)
    
    @example
        record = new EditableRestRecord {a: 1, b: 1}, {endpoint: {url: '/test'}}
        record._restSave (err, raw_response) ->
          console.log 'Done with', err, 'error'
    
    Option used:
    - .options.endpoint.url
    
    @author Greg Varsanyi
     */
    var EditableRestRecord;
    return EditableRestRecord = (function(_super) {
      __extends(EditableRestRecord, _super);

      function EditableRestRecord() {
        return EditableRestRecord.__super__.constructor.apply(this, arguments);
      }

      Mixin.extend(EditableRestRecord, RestRecord);


      /*
      Trigger saving data to the record-style endpoint specified in
      _options.endpoint.url
      
      Uses PUT method
      
      Bumps up ._restPending counter by 1 when starting to load (and will
      decrease by 1 when done)
      
      @param [function] callback (optional) will call back with signiture:
        (err, raw_response) ->
      @option raw_response [HttpError] error (optional) errorous response info
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration
      
      @throw [ValueError] Missing endpoint url value
      @throw [TypeError] Endpoint url is not a string
      
      @return [HttpPromise] promise object created by $http
       */

      EditableRestRecord.prototype._restSave = function(callback) {
        var url;
        url = EditableRestRecord.getUrl(this);
        return EditableRestRecord.async(this, $http.put(url, this._entity()), callback);
      };

      return EditableRestRecord;

    })(EditableRecord);
  }
]);

ksc.service('ksc.error', function() {

  /*
  Custom error archetype class
   */
  var ArgumentTypeError, ContractBreakError, CustomError, ErrorTypes, HttpError, KeyError, MissingArgumentError, PermissionError, TypeError, ValueError, class_ref, error, name, _fn;
  CustomError = (function(_super) {
    __extends(CustomError, _super);


    /*
    Takes over constructor so that messages can be formulated off of an option
    hashmap or plain string (or no argument)
    
    @param [object] options
     */

    function CustomError(options) {
      var key, msg, value;
      msg = '';
      if (options && typeof options === 'object') {
        for (key in options) {
          value = options[key];
          try {
            value = JSON.stringify(value, null, 2);
          } catch (_error) {
            value = String(value);
          }
          msg += '\n  ' + key + ': ' + value;
        }
      } else if (options != null) {
        msg += String(options);
      }
      this.message = msg;
    }

    return CustomError;

  })(Error);

  /*
  Error for argument type mismatch
  @example
      unless typeof param is 'string'
        error.ArgumentType {param, argument: 1, required: 'string'}
   */
  ArgumentTypeError = (function(_super) {
    __extends(ArgumentTypeError, _super);

    function ArgumentTypeError() {
      return ArgumentTypeError.__super__.constructor.apply(this, arguments);
    }

    return ArgumentTypeError;

  })(CustomError);

  /*
  Error in attempt to change contracted data set
  @example
      unless rules.match key, value
        error.ContractBreak {key, value, contract: rules[key]}
   */
  ContractBreakError = (function(_super) {
    __extends(ContractBreakError, _super);

    function ContractBreakError() {
      return ContractBreakError.__super__.constructor.apply(this, arguments);
    }

    return ContractBreakError;

  })(CustomError);

  /*
  HTTP request/response error
  @example
      promise.catch (response) ->
        error.Http response
   */
  HttpError = (function(_super) {
    __extends(HttpError, _super);

    function HttpError() {
      return HttpError.__super__.constructor.apply(this, arguments);
    }

    return HttpError;

  })(CustomError);

  /*
  Key related errors (like syntax requirement fails etc)
  @example
      if key.substr(0, 1) is '_'
        error.Key {key, description: 'keys can not start with "_"'}
   */
  KeyError = (function(_super) {
    __extends(KeyError, _super);

    function KeyError() {
      return KeyError.__super__.constructor.apply(this, arguments);
    }

    return KeyError;

  })(CustomError);

  /*
  Required argument is missing
  @example
      unless param?
        error.MissingArgument {name: 'param', argument: 1}
   */
  MissingArgumentError = (function(_super) {
    __extends(MissingArgumentError, _super);

    function MissingArgumentError() {
      return MissingArgumentError.__super__.constructor.apply(this, arguments);
    }

    return MissingArgumentError;

  })(CustomError);

  /*
  Perimission related errors
  @example
      if key.substr(0, 1) is '_'
        error.Perimission {key, description: 'property is off-limit'}
   */
  PermissionError = (function(_super) {
    __extends(PermissionError, _super);

    function PermissionError() {
      return PermissionError.__super__.constructor.apply(this, arguments);
    }

    return PermissionError;

  })(CustomError);

  /*
  Type mismatch
  @example
      if typeof param is 'function'
        error.Type {param, description: 'must not be function'}
   */
  TypeError = (function(_super) {
    __extends(TypeError, _super);

    function TypeError() {
      return TypeError.__super__.constructor.apply(this, arguments);
    }

    return TypeError;

  })(CustomError);

  /*
  Value does not meet requirements
  @example
      unless param and typeof param is 'string'
        error.Value {param, description: 'must be non-empty string'}
   */
  ValueError = (function(_super) {
    __extends(ValueError, _super);

    function ValueError() {
      return ValueError.__super__.constructor.apply(this, arguments);
    }

    return ValueError;

  })(CustomError);

  /*
  Common named error types
  
  All-static class: error type classes are attached to ErrorTypes class instance
  
  This is going to be accessible via the ksc.error service:
  @example
         * use MissingArgumentError class
        throw new error.type.MissingArgument {name: 'result', argument: 1}
  
         * shorthand for auto-throw:
        error.MissingArgument {name: 'result', argument: 1}
   */
  ErrorTypes = (function() {
    function ErrorTypes() {}

    ErrorTypes.ArgumentType = ArgumentTypeError;

    ErrorTypes.ContractBreak = ContractBreakError;

    ErrorTypes.Http = HttpError;

    ErrorTypes.Key = KeyError;

    ErrorTypes.MissingArgument = MissingArgumentError;

    ErrorTypes.Permission = PermissionError;

    ErrorTypes.Type = TypeError;

    ErrorTypes.Value = ValueError;

    return ErrorTypes;

  })();
  error = {
    type: ErrorTypes
  };
  _fn = function(class_ref) {
    return error[name] = function(description) {
      throw new class_ref(description);
    };
  };
  for (name in ErrorTypes) {
    class_ref = ErrorTypes[name];
    class_ref.prototype.name = name + 'Error';
    _fn(class_ref);
  }
  return error;
});

ksc.factory('ksc.EventEmitter', [
  '$interval', '$rootScope', '$timeout', 'ksc.error', 'ksc.util', function($interval, $rootScope, $timeout, error, util) {
    var EventEmitter, EventSubscriptions, UNSUBSCRIBER, argument_type_error, is_function, is_object, name_check, subscription_decorator;
    UNSUBSCRIBER = '__unsubscriber__';
    argument_type_error = error.ArgumentType;
    is_function = util.isFunction;
    is_object = util.isObject;

    /*
    A class used by EventEmitter to store and manage callbacks.
    
    @author greg.varsanyi@kareo.com
     */
    EventSubscriptions = (function() {
      function EventSubscriptions() {}

      EventSubscriptions.prototype.names = null;


      /*
      Emission logic
      
      @param [string] name event identifier
      @param [*] args... optional arguments to be passed to the callback fn
      
      @return [boolean] indicates if at least one callback fn was called
       */

      EventSubscriptions.prototype.emit = function() {
        var args, block, callback, callback_found, id, name, names, once, _i, _len, _ref, _ref1;
        name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        names = (this.names != null ? this.names : this.names = {});
        block = (names[name] != null ? names[name] : names[name] = {});
        callback_found = false;
        block.fired = (block.fired || 0) + 1;
        block.lastArgs = args;
        _ref = [0, 1];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          once = _ref[_i];
          if (block[once]) {
            _ref1 = block[once];
            for (id in _ref1) {
              callback = _ref1[id];
              if (!(is_function(callback))) {
                continue;
              }
              callback_found = true;
              if (once) {
                delete block[once][id];
              }
              callback.apply(null, args);
            }
          }
        }
        return callback_found;
      };


      /*
      Calls the callback fn if the event was fired before (with the arguments of
      the last emission). Synchronous, will return after the callback is called.
      Used by EventEmitter.if() and EventEmitter.if1()
      
      @param [string] name event identifier
      @param [function] callback
      
      @return [boolean] indicates if a callback fn was called
       */

      EventSubscriptions.prototype.instantCall = function(name, callback) {
        var names, _ref;
        names = (this.names != null ? this.names : this.names = {});
        if ((_ref = names[name]) != null ? _ref.fired : void 0) {
          callback.apply(null, names[name].lastArgs);
          return true;
        }
        return false;
      };


      /*
      Registers one ore more new event subscriptions
      
      @param [string] names... event identifier(s)
      @param [boolean] once indicates one-time subscription (if1 and on1)
      @param [function] callback
      
      @return [function] unsubscriber
       */

      EventSubscriptions.prototype.push = function(names, once, callback) {
        var block, fn, ids, name, pseudo_unsubscriber, subscription_names, unsubscribed, _base, _i, _len;
        subscription_names = (this.names != null ? this.names : this.names = {});
        ids = [];
        once = once ? 1 : 0;
        for (_i = 0, _len = names.length; _i < _len; _i++) {
          name = names[_i];
          if (subscription_names[name] == null) {
            subscription_names[name] = {};
          }
          block = ((_base = subscription_names[name])[once] != null ? _base[once] : _base[once] = {
            i: 0
          });
          block[block.i] = callback;
          ids.push({
            name: name,
            id: block.i
          });
          block.i += 1;
        }
        unsubscribed = false;
        fn = EventEmitter.prototype.unsubscriber();
        pseudo_unsubscriber = function() {
          var inf, _j, _len1;
          if (unsubscribed) {
            return false;
          }
          unsubscribed = true;
          for (_j = 0, _len1 = ids.length; _j < _len1; _j++) {
            inf = ids[_j];
            delete subscription_names[inf.name][once][inf.id];
          }
          return true;
        };
        pseudo_unsubscriber[UNSUBSCRIBER] = true;
        fn.add(pseudo_unsubscriber);
        return fn;
      };

      return EventSubscriptions;

    })();
    name_check = function(name) {
      if (typeof name !== 'string') {
        argument_type_error({
          name: name,
          argument: 1,
          required: 'string'
        });
      }
      if (!name) {
        return error.Value({
          name: name,
          description: 'must be a non-empty string'
        });
      }
    };
    subscription_decorator = function(names, unsubscribe_target, callback, next) {
      var name, scope, unsubscriber_fn, _i, _len;
      if (this.subscriptions == null) {
        this.subscriptions = new EventSubscriptions;
      }
      if (!is_function(callback)) {
        argument_type_error({
          callback: callback,
          argument: 'last',
          required: 'function'
        });
      }
      if (!((unsubscribe_target != null ? unsubscribe_target[UNSUBSCRIBER] : void 0) || (is_object(unsubscribe_target) && (scope = $rootScope.isPrototypeOf(unsubscribe_target))))) {
        names.push(unsubscribe_target);
        unsubscribe_target = null;
      }
      for (_i = 0, _len = names.length; _i < _len; _i++) {
        name = names[_i];
        name_check(name);
      }
      unsubscriber_fn = next.call(this);
      if (unsubscribe_target) {
        if (scope) {
          unsubscribe_target.$on('$destroy', unsubscriber_fn);
        } else {
          unsubscribe_target.add(unsubscriber_fn);
        }
        return true;
      }
      return unsubscriber_fn;
    };

    /*
     * EventEmitter
    
    @author greg.varsanyi@kareo.com
    
    This class is meant to be extended by classes that may emit events outside
    Angular controllers' $broadcast/$emit concept (like service-service
    communication).
    
     *# API
    1. __Classic event listener__
            unsubscriber = event_obj.on('event'[, 'event2', ...], callback)
    2. __One-time event listener__
            unsubscriber = event_obj.on1('event'[, 'event2', ...], callback)
    3. __Event listener with instant callback if the event happened before__
            unsubscriber = event_obj.if('event'[, 'event2', ...], callback)
    4. __One-time event listener OR instant callback if the event happened
    before__
            unsubscriber = event_obj.if1('event'[, 'event2', ...], callback)
    5. __Emit event__
            event_obj.emit('event'[, args...]) # args are passed to listeners
    6. __Check if event was emitted before__
            event_obj.emitted('event') # returns false or latest call args array
    7. __Unsubscribe__
    Use the returned unsubscriber function:
            unsubscriber = event_obj.on('event', callback)
            unsubscriber() # callback won't get called on 'event'
    Unsubscribers are chainable with the .add method on the function
            unsubscriber = event_obj.on('event', callback)
            unsubscriber.add other_event_obj.if1('event2', callback)
            unsubscriber() # both subscriptions get removed
    You can pass your $scope while in a controller scope:
             * triggers an unsubscription with $scope.$on('$destroy', unsub_fn)
            event_obj.on('event', $scope, callback)
    With this signiture above you can also chain unsubscriber:
             * This is the preferred way for .if() and .if1() as those may call
             * the callback fn before the unsubscribe function is created as a
             * return value
            unsubscriber = event_obj.unsubscriber()
            event_obj.if1 'event', unsubscriber, ->
              other_event_obj.if1 'event', unsubscriber, ->
    
    Don't forget to unsubscribe when you destroy a scope. Not unsubscribing
    prevents garbage collection from running right and calling references on
    supposedly removed objects may lead to unexpected behavior.
     */
    return EventEmitter = (function() {
      function EventEmitter() {
        this.on = __bind(this.on, this);
        this.on1 = __bind(this.on1, this);
        this["if"] = __bind(this["if"], this);
        this.if1 = __bind(this.if1, this);
      }


      /*
      Emit event, e.g. call all functions subscribed for the specified event.
      
      @param [string] name event identifier
      @param [*] args... optional arguments to be passed to the callback fn
      
      @throw [ArgumentTypeError] name is not a string
      @throw [ValueError] name is empty
      
      @return [boolean] indicates if anything was called
       */

      EventEmitter.prototype.emit = function() {
        var args, name, _ref;
        name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        name_check(name);
        if (this._halt) {
          name = this._halt + '#!' + name;
        }
        return (_ref = (this.subscriptions != null ? this.subscriptions : this.subscriptions = new EventSubscriptions)).emit.apply(_ref, [name].concat(__slice.call(args)));
      };


      /*
      Check if this even was emitted before by the object.
      If so, it returns an array of the arguments of last emission which is
      the "args..." part of the emit(name, args...) method.
      
      @param [string] name event identifier
      
      @throw [ArgumentTypeError] name is not a string
      @throw [ValueError] name is empty
      
      @return [boolean|Array] false or Array of arguments
       */

      EventEmitter.prototype.emitted = function(name) {
        var subscriptions, _ref, _ref1;
        name_check(name);
        if ((_ref = (subscriptions = (_ref1 = this.subscriptions) != null ? _ref1.names[name] : void 0)) != null ? _ref.fired : void 0) {
          return subscriptions.lastArgs;
        }
        return false;
      };


      /*
      Prevent emit() from emitting.
      
      Bumps a counter, so you can define multi-level halters.
      
      Warning: all halt() calls should be coupled with exactly 1 unhalt() or
      things get messy.
      
      @return [number] updated halt level
       */

      EventEmitter.prototype.halt = function() {
        return this._halt = (this._halt || 0) + 1;
      };


      /*
      Enable emit() to emit again.
      
      Decreases the halt a counter.
      
      Warning: all halt() calls should be coupled with exactly 1 unhalt() or
      things get messy.
      
      @return [number] updated halt level
       */

      EventEmitter.prototype.unhalt = function() {
        return this._halt -= 1;
      };


      /*
      Subscribe for 1 event in the future OR the last emission if there was one
      
      @throw [ArgumentTypeError] name is not a string
      @throw [ValueError] name is empty
      @throw [ArgumentTypeError] callback not provided or not a function
      @throw [ArgumentTypeError] invalid unsubscribe target
      
      @overload if1(names..., unsubscribe_target, callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [$timeout|$interval|function] unsubscribe_target attach to
          unsubscriber event
        @param [function] callback function to call on event emission
      
        @return [boolean]
      
      @overload if1(names..., callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [function] callback function to call on event emission
      
        @return [function] unsubscriber
       */

      EventEmitter.prototype.if1 = function() {
        var callback, names, unsubscribe_target, _i;
        names = 3 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 2) : (_i = 0, []), unsubscribe_target = arguments[_i++], callback = arguments[_i++];
        return subscription_decorator.call(this, names, unsubscribe_target, callback, function() {
          var name, remainder, _j, _len;
          remainder = [];
          for (_j = 0, _len = names.length; _j < _len; _j++) {
            name = names[_j];
            if (!this.subscriptions.instantCall(name, callback)) {
              remainder.push(name);
            }
          }
          return this.subscriptions.push(remainder, 1, callback);
        });
      };


      /*
      Subscribe for future events AND the last emission if there was one
      
      @throw [ArgumentTypeError] name is not a string
      @throw [ValueError] name is empty
      @throw [ArgumentTypeError] callback not provided or not a function
      @throw [ArgumentTypeError] invalid unsubscribe target
      
      @overload if(names..., unsubscribe_target, callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [$timeout|$interval|function] unsubscribe_target attach to
          unsubscriber event
        @param [function] callback function to call on event emission
      
        @return [boolean]
      
      @overload if(names..., callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [function] callback function to call on event emission
      
        @return [function] unsubscriber
       */

      EventEmitter.prototype["if"] = function() {
        var callback, names, unsubscribe_target, _i;
        names = 3 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 2) : (_i = 0, []), unsubscribe_target = arguments[_i++], callback = arguments[_i++];
        return subscription_decorator.call(this, names, unsubscribe_target, callback, function() {
          var name, _j, _len;
          for (_j = 0, _len = names.length; _j < _len; _j++) {
            name = names[_j];
            this.subscriptions.instantCall(name, callback);
          }
          return this.subscriptions.push(names, 0, callback);
        });
      };


      /*
      Subscribe for 1 event in the future
      
      @throw [ArgumentTypeError] name is not a string
      @throw [ValueError] name is empty
      @throw [ArgumentTypeError] callback not provided or not a function
      @throw [ArgumentTypeError] invalid unsubscribe target
      
      @overload on1(names..., unsubscribe_target, callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [$timeout|$interval|function] unsubscribe_target attach to
          unsubscriber event
        @param [function] callback function to call on event emission
      
        @return [boolean]
      
      @overload on1(names..., callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [function] callback function to call on event emission
      
        @return [function] unsubscriber
       */

      EventEmitter.prototype.on1 = function() {
        var callback, names, unsubscribe_target, _i;
        names = 3 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 2) : (_i = 0, []), unsubscribe_target = arguments[_i++], callback = arguments[_i++];
        return subscription_decorator.call(this, names, unsubscribe_target, callback, function() {
          return this.subscriptions.push(names, 1, callback);
        });
      };


      /*
      Subscribe for events in the future
      
      @throw [ArgumentTypeError] name is not a string
      @throw [ValueError] name is empty
      @throw [ArgumentTypeError] callback not provided or not a function
      @throw [ArgumentTypeError] invalid unsubscribe target
      
      @overload on(names..., unsubscribe_target, callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [$timeout|$interval|function] unsubscribe_target attach to
          unsubscriber event
        @param [function] callback function to call on event emission
      
        @return [boolean]
      
      @overload on(names..., callback)
        @param [string] names... name(s) that identify event(s) to subscribe to
        @param [function] callback function to call on event emission
      
        @return [function] unsubscriber
       */

      EventEmitter.prototype.on = function() {
        var callback, names, unsubscribe_target, _i;
        names = 3 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 2) : (_i = 0, []), unsubscribe_target = arguments[_i++], callback = arguments[_i++];
        return subscription_decorator.call(this, names, unsubscribe_target, callback, function() {
          return this.subscriptions.push(names, 0, callback);
        });
      };


      /*
      Get an empty unsubscriber function you can add unsubscribers to
      
      @example
        unsub = MyEventEmitterObject.unsubscriber()
      
        unsub.add $interval(timed_fn, 100)
      
         * similar syntax with EventEmitter object
        unsub.add MyOtherEventEmitterObject.if('roar', lion_coming_fn)
      
         * this also works for EventEmitter objects
        MyOtherEventEmitterObject.if('meow', unsub, cat_coming_fn)
      
         * i want these events to stop firing in a minute
        $timeout unsub, 60000
      
      @example
         * link unsubscription to $scope lifecycle
        unsub = MyEventEmitterObject.unsubscriber $scope
      
        unsub.add $interval(timed_fn, 100)
      
         * similar syntax with EventEmitter object
        unsub.add MyOtherEventEmitterObject.if('roar', lion_coming_fn)
      
         * this also works for EventEmitter objects
        MyOtherEventEmitterObject.if('meow', unsub, cat_coming_fn)
      
      
      @param [Object] scope (optional) tie the lifecycle of unsubscriptions to
        controller lifecycle, i.e. will trigger unsubscribscription when
        controller receives the '$destroy' event.
      
      @return [function] unsubscriber
       */

      EventEmitter.prototype.unsubscriber = function(scope) {
        var attached, fn, increment;
        attached = {};
        increment = 0;

        /*
        Calls all added functions and cancels $interval/$timeout promises
        
        @return [null/bool] null = no added fn, true = all returned truthy
         */
        fn = function() {
          var id, node, status;
          status = null;
          for (id in attached) {
            node = attached[id];
            if (is_function(node)) {
              if (!node()) {
                status = false;
              }
            } else {
              if (node.$$intervalId != null) {
                $interval.cancel(node);
              } else {
                $timeout.cancel(node);
              }
            }
          }
          return status;
        };
        if (scope != null) {
          if (!$rootScope.isPrototypeOf(scope)) {
            argument_type_error({
              scope: scope,
              required: '$rootScope descendant'
            });
          }
          scope.$on('$destroy', fn);
        }
        fn[UNSUBSCRIBER] = true;
        fn.add = function(unsubscriber) {
          (function(increment) {
            var del, unknown;
            del = function() {
              return delete attached[increment];
            };
            unknown = function() {
              return argument_type_error({
                unsubscriber: unsubscriber,
                argument: 1,
                required: ['function', 'Promise']
              });
            };
            if (is_object(unsubscriber)) {
              if ((unsubscriber.$$timeoutId != null) && (unsubscriber["finally"] != null)) {
                unsubscriber["finally"](del);
              } else if ((unsubscriber.$$intervalId != null) && (unsubscriber["finally"] != null)) {
                unsubscriber["finally"](del);
              } else {
                unknown();
              }
            } else if (!(is_function(unsubscriber) && unsubscriber[UNSUBSCRIBER])) {
              unknown();
            }
            return attached[increment] = unsubscriber;
          })(increment);
          increment += 1;
          return true;
        };
        return fn;
      };

      return EventEmitter;

    })();
  }
]);
ksc.factory('ksc.ListMapper', [
  'ksc.util', function(util) {
    var ListMapper, deep_target, define_value;
    define_value = util.defineValue;

    /*
    Helper function that looks up named source references on .map and .pseudo
    hierarchies (aka target)
    
    @param [Object] target .map or .pseudo
    @param [Array] source_names (optional) list of source_names that ID target
    
    @return [undefined]
     */
    deep_target = function(target, source_names) {
      var source_name, _i, _len;
      if (source_names) {
        for (_i = 0, _len = source_names.length; _i < _len; _i++) {
          source_name = source_names[_i];
          target = target[source_name];
        }
      }
      return target;
    };

    /*
    A helper class that features creating look-up objects for mappable lists
    like {List} and {ListMask}.
    
    On construction, it creates .map={} (for {Record}s with ._id) and .pseudo={}
    (for {Record}s with no valid ._id but with valid ._pseudo ID) on the parent.
    
    @note Methods are prepped to handle multiple named sources for {ListMask}.
      If multi-sourced, .map and .pseudo will have sub-objects with keys being
      the source names. See: {ListMask}
    
    @note This class - being just an extension - has no error handling. All
      error cases should be handled by the callers
    
    @author Greg Varsanyi
     */
    return ListMapper = (function() {
      ListMapper.prototype.map = null;


      /*
      @property [boolean|undefined] indicates multiple named sources on parent.
        Set to boolean if parent is {ListMask} or undefined {List}.
       */

      ListMapper.prototype.multi = null;

      ListMapper.prototype.parent = null;

      ListMapper.prototype.pseudo = null;


      /*
      Creates containers for records with valid ._id (.map) and pseudo records
      (.pseudo)
      
      Adds references to itself (as ._mapper) and .map and .pseudo to parent.
      
      @param [List/ListMask] list reference to parent {List} or {ListMask}
       */

      function ListMapper(parent) {
        var build_maps, mapper, source;
        this.parent = parent;
        mapper = this;
        source = parent.source;
        define_value(mapper, 'map', {}, 0, 1);
        define_value(mapper, 'pseudo', {}, 0, 1);
        define_value(mapper, 'multi', source && !source._, 0, 1);
        define_value(mapper, '_sources', [], 0, 1);
        build_maps = function(parent, target_map, target_pseudo, names) {
          var item, source_list, source_name, src, subnames, _results;
          if (src = parent.source) {
            if (src._) {
              return build_maps(src._, target_map, target_pseudo, names);
            } else {
              _results = [];
              for (source_name in src) {
                source_list = src[source_name];
                target_map[source_name] = {};
                target_pseudo[source_name] = {};
                subnames = (function() {
                  var _i, _len, _results1;
                  _results1 = [];
                  for (_i = 0, _len = names.length; _i < _len; _i++) {
                    item = names[_i];
                    _results1.push(item);
                  }
                  return _results1;
                })();
                subnames.push(source_name);
                _results.push(build_maps(source_list, target_map[source_name], target_pseudo[source_name], subnames));
              }
              return _results;
            }
          } else {
            return mapper._sources.push({
              names: names,
              source: parent
            });
          }
        };
        build_maps(parent, mapper.map, mapper.pseudo, []);
        Object.freeze(mapper._sources);
      }


      /*
      Add record to .map or .pseudo (whichever fits)
      
      @param [Record] record reference to a record
      @param [Array<string>] source_names (optional) named source identifier
      
      @return [Record] the added record
       */

      ListMapper.prototype.add = function(record, source_names) {
        var id, mapper, target;
        mapper = this;
        if (record._id != null) {
          id = record._id;
          target = mapper.map;
        } else {
          id = record._pseudo;
          target = mapper.pseudo;
        }
        target = deep_target(target, source_names);
        return target[id] = record;
      };


      /*
      Delete record from .map or .pseudo (whichever fits)
      
      @overload del(map_id, pseudo_id, source_names)
        @param [string|number] map_id (optional) ._id of record
        @param [string|number] pseudo_id (optional) ._pseudo ID of record
        @param [Array<string>] source_names (optional) named source identifier
      @overload del(record, na, source_names)
        @param [Record] record reference to a record on .map or .pseudo
        @param [null] na (skipped)
        @param [Array<string>] source_names (optional) named source identifier
      
      @return [undefined]
       */

      ListMapper.prototype.del = function(map_id, pseudo_id, source_names) {
        var mapper, target;
        mapper = this;
        if (util.isObject(map_id)) {
          pseudo_id = map_id._pseudo;
          map_id = map_id._id;
        }
        if (pseudo_id != null) {
          target = mapper.pseudo;
          map_id = pseudo_id;
        } else {
          target = mapper.map;
        }
        target = deep_target(target, source_names);
        delete target[map_id];
      };


      /*
      Find a record on .map or .pseudo (whichever fits)
      
      @overload has(map_id, pseudo_id, source_names)
        @param [string|number] map_id (optional) ._id of record
        @param [string|number] pseudo_id (optional) ._pseudo ID of record
        @param [Array<string>] source_names (optional) named source identifier
      @overload has(record, na, source_names)
        @param [Record] record reference to a record on .map or .pseudo
        @param [null] na (skipped)
        @param [Array<string>] source_names (optional) named source identifier
      
      @return [Record|false] found record or false if not found
       */

      ListMapper.prototype.has = function(map_id, pseudo_id, source_names) {
        var id, mapper, target;
        mapper = this;
        if (util.isObject(map_id)) {
          pseudo_id = map_id._pseudo;
          map_id = map_id._id;
        }
        if (pseudo_id != null) {
          id = pseudo_id;
          target = mapper.parent.pseudo;
        } else {
          id = map_id;
          target = mapper.parent.map;
        }
        target = deep_target(target, source_names);
        return target[id] || false;
      };


      /*
      Helper method that creates and registers mapper objects (.map, .pseudo and
      ._mapper) on provided Array instances created by {List} or {ListMask}
      
      @param [List] list reference to the list
      
      @return [undefined]
       */

      ListMapper.register = function(list) {
        var mapper;
        mapper = new ListMapper(list);
        define_value(list, '_mapper', mapper, 0, 1);
        define_value(list, 'map', mapper.map, 0, 1);
        define_value(list, 'pseudo', mapper.pseudo, 0, 1);
      };

      return ListMapper;

    })();
  }
]);

ksc.factory('ksc.ListMask', [
  '$rootScope', 'ksc.EventEmitter', 'ksc.List', 'ksc.ListMapper', 'ksc.ListSorter', 'ksc.error', 'ksc.util', function($rootScope, EventEmitter, List, ListMapper, ListSorter, error, util) {
    var ListMask, SCOPE_UNSUBSCRIBER, add_to_list, argument_type_error, array_push, cut_from_list, define_get_set, define_value, is_object, rebuild_list, register_filter, register_splitter, splitter_wrap;
    SCOPE_UNSUBSCRIBER = '_scopeUnsubscriber';
    argument_type_error = error.ArgumentType;
    define_get_set = util.defineGetSet;
    define_value = util.defineValue;
    is_object = util.isObject;
    array_push = Array.prototype.push;

    /*
    Helper function that adds element to list Array in a sort-sensitive way when
    needed
    
    @param [Array] list container array instance generated by ListMask
    @param [Record] record Item to inject
    
    @return [undefined]
     */
    add_to_list = function(list, record) {
      var item, pos, records, _i, _len;
      records = splitter_wrap(list, record);
      if (list.sorter) {
        for (_i = 0, _len = records.length; _i < _len; _i++) {
          item = records[_i];
          pos = list.sorter.position(item);
          Array.prototype.splice.call(list, pos, 0, item);
        }
      } else {
        array_push.apply(list, records);
      }
    };

    /*
    Helper function that removes elements from list Array
    
    @param [Array] list container array instance generated by ListMask
    @param [Array] records Record items to cut
    
    @return [undefined]
     */
    cut_from_list = function(list, records) {
      var record, target, tmp_container;
      tmp_container = [];
      while (record = Array.prototype.pop.call(list)) {
        target = record._original || record;
        if (__indexOf.call(records, target) < 0) {
          tmp_container.push(record);
        }
      }
      if (tmp_container.length) {
        tmp_container.reverse();
        array_push.apply(list, tmp_container);
      }
    };
    rebuild_list = function(list) {
      var record, source_info, _i, _j, _len, _len1, _ref, _ref1;
      util.empty(list);
      _ref = list._mapper._sources;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        source_info = _ref[_i];
        _ref1 = source_info.source;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          record = _ref1[_j];
          if (list.filter(record)) {
            array_push.apply(list, splitter_wrap(list, record));
          }
        }
      }
    };

    /*
    Helper function that registers a filter function on the {ListMask} object
    (and its .options object)
    
    @param [ListMask] list Reference to list mask
    
    @return [undefined]
     */
    register_filter = function(list) {
      var default_fn, filter, filter_get, filter_set;
      default_fn = (function() {
        return true;
      });
      if (!(filter = list.options.filter)) {
        filter = default_fn;
      }
      filter_get = function() {
        return filter;
      };
      filter_set = function(filter_function) {
        if (!filter_function) {
          filter_function = default_fn;
        }
        if (typeof filter_function !== 'function') {
          error.Type({
            filter_function: filter_function,
            required: 'function'
          });
        }
        filter = filter_function;
        return list.update();
      };
      define_get_set(list, 'filter', filter_get, filter_set, 1);
      define_get_set(list.options, 'filter', filter_get, filter_set, 1);
    };

    /*
    Helper function that registers a splitter function function on the
    {ListMask} object (and its .options object)
    
    @param [ListMask] list Reference to list mask
    
    @return [undefined]
     */
    register_splitter = function(list) {
      var default_fn, splitter, splitter_get, splitter_set;
      default_fn = (function() {
        return false;
      });
      if (!(splitter = list.options.splitter)) {
        splitter = default_fn;
      }
      splitter_get = function() {
        return splitter;
      };
      splitter_set = function(splitter_function) {
        if (!splitter_function) {
          splitter_function = default_fn;
        }
        if (typeof splitter_function !== 'function') {
          error.Type({
            splitter_function: splitter_function,
            required: 'function'
          });
        }
        splitter = splitter_function;
        return list.update();
      };
      define_get_set(list, 'splitter', splitter_get, splitter_set, 1);
      define_get_set(list.options, 'splitter', splitter_get, splitter_set, 1);
    };

    /*
    Helper function to wrap splitter function and turn them into an Array
    instance (either with the original record only, or all the masked record
    children)
    
    @param [Array] list Array instance generated by {ListMask}
    @param [Record] record Record instance to match and optionally split
    
    @return [Array]
     */
    splitter_wrap = function(list, record) {
      var info, key, record_mask, record_masks, result, value, _fn, _i, _len;
      if ((result = list.splitter(record)) && result instanceof Array) {
        record_masks = [];
        for (_i = 0, _len = result.length; _i < _len; _i++) {
          info = result[_i];
          if (!is_object(info)) {
            error.Type({
              splitter: list.splitter,
              description: 'If Array is returned, all elements must be ' + 'objects with override data'
            });
          }
          record_mask = Object.create(record);
          _fn = function(key, record) {
            var getter, setter;
            getter = function() {
              return record[key];
            };
            setter = function(value) {
              return record[key] = value;
            };
            return define_get_set(record_mask, key, getter, setter, 1);
          };
          for (key in record) {
            _fn(key, record);
          }
          for (key in info) {
            value = info[key];
            define_value(record_mask, key, value, 0, 1);
          }
          define_value(record_mask, '_original', record);
          record_masks.push(record_mask);
        }
        return record_masks;
      }
      return [record];
    };

    /*
    Masked list that picks up changes from parent {List} instance(s)
    Features:
    - may be a composite of multiple named parents/sources to combine different
    kinds of records in the list. That also addes namespaces to .map and .pseudo
    containers like: .map.sourcelistname
    - May filter records (by provided function)
    - May have its own sorter, see: {ListSorter}
    
    Adding to or removing from a ListMask is not allowed, all of those
    operations should happen on the parent list and autmatically boild down.
    
    This list also emits appropriate events on changes, just like {List} does
    so {ListMask}s can also be marked as source/parent for other {ListMask}s.
    
    @example
            list = new List
            list.push {id: 1, x: 'aaa'}, {id: 2, x: 'baa'}, {id: 3, x: 'ccc'}
    
            filter_fn = (record) -> # filter to .x properties that have char 'a'
              String(record.x).indexOf('a') > -1
    
            sublist = new ListMask list, filter_fn
            console.log sublist # [{id: 1, x: 'aaa'}, {id: 2, x: 'baa'}]
    
            list.map[1].x = 'xxx' # should remove item form sublist as it does
                                   * not meet the filter_fn requirement any more
    
            console.log sublist # [{id: 2, x: 'baa'}]
    
    @note Do not forget to manage the lifecycle of lists to prevent memory leaks
    @example
             * You may tie the lifecycle easily to a controller $scope by
             * just passing it to the constructor as last argument (arg #3 or #4)
            sublist = new ListMask list, filter_fn, $scope
    
             * you can destroy it at any time though:
            sublist.destroy()
    
    May also get two or more {List}s to form composite lists.
    In this case, sources must be named so that .map.name and .pseudo.name
    references can be used for mapping.
    
    @example
            list1 = new List
            list1.push {id: 1, x: 'aaa'}, {id: 2, x: 'baa'}, {id: 3, x: 'ccc'}
    
            list2 = new List
            list2.push {id2: 1, x: 'a'}, {id2: 22, x: 'b'}
    
            filter_fn = (record) -> # filter to .x properties that have char 'a'
              String(record.x).indexOf('a') > -1
    
            sublist = new ListMask {one: list1, two: list2}, filter_fn
            console.log sublist # [{id: 1, x: 'aaa'}, {id: 2, x: 'baa'},
                                 *  {id2: 1, x: 'a'}]
    
            list.map.one[1].x = 'xxx' # removes item form sublist as it does not
                                       * meet the filter_fn requirement any more
    
            console.log sublist # [{id: 2, x: 'baa'}, {id2: 1, x: 'a'}]
    
    A splitter function may also be added to trigger split records appearing in
    the list mask (but not on .map or .pseudo where the original record would
    appear only). Split records are masks of records that have the same
    attributes as the original record, except:
    - The override attributes from the filter_fn will be added as read-only
    - The original attributes appear as getter/setter pass-thorugh to the
    original record
    - A reference added to the original record: ._original
    
    @example
            list = new List
            list.push {id: 1, start: 30, end: 50}, {id: 2, start: 7, end: 8},
                      {id: 3, start: 20, end: 41}
    
            splitter = (record) ->
              step = 10
              if record.end - record.start > step # break it to 10-long units
                fakes = for i in [record.start ... record.end] by step
                  {start: i, end: Math.min record.end, i + step}
                return fakes
              false
    
            sublist = new ListMask list, {splitter}
            console.log sublist
             * [{id: 1, start: 30, end: 40}, {id: 1, start: 40, end: 50},
             *  {id: 2, start: 7, end: 8}, {id: 3, start: 20, end: 30},
             *  {id: 3, start: 30, end: 40}, {id: 3, start: 40, end: 41}]
    
    @author Greg Varsanyi
     */
    return ListMask = (function() {

      /*
      @property [ListMapper] helper object that handles references to records
        by their unique IDs (._id) or pseudo IDs (._pseudo)
       */
      ListMask.prototype._mapper = null;

      ListMask.prototype.events = null;


      /*
      @property [function] function with signiture `(record) ->` and boolean
        return value indicating if record should be in the filtered list
       */

      ListMask.prototype.filter = null;

      ListMask.prototype.map = null;

      ListMask.prototype.options = null;

      ListMask.prototype.pseudo = null;

      ListMask.prototype.sorter = null;

      ListMask.prototype.source = null;


      /*
      @property [function] function with signiture `(record) ->` that returns
        an Array of overrides to split records or anything else to indicate no
        splitting of record
       */

      ListMask.prototype.splitter = null;


      /*
      Creates a vanilla Array instance (e.g. []), disables methods like
      pop/shift/push/unshift since thes are supposed to be used on the source
      (aka parent) list only
      
      @note If a single {List} or {ListMask} source/parent is provided as first
        argument, .map and .pseudo references will work just like in {List}. If
        object with key-value pairs provided (values being sources/parents),
        records get mapped like .map.keyname[id] and .pseudo.keyname[pseudo_id]
      
      @overload constructor(source, options, scope)
        @param [List/Object] source reference(s) to parent {List}(s)
        @param [Object] options (optional) configuration
        @param [ControllerScope] scope (optional) auto-unsubscribe on $scope
          '$destroy' event
      @overload constructor(source, filter, options, scope)
        @param [List/Object] source reference(s) to parent {List}(s)
        @param [function] filter function with signiture `(record) ->` and
          boolean return value indicating if record should appear in the list
        @param [Object] options (optional) configuration
        @param [ControllerScope] scope (optional) auto-unsubscribe on $scope
          '$destroy' event
      
      @return [Array] returns plain [] with processed contents
       */

      function ListMask(source, filter, options, scope) {
        var flat_sources, key, list, record, source_count, source_info, source_list, source_name, sources, unsubscriber, value, _fn, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2, _ref3;
        if (source instanceof Array || typeof source !== 'object') {
          source = {
            _: source
          };
        }
        source_count = 0;
        for (source_name in source) {
          source_list = source[source_name];
          if (!(source_list instanceof Array && source_list.options && source_list.events instanceof EventEmitter)) {
            argument_type_error({
              source: source_list,
              name: source_name,
              required: 'List'
            });
          }
          source_count += 1;
          define_value(source, source_name, source_list, 0, 1);
        }
        Object.freeze(source);
        if (source._) {
          if (source_count > 1) {
            argument_type_error({
              source: source,
              conflict: 'Can not have unnamed ("_") and named sources mixed'
            });
          }
        }
        if (is_object(filter)) {
          scope = options;
          options = filter;
          filter = null;
        }
        if (options == null) {
          options = {};
        }
        if (!is_object(options)) {
          argument_type_error({
            options: options,
            argument: 3,
            required: 'object'
          });
        }
        if ($rootScope.isPrototypeOf(options)) {
          scope = options;
          options = {};
        }
        if (scope != null) {
          if (!$rootScope.isPrototypeOf(scope)) {
            argument_type_error({
              scope: scope,
              required: '$rootScope descendant'
            });
          }
        }
        if (filter) {
          options.filter = filter;
        }
        list = [];
        _ref = this.constructor.prototype;
        for (key in _ref) {
          value = _ref[key];
          define_value(list, key, value, 0, 1);
        }
        _ref1 = ['copyWithin', 'fill', 'pop', 'push', 'reverse', 'shift', 'sort', 'splice', 'unshift'];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          key = _ref1[_i];
          if (list[key]) {
            define_value(list, key, void 0);
          }
        }
        define_value(list, 'events', new EventEmitter, 0, 1);
        define_value(list, 'options', options);
        define_value(list, 'source', source, 0, 1);
        register_filter(list);
        register_splitter(list);
        ListMapper.register(list);
        sources = list._mapper._sources;
        if (scope) {
          define_value(list, SCOPE_UNSUBSCRIBER, scope.$on('$destroy', function() {
            delete list[SCOPE_UNSUBSCRIBER];
            return list.destroy();
          }));
        }
        unsubscriber = null;
        flat_sources = [];
        _fn = function(source_info) {
          var unsub;
          unsub = source_info.source.events.on('update', function(info) {
            return ListMask.update.call(list, info, source_info.names);
          });
          if (unsubscriber) {
            unsubscriber.add(unsub);
          } else {
            unsubscriber = unsub;
          }
          return unsubscriber.add(source_info.source.events.on('destroy', function() {
            return list.destroy();
          }));
        };
        for (_j = 0, _len1 = sources.length; _j < _len1; _j++) {
          source_info = sources[_j];
          if (_ref2 = source_info.source, __indexOf.call(flat_sources, _ref2) >= 0) {
            error.Value({
              sources: sources,
              conflict: 'Source can not be referenced twice to keep list unique'
            });
          }
          flat_sources.push(source_info.source);
          _fn(source_info);
        }
        define_value(list, '_sourceUnsubscriber', unsubscriber);
        ListSorter.register(list, options.sorter);
        for (_k = 0, _len2 = sources.length; _k < _len2; _k++) {
          source_info = sources[_k];
          _ref3 = source_info.source;
          for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
            record = _ref3[_l];
            if (list.filter(record)) {
              list._mapper.add(record, source_info.names);
              add_to_list(list, record);
            }
          }
        }
        return list;
      }


      /*
      Unsubscribes from list, destroy all properties and freeze
      See: {List#destroy}
      
      @event 'destroy' sends out message pre-destruction
      
      @return [boolean] false if the object was already destroyed
       */

      ListMask.prototype.destroy = List.prototype.destroy;


      /*
      Re-do filtering. Useful when external condtions change for the filter
      
      @return [Object] Actions desctription (or empty {} if nothing changed)
       */

      ListMask.prototype.update = function() {
        var action, is_on, list, mapper, record, source_info, source_names, _i, _j, _len, _len1, _ref, _ref1;
        action = {};
        list = this;
        mapper = list._mapper;
        _ref = mapper._sources;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          source_info = _ref[_i];
          source_names = source_info.names;
          _ref1 = source_info.source;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            record = _ref1[_j];
            is_on = mapper.has(record, null, source_names);
            if (list.filter(record)) {
              if (!is_on) {
                mapper.add(record, source_names);
                add_to_list(list, record);
                (action.add != null ? action.add : action.add = []).push(record);
              }
            } else if (is_on) {
              mapper.del(record, null, source_names);
              (action.cut != null ? action.cut : action.cut = []).push(record);
            }
          }
        }
        if (action.cut) {
          cut_from_list(list, action.cut);
        }
        rebuild_list(list);
        if (action.add || action.cut) {
          list.events.emit('update', {
            node: list,
            action: action
          });
        }
        return action;
      };


      /*
      Helper function that handles all kinds of event mutations coming from the
      parent (source) {List}
      
      Action types: 'add', 'cut', 'update'
      Targets and sources may or may not be or had been on filtered list,
      so this function may or may not transform (or drop) the event before it
      emits to its own listeners.
      
      @param [Object] info Event information object
      @param [string] source_names name of the source list ('_' for unnamed)
      
      @event 'update' See {List#_recordChange}, {List#add} and {List#remove} for
        possible event emission object descriptions
      
      @return [undefined]
       */

      ListMask.update = function(info, source_names) {
        var action, add_action, cut, cutter, delete_if_on, find_and_add, from, incoming, key, list, mapper, merge, move, record, remapper, source, source_found, target_found, to, update_info, value, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _ref3, _ref4;
        action = null;
        cut = [];
        list = this;
        incoming = info.action;
        mapper = list._mapper;
        add_action = function(name, info) {
          var _base;
          return ((_base = (action != null ? action : action = {}))[name] != null ? _base[name] : _base[name] = []).push(info);
        };
        cutter = function(map_id, pseudo_id, record) {
          if (mapper.has(map_id, pseudo_id, source_names)) {
            add_action('cut', record);
            cut.push(record);
            return mapper.del(map_id, pseudo_id, source_names);
          }
        };
        find_and_add = function(map_id, pseudo_id, record) {
          var is_on;
          if (!(is_on = mapper.has(map_id, pseudo_id, source_names))) {
            mapper.add(record, source_names);
          }
          return is_on;
        };
        delete_if_on = function(map_id, pseudo_id) {
          var is_on;
          if (is_on = mapper.has(map_id, pseudo_id, source_names)) {
            mapper.del(map_id, pseudo_id, source_names);
          }
          return is_on;
        };
        if (incoming.cut) {
          _ref = incoming.cut;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            record = _ref[_i];
            cutter(record._id, record._pseudo, record);
          }
        }
        if (incoming.add) {
          _ref1 = incoming.add;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            record = _ref1[_j];
            if (!(list.filter(record))) {
              continue;
            }
            find_and_add(record._id, record._pseudo, record);
            add_to_list(list, record);
            add_action('add', record);
          }
        }
        if (incoming.update) {
          _ref2 = incoming.update;
          for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
            info = _ref2[_k];
            _ref3 = info, record = _ref3.record, info = _ref3.info, merge = _ref3.merge, move = _ref3.move, source = _ref3.source;
            from = to = null;
            if (remapper = merge || move) {
              from = remapper.from, to = remapper.to;
            }
            if (list.filter(record)) {
              source_found = from && delete_if_on(from.map, from.pseudo);
              if (to) {
                target_found = find_and_add(to.map, to.pseudo, record);
              } else {
                target_found = find_and_add(record._id, record._pseudo, record);
              }
              if (source_found && target_found) {
                add_action('update', {
                  record: record,
                  info: info,
                  merge: remapper,
                  source: source
                });
                cut.push(source);
              } else if (source_found) {
                add_action('update', {
                  record: record,
                  info: info,
                  move: remapper
                });
              } else if (target_found) {
                update_info = {
                  record: record
                };
                _ref4 = {
                  info: info,
                  source: source
                };
                for (key in _ref4) {
                  value = _ref4[key];
                  if (value != null) {
                    update_info[key] = value;
                  }
                }
                add_action('update', update_info);
              } else {
                add_to_list(list, record);
                add_action('add', record);
              }
            } else {
              if (merge) {
                cutter(from.map, from.pseudo, source);
                cutter(to.map, to.pseudo, record);
              } else if (move) {
                cutter(from.map, from.pseudo, record);
              } else {
                cutter(record._id, record._pseudo, record);
              }
            }
          }
        }
        if (!list.sorter) {
          rebuild_list(list);
        } else if (cut.length) {
          cut_from_list(list, cut);
        }
        if (action) {
          list.events.emit('update', {
            node: list,
            action: action
          });
        }
      };

      return ListMask;

    })();
  }
]);
ksc.factory('ksc.ListSorter', [
  'ksc.error', 'ksc.util', function(error, util) {
    var ListSorter, define_value, is_key_conform;
    define_value = util.defineValue;
    is_key_conform = util.isKeyConform;

    /*
    Class definition for auto-sort definition at {List#sorter}
    
    @example
         * must return a numeric value, preferrably -1, 0 or 1
        my_sorter_fn = (a, b) -> # sort by id
          if a._id >= b._id then 1 else -1
    
        list = new list
        list.sorter = my_sorter_fn
    
         * you may also pass it as part of the options argument, the result
         * will be moved to list.sorter though
        list = new list
          sorter: my_sorter_fn
    
    @example
         * strings or arrays will be turned into sorter description objects
        list = new list
        list.sorter = 'name'
         * will be turned into:
         * list.sorter = # [ListSorter]
         *   key:     'name'
         *   reverse: false # A -> Z
         *   type:    'natural'
    
    @example
        list = new list
        list.sorter =
          key:     ['lastName', 'firstName']
          reverse: true # Z -> A
          type:    'natural' # other possible values: 'number', 'byte'
    
    @author Greg Varsanyi
     */
    return ListSorter = (function() {
      ListSorter.prototype.fn = null;

      ListSorter.prototype.key = null;

      ListSorter.prototype.list = null;

      ListSorter.prototype.reverse = null;


      /*
      @property [string] sorting type, possible values
        - 'byte': compare based on ASCII/UTF8 character value (stringifies vals)
        - 'natural': human-perceived "natural" order, case-insensitive (default)
        - 'number': number-ordering, falls back to natural for non-numbers
        (null if external function is used)
       */

      ListSorter.prototype.type = null;


      /*
      Creates ListSorter object
      
      @param [List] list reference to Array created by {List}
      @param [string|Array|object|function] description external sort function
        or sort logic description
      @option sorter [string|Array] key key or keys used for sorting
      @option sorter [boolean] reverse sorting order (defaults to false)
      @option sorter [string] type sort method: 'natural', 'number', 'byte' -
        see: {ListSorter#type}
      
      @throw [ValueError] if a sorter value is errorous
       */

      function ListSorter(list, description) {
        var key, sorter, type;
        sorter = this;
        define_value(sorter, 'list', list, 0, 0);
        if (typeof description === 'function') {
          sorter.fn = description;
        } else {
          if (is_key_conform(description) || description instanceof Array) {
            description = {
              key: description
            };
          }
          if (!(util.isObject(description) && (is_key_conform(key = description.key) || key instanceof Array))) {
            error.Value({
              sorter: description,
              requirement: 'function or string or array or object: ' + '{key: <string|array>, reverse: <bool>, type: ' + '\'natural|number|byte\'}'
            });
          }
          if (type = description.type) {
            if (type !== 'byte' && type !== 'natural' && type !== 'number') {
              error.Value({
                type: type,
                required: 'byte, natural or number'
              });
            }
          } else {
            type = 'natural';
          }
          define_value(sorter, 'key', key, 0, 1);
          define_value(sorter, 'reverse', !!description.reverse, 0, 1);
          define_value(sorter, 'type', type, 0, 1);
          define_value(sorter, 'fn', ListSorter.getSortFn(sorter), 0, 1);
        }
        Object.preventExtensions(sorter);
      }


      /*
      Find a new Record's position in a sorted list
      
      @param [Record] record Instance of record that needs a position
      
      @throw [TypeError] If the sorter function returns a non-numeric value
      
      @return [number] position
       */

      ListSorter.prototype.position = function(record) {
        var cmp_check, compare, find_in, len, list, max, min, sorter;
        sorter = this;
        compare = sorter.fn;
        list = sorter.list;
        if (!(len = list.length)) {
          return 0;
        }
        min = 0;
        max = len - 1;
        cmp_check = function(value) {
          if (typeof value !== 'number' || isNaN(value)) {
            error.Type({
              sort_fn_output: value,
              required: 'number'
            });
          }
          return value;
        };
        if (cmp_check(compare(record, list[min])) < 0) {
          return min;
        }
        if (len === 1) {
          return 1;
        }
        if (cmp_check(compare(record, list[max])) >= 0) {
          return max + 1;
        }
        find_in = function(min, max) {
          var mid;
          if (min < max - 1) {
            mid = Math.floor((max - min) / 2 + min);
            if (cmp_check(compare(record, list[mid])) < 0) {
              return find_in(min, mid);
            }
            return find_in(mid, max);
          }
          return max;
        };
        return find_in(min, max);
      };


      /*
      Helper method that generates a sorter/comparison function
      
      Type 'number' sorts fall back to natural sort on anything that is either
      - (not typeof 'number' or 'string') or
      - typeof 'string' but is empty or Number(anything) returns NaN
      
      Natural sort will produce the same result on numbers as 'number' sort, but
      'number' on numbers is faster.
      
      @param [ListSorter] sorter ListSorter instance to get sorter function for
      
      @return [function] sorter/comparison function with signiture `(a, b) ->`
       */

      ListSorter.getSortFn = function(sorter) {
        var joint, key, natural_cmp, numerify, reverse, type;
        key = sorter.key, reverse = sorter.reverse, type = sorter.type;
        reverse = reverse ? -1 : 1;
        joint = function(obj, parts) {
          var part;
          return ((function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = parts.length; _i < _len; _i++) {
              part = parts[_i];
              if (obj[part] != null) {
                _results.push(obj[part]);
              }
            }
            return _results;
          })()).join(' ');
        };
        numerify = function(n) {
          if (typeof n !== 'number') {
            if (typeof n === 'string' && n !== '') {
              return Number(n);
            } else {
              return NaN;
            }
          }
          return n;
        };
        natural_cmp = function(as, bs) {
          var L, a, a1, b, b1, i, n, rx;
          as = String(as).toLowerCase();
          bs = String(bs).toLowerCase();
          i = 0;
          rx = /(\.\d+)|(\d+(\.\d+)?)|([^\d.]+)|(\.\D+)|(\.$)/g;
          if (as === bs) {
            return 0;
          }
          a = as.toLowerCase().match(rx);
          b = bs.toLowerCase().match(rx);
          L = a != null ? a.length : 0;
          while (i < L) {
            if ((b == null) || b[i] === void 0) {
              return 1;
            }
            a1 = a[i];
            b1 = b[i];
            i += 1;
            n = a1 - b1;
            if (!isNaN(n)) {
              return n;
            }
            if (a1 >= b1) {
              return 1;
            } else {
              return -1;
            }
          }
          return -1;
        };
        return function(a, b) {
          var _a, _b;
          if (is_key_conform(key)) {
            a = a[key];
            b = b[key];
          } else {
            a = joint(a, key);
            b = joint(b, key);
          }
          if (type === 'number') {
            _a = a;
            _b = b;
            a = numerify(a);
            b = numerify(b);
            if (isNaN(a)) {
              if (isNaN(b)) {
                return natural_cmp(_a, _b) * reverse;
              }
              return -1 * reverse;
            }
            if (isNaN(b)) {
              return 1 * reverse;
            }
          } else {
            if (a == null) {
              a = '';
            }
            if (b == null) {
              b = '';
            }
          }
          if (type === 'natural') {
            return natural_cmp(a, b) * reverse;
          } else if (type === 'byte') {
            a = String(a);
            b = String(b);
          }
          if (a === b) {
            return 0;
          }
          return (a > b ? 1 : -1) * reverse;
        };
      };


      /*
      Helper method that registers a sorter getter/setter on an Array created
      by {List} or {ListMask}
      
      @param [List] list reference to the list (not) to be auto-sorted
      @param [null|function|object|string|Array] description sort logic
        description, see: {ListSorter} and {ListSorter#constructor}
      
      @return [undefined]
       */

      ListSorter.register = function(list, description) {
        var getter, setter, sorter;
        sorter = null;
        if (description) {
          sorter = new ListSorter(list, description);
        }
        getter = function() {
          return sorter;
        };
        setter = function(description) {
          if (description) {
            sorter = new ListSorter(list, description);
            Array.prototype.sort.call(list, sorter.fn);
            return list.events.emit('update', {
              node: list,
              action: {
                sort: true
              }
            });
          } else {
            return sorter = null;
          }
        };
        util.defineGetSet(list, 'sorter', getter, setter, 1);
        util.defineGetSet(list.options, 'sorter', getter, setter, 1);
      };

      return ListSorter;

    })();
  }
]);

ksc.factory('ksc.List', [
  '$rootScope', 'ksc.EditableRecord', 'ksc.EventEmitter', 'ksc.ListMapper', 'ksc.ListSorter', 'ksc.Record', 'ksc.error', 'ksc.util', function($rootScope, EditableRecord, EventEmitter, ListMapper, ListSorter, Record, error, util) {
    var List, SCOPE_UNSUBSCRIBER, argument_type_error, define_value, emit_action, inject, is_object, normalize_return_action;
    SCOPE_UNSUBSCRIBER = '_scopeUnsubscriber';
    argument_type_error = error.ArgumentType;
    define_value = util.defineValue;
    is_object = util.isObject;
    normalize_return_action = function(items, return_action) {
      if (typeof return_action !== 'boolean') {
        items.push(return_action);
        return_action = false;
      }
      return return_action;
    };
    emit_action = function(list, action) {
      return list.events.emit('update', {
        node: list,
        action: action
      });
    };

    /*
    A helper function, similar to Array::splice, except it does not delete.
    This is a central place for injecting into the array, a candidate for
    turning elements into getters/setters if we ever go there.
    
    @param [Object] list Array with extensions from {List}
    @param [number] pos Index in array where injection starts
    @param [Record] records... Element(s) to be injected
    
    @return [undefined]
     */
    inject = function(list, pos, records) {
      var _ref;
      (_ref = Array.prototype.splice).call.apply(_ref, [list, pos, 0].concat(__slice.call(records)));
    };

    /*
    Constructor for an Array instance and methods to be added to that instance
    
    Only contains objects. Methods push() and unshift() take vanilla objects
    too, but turn them into ksc.Record instances.
    
    @note This record contains a unique list of records. Methods push() and
    unshift() are turned into "upsert" loaders: if the record is already in
    the list it will update the already existing one instead of being added to
    the list
    
    Maintains a key-value map of record._id's in the .map={id: Record} property
    
    @example
      list = new List
        record:
          class: Record
          idProperty: 'id'
    
      list.push {id: 1, x: 2}
      list.push {id: 2, x: 3}
      list.push {id: 2, x: 4}
      console.log list # [{id: 1, x: 2}, {id: 2, x: 4}]
      console.log list.map[2] # {id: 2, x: 4}
    
    @note Do not forget to manage the lifecycle of lists to prevent memory leaks
    @example
             * You may tie the lifecycle easily to a controller $scope by
             * just passing it to the constructor as last argument (arg #1 or #2)
            list = new List {someOption: 1}, $scope
    
             * you can destroy it at any time though:
            list.destroy()
    
    Options that may be used:
    - .options.record.class (class reference for record objects)
    - .options.record.idProperty (property/properties that define record ID)
    
    @author Greg Varsanyi
     */
    return List = (function() {

      /*
      @property [ListMapper] helper object that handles references to records
        by their unique IDs (._id) or pseudo IDs (._pseudo)
       */
      List.prototype._mapper = null;

      List.prototype.events = null;

      List.prototype.map = null;

      List.prototype.pseudo = null;

      List.prototype.options = null;

      List.prototype.sorter = null;


      /*
      Creates a vanilla Array instance (e.g. []), adds methods and overrides
      pop/shift/push/unshift logic to support the special features. Will inherit
      standard Array behavior for .length and others.
      
      @param [Object] options (optional) configuration data for this list
      @param [ControllerScope] scope (optional) auto-unsubscribe on $scope
        '$destroy' event
      
      @return [Array] returns plain [] with extra methods and some overrides
       */

      function List(options, scope) {
        var key, list, value, _base, _ref;
        if (options == null) {
          options = {};
        }
        list = [];
        if (!util.isObject(options)) {
          argument_type_error({
            options: options,
            argument: 3,
            required: 'object'
          });
        }
        if ($rootScope.isPrototypeOf(options)) {
          scope = options;
          options = {};
        }
        if (scope != null) {
          if (!$rootScope.isPrototypeOf(scope)) {
            argument_type_error({
              scope: scope,
              required: '$rootScope descendant'
            });
          }
        }
        _ref = this.constructor.prototype;
        for (key in _ref) {
          value = _ref[key];
          if (key.indexOf('constructor') === -1) {
            define_value(list, key, value, 0, 1);
          }
        }
        options = angular.copy(options);
        define_value(list, 'options', options);
        if ((_base = list.options).record == null) {
          _base.record = {};
        }
        define_value(list, 'events', new EventEmitter, 0, 1);
        ListMapper.register(list);
        if (scope) {
          define_value(list, SCOPE_UNSUBSCRIBER, scope.$on('$destroy', function() {
            delete list[SCOPE_UNSUBSCRIBER];
            return list.destroy();
          }));
        }
        ListSorter.register(list, options.sorter);
        return list;
      }


      /*
      Unsubscribes from list, destroy all properties and freeze
      
      @event 'destroy' sends out message pre-destruction
      
      @return [boolean] false if the object was already destroyed
       */

      List.prototype.destroy = function() {
        var key, list;
        list = this;
        if (Object.isFrozen(list)) {
          return false;
        }
        list.events.emit('destroy');
        if (typeof list[SCOPE_UNSUBSCRIBER] === "function") {
          list[SCOPE_UNSUBSCRIBER]();
        }
        if (typeof list._sourceUnsubscriber === "function") {
          list._sourceUnsubscriber();
        }
        util.empty(list);
        for (key in list) {
          if (key !== 'destroy') {
            delete list[key];
          }
        }
        delete list.options;
        delete list._sourceUnsubscriber;
        Object.freeze(list);
        return true;
      };


      /*
      Cut 1 or more records from the list
      
      Option used:
      - .options.record.idProperty (property/properties that define record ID)
      
      @param [Record] records... Record(s) or record ID(s) to be removed
      
      @throw [KeyError] element can not be found
      @throw [MissingArgumentError] record reference argument not provided
      
      @event 'update' sends out message if list changes
              events.emit 'update', {node: list, action: {cut: [records...]}}
      
      @return [Object] returns list of affected records: {cut: [records...]}
       */

      List.prototype.cut = function() {
        var action, cut, id, item, list, mapper, record, records, removable, tmp_container, _i, _len;
        records = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (!records.length) {
          error.MissingArgument({
            name: 'record',
            argument: 1
          });
        }
        cut = [];
        list = this;
        mapper = list._mapper;
        removable = [];
        for (_i = 0, _len = records.length; _i < _len; _i++) {
          record = records[_i];
          if (is_object(record)) {
            if (__indexOf.call(list, record) < 0) {
              error.Value({
                record: record,
                description: 'not found in list'
              });
            }
            if (!mapper.has(record)) {
              error.Key({
                record: record,
                description: 'map/pseudo id error'
              });
            }
            mapper.del(record);
            cut.push(record);
          } else {
            id = record;
            if (!(record = mapper.has(id))) {
              error.Key({
                id: id,
                description: 'map id error'
              });
            }
            mapper.del(id);
            if (record._id !== id) {
              cut.push(id);
            } else {
              cut.push(record);
            }
          }
          removable.push(record);
        }
        tmp_container = [];
        while (item = Array.prototype.pop.call(list)) {
          if (__indexOf.call(removable, item) < 0) {
            tmp_container.push(item);
          }
        }
        if (tmp_container.length) {
          tmp_container.reverse();
          inject(list, list.length, tmp_container);
        }
        action = {
          cut: cut
        };
        emit_action(list, action);
        return action;
      };


      /*
      Empty list
      
      Option used:
      - .options.record.idProperty (property/properties that define record ID)
      
      @event 'update' sends out message if list changes (see: {List#cut})
      
      @return [Array] returns the list array (chainable) or action description
       */

      List.prototype.empty = function(return_action) {
        var action, i, list, _i, _ref;
        list = this;
        action = {
          cut: []
        };
        list.events.halt();
        try {
          for (i = _i = 0, _ref = list.length; _i < _ref; i = _i += 1) {
            action.cut.push(list.shift());
          }
        } finally {
          list.events.unhalt();
        }
        if (action.cut.length) {
          emit_action(list, action);
        }
        if (return_action) {
          return action;
        }
        return this;
      };


      /*
      Remove the last element
      
      Option used:
      - .options.record.idProperty (property/properties that define record ID)
      
      @event 'update' sends out message if list changes (see: {List#cut})
      
      @return [Record] The removed element
       */

      List.prototype.pop = function() {
        return List.remove(this, 'pop');
      };


      /*
      Upsert 1 or more records - adds to the end of the list if unsorted.
      
      Upsert means update or insert. Updates if a record is found in the list
      with identical ._id property. Inserts otherwise.
      
      If list is auto-sorted, new elements will be added to their appropriate
      sorted position (i.e. not necessarily to the last position), see:
      {ListSorter} and {ListSorter#position}
      
      Options used:
      - .options.record.idProperty (property/properties that define record ID)
      
      @throw [TypeError] non-object element pushed
      @throw [MissingArgumentError] no items were pushed
      
      @event 'update' sends out message if list changes:
              events.emit 'update', {node: list, action: {add: [records...],
              update: [{record: record}, ...]}}
      
      @overload push(items...)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)
      
        @return [number] New length of list
      
      @overload push(items..., return_action)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)
        @param [boolean] return_action Request to return an object with
        references to the affected records:
        {add: [records...], update: [records...]}
      
        @return [Object] Affected records
       */

      List.prototype.push = function() {
        var action, items, list, return_action, _i;
        items = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), return_action = arguments[_i++];
        return_action = normalize_return_action(items, return_action);
        list = this;
        action = List.add(list, items, list.length);
        if (return_action) {
          return action;
        }
        return list.length;
      };


      /*
      Remove the first element
      
      Option used:
      - .options.record.idProperty (property/properties that define record ID)
      
      @event 'update' sends out message if list changes (see: {List#cut})
      
      @return [Record] The removed element
       */

      List.prototype.shift = function() {
        return List.remove(this, 'shift');
      };


      /*
      Upsert 1 or more records - adds to the beginning of the list if unsorted.
      
      Upsert means update or insert. Updates if a record is found in the list
      with identical ._id property. Inserts otherwise.
      
      If list is auto-sorted, new elements will be added to their appropriate
      sorted position (i.e. not necessarily to the first position), see:
      {ListSorter} and {ListSorter#position}
      
      Options used:
      - .options.record.idProperty (property/properties that define record ID)
      
      @throw [TypeError] non-object element pushed
      @throw [MissingArgumentError] no items were pushed
      
      @event 'update' sends out message if list changes:
              events.emit 'update', {node: list, action: {add: [records...],
              update: [{record: record}, ...]}}
      
      @overload unshift(items...)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)
      
        @return [number] New length of list
      
      @overload unshift(items..., return_action)
        @param [Object] items... Record or vanilla object that will be turned
        into a Record (based on .options.record.class)
        @param [boolean] return_action Request to return an object with
        references to the affected records:
        {add: [records...], update: [records...]}
      
        @return [Object] Affected records
       */

      List.prototype.unshift = function() {
        var action, items, list, return_action, _i;
        items = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), return_action = arguments[_i++];
        return_action = normalize_return_action(items, return_action);
        list = this;
        action = List.add(list, items, 0);
        if (return_action) {
          return action;
        }
        return list.length;
      };


      /*
      Cut and/or upsert 1 or more records. Inserts to position if unsorted.
      
      Upsert means update or insert. Updates if a record is found in the list
      with identical ._id property. Inserts otherwise.
      
      If list is auto-sorted, new elements will be added to their appropriate
      sorted position (i.e. not necessarily to the first position), see:
      {ListSorter} and {ListSorter#position}
      
      Options used:
      - .options.record.idProperty (property/properties that define record ID)
      
      @throw [ArgumentTypeError] pos or count does not meet requirements
      @throw [TypeError] non-object element pushed
      
      @event 'update' sends out message if list changes:
              events.emit 'update', {node: list, action: {cut: [records...],
              add: [records...], update: [{record: record}, ...]}}
      
      @overload unshift(items...)
        @param [number] pos Index of cut/insert start
        @param [number] count Number of elements to cut
        @param [Object] items... Record or vanilla object that will be turned
          into a Record (based on .options.record.class)
      
        @return [Array] removed elements
      
      @overload unshift(items..., return_action)
        @param [Object] items... Record or vanilla object that will be turned
          into a Record (based on .options.record.class)
        @param [boolean] return_action Request to return an object with
          references to the affected records: {cut: [records..],
          add: [records...], update: [records...]}
      
        @return [Object] Actions taken (see event description: action)
       */

      List.prototype.splice = function() {
        var action, count, items, len, list, pos, positive_int_or_zero, return_action, _i;
        pos = arguments[0], count = arguments[1], items = 4 <= arguments.length ? __slice.call(arguments, 2, _i = arguments.length - 1) : (_i = 2, []), return_action = arguments[_i++];
        return_action = normalize_return_action(items, return_action);
        if (typeof items[0] === 'undefined' && items.length === 1) {
          items.pop();
        }
        if (typeof count === 'boolean' && !items.length) {
          return_action = count;
          count = null;
        }
        positive_int_or_zero = function(value, i) {
          if (!(typeof value === 'number' && (value > 0 || value === 0) && value === Math.floor(value))) {
            return argument_type_error({
              value: value,
              argument: i,
              required: 'int >= 0'
            });
          }
        };
        action = {};
        list = this;
        len = list.length;
        if (pos < 0) {
          pos = Math.max(len + pos, 0);
        }
        positive_int_or_zero(pos);
        pos = Math.min(len, pos);
        if (count != null) {
          positive_int_or_zero(count);
          count = Math.min(len - pos, count);
        } else {
          count = len - pos;
        }
        list.events.halt();
        try {
          if (count > 0) {
            action = list.cut.apply(list, list.slice(pos, pos + count));
          }
          if (items.length) {
            util.mergeIn(action, List.add(list, items, pos));
          }
        } finally {
          list.events.unhalt();
        }
        if (action.cut || action.add || action.update) {
          emit_action(list, action);
        }
        if (return_action) {
          return action;
        }
        return action.cut || [];
      };


      /*
      Wraps Array::reverse
      
      Throws error if list is auto-sorted (.sorter is set, see {List#sorter})
      
      @event 'update' emits event if order changed, i.e. if there is >1
        elements on the list:
            events.emit 'update', {node: list, action: {reverse: true}}
      
      @throw [PermissionError] can not reverse an auto-sorted list
      
      @return [Array] Array instance generated by List
       */

      List.prototype.reverse = function() {
        var list;
        list = this;
        if (list.sorter) {
          error.Permission('can not reverse an auto-sorted list');
        }
        if (list.length > 1) {
          Array.prototype.reverse.call(list);
          emit_action(list, {
            reverse: true
          });
        }
        return list;
      };


      /*
      Wraps Array::sort
      
      Throws error if list is auto-sorted (.sorter is set, see {List#sorter})
      
      @param [function] sorter_fn (optional) sort logic function. If not
        provided, records will be sorted based on ._id and ._pseudo
      
      @event 'update' emits event if order actually changed:
            events.emit 'update', {node: list, action: {reverse: true}}
      
      @throw [PermissionError] can not reverse an auto-sorted list
      
      @return [Array] Array instance generated by List
       */

      List.prototype.sort = function(sorter_fn) {
        var cmp, i, list, record, _i, _len;
        list = this;
        if (list.sorter) {
          error.Permission('can not reverse an auto-sorted list');
        }
        if (list.length > 1) {
          cmp = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = list.length; _i < _len; _i++) {
              record = list[_i];
              _results.push(record);
            }
            return _results;
          })();
          if (sorter_fn == null) {
            sorter_fn = function(a, b) {
              if (a._id === null && b._id === null) {
                return a._pseudo - b._pseudo;
              }
              if (a._id === null) {
                return -1;
              }
              if (b._id === null) {
                return 1;
              }
              if (a._id > b._id) {
                return 1;
              }
              return -1;
            };
          }
          Array.prototype.sort.call(list, sorter_fn);
          for (i = _i = 0, _len = list.length; _i < _len; i = ++_i) {
            record = list[i];
            if (!(record !== cmp[i])) {
              continue;
            }
            emit_action(list, {
              sort: true
            });
            break;
          }
        }
        return list;
      };


      /*
      Catches change event from records belonging to the list
      
      Moves or merges records in the map if record._id changed
      
      @param [object] record reference to the changed record
      @param [object] info record change event hashmap
      @option info [object] node reference to the changed record or subrecord
      @option info [object] parent (optional) appears if subrecord changed,
        references the top-level record node
      @option info [Array] path (optional) appears if subrecord changed,
        provides key literals from the top-level record to changed node
      @option info [string] action type of event: 'set', 'delete', 'revert' or
        'replace'
      @option info [string|number] key (optional) changed key (for 'set')
      @option info [Array] keys (optional) changed key(s) (for 'delete')
      @param [string|number] old_id (optional) indicates _id change if provided
      
      @event 'update' sends out message if record changes on list
            events.emit 'update',
              node: list
              action:
                update: [{record, info}]
      
      @event 'update' sends out message if record id changes (no merge)
            events.emit 'update',
              node: list
              action:
                update: [
                  record: record
                  move:   {from: {map|pseudo: id}, to: {map|pseudo: id}}
                  info:   record_update_info # see {EditableRecord} methods
                ]
      
      @event 'update' sends out message if record id changes (merge)
            events.emit 'update',
              node: list
              action:
                merge: [
                  record: record
                  merge:  {from: {map|pseudo: id}, to: {map|pseudo: id}}
                  source: dropped_record_reference
                  info:   record_update_info # see {EditableRecord} methods
                ]
      
      @return [boolean] true if list event is emitted
       */

      List.prototype._recordChange = function(record, record_info, old_id) {
        var add_to_map, info, item, list, map, mapper, new_pos, pos, _i, _len;
        if (!(record instanceof Record)) {
          error.Type({
            record: record,
            required: 'Record'
          });
        }
        list = this;
        map = list.map;
        mapper = list._mapper;
        add_to_map = function() {
          define_value(record, '_pseudo', null);
          return mapper.add(record);
        };
        info = {
          record: record,
          info: record_info
        };
        if (old_id !== record._id) {
          list.events.halt();
          try {
            if (record._id == null) {
              mapper.del(old_id);
              define_value(record, '_pseudo', util.uid('record.pseudo'));
              mapper.add(record);
              info.move = {
                from: {
                  map: old_id
                },
                to: {
                  pseudo: record._pseudo
                }
              };
            } else if (old_id == null) {
              if (map[record._id]) {
                info.merge = {
                  from: {
                    pseudo: record._pseudo
                  },
                  to: {
                    map: record._id
                  }
                };
                info.record = map[record._id];
                info.source = record;
                list.cut(record);
                list.push(record);
              } else {
                info.move = {
                  from: {
                    pseudo: record._pseudo
                  },
                  to: {
                    map: record._id
                  }
                };
                mapper.del(null, record._pseudo);
                add_to_map();
              }
            } else {
              if (map[record._id]) {
                info.merge = {
                  from: {
                    map: old_id
                  },
                  to: {
                    map: record._id
                  }
                };
                info.record = map[record._id];
                info.source = record;
                list.cut(old_id);
                list.push(record);
              } else {
                info.move = {
                  from: {
                    map: old_id
                  },
                  to: {
                    map: record._id
                  }
                };
                mapper.del(old_id);
                add_to_map();
              }
            }
          } finally {
            list.events.unhalt();
          }
        }
        if (list.sorter) {
          record = info.record;
          for (pos = _i = 0, _len = list.length; _i < _len; pos = ++_i) {
            item = list[pos];
            if (!(item === record)) {
              continue;
            }
            Array.prototype.splice.call(list, pos, 1);
            new_pos = list.sorter.position(record);
            inject(list, new_pos, [record]);
            break;
          }
        }
        return emit_action(list, {
          update: [info]
        });
      };


      /*
      Aggregate method for push/unshift
      
      Options used:
      - .options.record.idProperty (property/properties that define record ID)
      
      If list is auto-sorted, new elements will be added to their appropriate
      sorted position (i.e. not necessarily to the first/last position), see:
      {ListSorter} and {ListSorter#position}
      
      @param [Array] list Array generated by {List}
      @param [Array] items Record or vanilla objects to be added
      @param [number] pos position to inject new element to
      
      @throw [TypeError] non-object element pushed
      @throw [MissingArgumentError] no items were pushed
      
      @event 'update' sends out message if list changes:
              events.emit 'update', {node: list, action: {add: [records...],
              update: [{record: record}, ...]}}
      
      @return [Object] action description: {add: [...], update: [...]}
       */

      List.add = function(list, items, pos) {
        var action, existing, item, mapper, original, record_class, record_opts, tmp, _i, _j, _len, _len1;
        if (!items.length) {
          error.MissingArgument({
            name: 'item',
            argument: 1
          });
        }
        action = {};
        mapper = list._mapper;
        list.events.halt();
        try {
          tmp = [];
          record_opts = list.options.record;
          record_class = record_opts["class"] || EditableRecord;
          for (_i = 0, _len = items.length; _i < _len; _i++) {
            item = items[_i];
            original = item;
            if (item instanceof record_class) {
              if (item._parent && item._parent !== list) {
                item._parent.cut(item);
              }
              define_value(item, '_parent', list);
            } else {
              if (item instanceof Record) {
                item = item._clone(true);
              }
              item = new record_class(item, record_opts, list);
            }
            if (item._id != null) {
              if (existing = mapper.has(item._id)) {
                existing._replace(item._clone(true));
                (action.update != null ? action.update : action.update = []).push({
                  record: existing,
                  source: original
                });
              } else {
                mapper.add(item);
                tmp.push(item);
                (action.add != null ? action.add : action.add = []).push(item);
              }
              if (item._pseudo) {
                define_value(item, '_pseudo', null);
              }
            } else {
              define_value(item, '_pseudo', util.uid('record.pseudo'));
              mapper.add(item);
              tmp.push(item);
              (action.add != null ? action.add : action.add = []).push(item);
            }
          }
          if (tmp.length) {
            if (list.sorter) {
              for (_j = 0, _len1 = tmp.length; _j < _len1; _j++) {
                item = tmp[_j];
                pos = list.sorter.position(item);
                inject(list, pos, [item]);
              }
            } else {
              inject(list, pos, tmp);
            }
          }
        } finally {
          list.events.unhalt();
        }
        emit_action(list, action);
        return action;
      };


      /*
      Aggregate method for pop/shift
      
      Option used:
      - .options.record.idProperty (property/properties that define record ID)
      
      @param [Array] list Array generated by {List}
      @param [string] orig_fn 'pop' or 'shift'
      
      @event 'update' sends out message if list changes (see: {List#cut})
      
      @return [Record] Removed record
       */

      List.remove = function(list, orig_fn) {
        var record;
        if (record = Array.prototype[orig_fn].call(list)) {
          list._mapper.del(record);
          emit_action(list, {
            cut: [record]
          });
        }
        return record;
      };

      return List;

    })();
  }
]);

ksc.factory('ksc.Mixin', [
  'ksc.error', 'ksc.util', function(error, util) {
    var Mixin, normalize, validate_key;
    normalize = function(explicit, properties, next) {
      var property, _i, _len;
      if (explicit != null) {
        if (typeof explicit !== 'boolean') {
          properties.unshift(explicit);
          explicit = true;
        }
      }
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        property = properties[_i];
        if (!util.isKeyConform(property)) {
          error.Key({
            property: property,
            required: 'key conform value'
          });
        }
      }
      return next(explicit, properties);
    };
    validate_key = function(extensible, key, explicit, properties) {
      var found;
      if (util.hasProperty(extensible, key)) {
        return false;
      }
      if (explicit == null) {
        return true;
      }
      found = __indexOf.call(properties, key) >= 0;
      return (explicit && found) || (!explicit && !found);
    };

    /*
    Mixin methods
    
    Extend class instance and/or prototype with properties of an other class.
    Will not override existing properties on the extended class.
    Supports explicit inclusion/exclusion.
    
    @example
        class A
          @instProp: 'x'
          protoProp: 'y'
          zProp: 'not z here'
    
        class B
          Mixin.extend B, A
    
          zProp: 'z'
    
        console.log B.instProp is 'x'   # true
        console.log B::protoProp is 'y' # true
        console.log B::zProp is 'z' # true
    
    @author Greg Varsanyi
     */
    return Mixin = (function() {
      function Mixin() {}


      /*
      Extend both class prototype and instance based on source class prototype
      and instance
      
      @param [class] extensible class to be extended
      @param [class] mixin extension source class
      @param [boolean] explicit (optional) true = only copy properties named
        explicitly as follows. false = only copy properties that are not in
        the following list. Defaults to true if property names are provided.
      @param [string] properties explicit list of properties to be included or
        excluded from the mixin class (depending on the previous boolean arg)
      
      @throw [TypeError] a property name in the properties list is not a string
      
      @return [undefined]
       */

      Mixin.extend = function() {
        var explicit, extensible, mixin, properties;
        extensible = arguments[0], mixin = arguments[1], explicit = arguments[2], properties = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
        Mixin.extendProto.apply(Mixin, [extensible, mixin, explicit].concat(__slice.call(properties)));
        return Mixin.extendInstance.apply(Mixin, [extensible, mixin, explicit].concat(__slice.call(properties)));
      };


      /*
      Extend class instance based on source class instance
      
      @param [class] extensible class to be extended
      @param [class] mixin extension source class
      @param [boolean] explicit (optional) true = only copy properties named
        explicitly as follows. false = only copy properties that are not in
        the following list. Defaults to true if property names are provided.
      @param [string] properties explicit list of properties to be included or
        excluded from the mixin class (depending on the previous boolean arg)
      
      @throw [TypeError] a property name in the properties list is not a string
      
      @return [undefined]
       */

      Mixin.extendInstance = function() {
        var explicit, extensible, mixin, properties;
        extensible = arguments[0], mixin = arguments[1], explicit = arguments[2], properties = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
        return normalize(explicit, properties, function(explicit, properties) {
          var key, property;
          for (key in mixin) {
            property = mixin[key];
            if (validate_key(extensible, key, explicit, properties)) {
              extensible[key] = property;
            }
          }
        });
      };


      /*
      Extend class prototype based on source class prototype
      
      @param [class] extensible class to be extended
      @param [class] mixin extension source class
      @param [boolean] explicit (optional) true = only copy properties named
        explicitly as follows. false = only copy properties that are not in
        the following list. Defaults to true if property names are provided.
      @param [string] properties explicit list of properties to be included or
        excluded from the mixin class (depending on the previous boolean arg)
      
      @throw [TypeError] a property name in the properties list is not a string
      
      @return [undefined]
       */

      Mixin.extendProto = function() {
        var explicit, extensible, mixin, properties;
        extensible = arguments[0], mixin = arguments[1], explicit = arguments[2], properties = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
        return Mixin.extendInstance.apply(Mixin, [extensible.prototype, mixin.prototype, explicit].concat(__slice.call(properties)));
      };

      return Mixin;

    })();
  }
]);

ksc.factory('ksc.RecordContract', [
  'ksc.error', 'ksc.util', function(error, util) {
    var NULLABLE, RecordContract, has_own, is_object;
    NULLABLE = 'nullable';
    has_own = util.hasOwn;
    is_object = util.isObject;

    /*
    Contract, integrity checkers and matchers for {Record} and descendants
    
    Restricts record properties to the ones specified in the contract.
    
    Requires data types to match
    
    Allows specifing defaults and if the values are nullable
    
    Does not ever allow undefined values on contract nor it will allow nulls on
    non-nullable properties.
    
    Sets default values to properties not specified in construction or data
    replacement time (see: {Record#_replace} and {EditableRecord#_replace})
    
    @example
      record = new Record {c: false},
        contract:
          a: {type: 'number'}
          b: {type: 'string', nullable: true}
          c: {type: 'boolean', default: true}
      console.log record # {a: 0, b: null, c: false}
    
    @author Greg Varsanyi
     */
    return RecordContract = (function() {

      /*
      Construct RecordContract instance off of provided description (or return
      the existing RecordContract instance if that was passed)
      
      Checks integrity of escription
      
      @throw [KeyError] keys can not start with underscore
      @throw [TypeError] type is not supported or mismatches with default value
      @throw [ValueError] subcontracts can not have default values
      
      @param [object] contract description object
       */
      function RecordContract(contract) {
        var arr, desc, desc_key, exclusive_count, key, _i, _len, _ref;
        if (contract === null || contract instanceof RecordContract) {
          return contract;
        }
        if (!is_object(contract)) {
          error.Type({
            contract: contract,
            required: 'object'
          });
        }
        for (key in contract) {
          desc = contract[key];
          if (key.substr(0, 1) === '_') {
            error.Key({
              key: key,
              description: 'can not start with "_"'
            });
          }
          this[key] = desc;
          if (desc[NULLABLE]) {
            desc[NULLABLE] = true;
          } else {
            delete desc[NULLABLE];
          }
          exclusive_count = 0;
          _ref = ['array', 'contract', 'default'];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            desc_key = _ref[_i];
            if (!desc[desc_key]) {
              continue;
            }
            exclusive_count += 1;
            if (exclusive_count > 1) {
              error.Value({
                key: desc_key,
                contract: desc,
                description: 'array, default and contract are mutally exclusive'
              });
            }
          }
          if (!(arr = desc.array) && desc.type === 'array') {
            error.Type({
              array: desc.array,
              description: 'array description object is required'
            });
          }
          if (arr) {
            if (has_own(desc, 'type') && desc.type !== 'array') {
              error.Type({
                type: type,
                array: desc.array,
                requiredType: 'array'
              });
            }
            delete desc.type;
          }
          if (desc.type === 'object' && !is_object(desc.contract)) {
            error.Type({
              contract: desc.contract,
              description: 'contract description object is required'
            });
          }
          if (desc.contract) {
            if (has_own(desc, 'type') && desc.type !== 'object') {
              error.Type({
                type: type,
                contract: desc.contract,
                requiredType: 'object'
              });
            }
            delete desc.type;
          }
          if (!arr) {
            if (desc.contract) {
              desc.contract = new RecordContract(desc.contract);
            } else {
              if (has_own(desc, 'default') && !has_own(desc, 'type') && (RecordContract.typeDefaults[typeof desc["default"]] != null)) {
                desc.type = typeof desc["default"];
              }
              if (RecordContract.typeDefaults[desc.type] == null) {
                error.Type({
                  type: desc.type,
                  required: 'array, boolean, number, object, string'
                });
              }
            }
          }
          this._match(key, this._default(key));
        }
        Object.freeze(this);
      }


      /*
      Get default value for property from contract definition or from type
      defaults (see: {RecordContract#typeDefaults})
      
      @param [string] key name of property
      
      @throw [KeyError] key not found on contract
      
      @return [any type] default value for property
       */

      RecordContract.prototype._default = function(key) {
        var desc, value, _ref;
        desc = this[key];
        if (!desc) {
          error.Key({
            key: key,
            description: 'Key not found on contract'
          });
        }
        if (has_own(desc, 'default')) {
          return desc["default"];
        }
        if (desc[NULLABLE]) {
          return null;
        }
        if (desc.array) {
          return [];
        }
        if (desc.contract) {
          value = {};
          _ref = desc.contract;
          for (key in _ref) {
            if (!__hasProp.call(_ref, key)) continue;
            value[key] = desc.contract._default(key);
          }
          return value;
        }
        return RecordContract.typeDefaults[desc.type];
      };


      /*
      Check if value matches contract requirements (value type, nullable)
      
      NOTE: It throws an error on mismatch, i.e. it returns true OR throws an
      error.
      
      @param [string] key name of property
      @param [any type] value value to match against contract requirements
      
      @throw [ContractBreakError] key not found or value contract mismatch
      
      @return [boolean] true on success
       */

      RecordContract.prototype._match = function(key, value) {
        var desc;
        desc = this[key];
        if ((desc != null) && ((desc.array && Array.isArray(value)) || ((desc.contract && is_object(value)) || typeof value === desc.type) || (value === null && desc[NULLABLE]))) {
          return true;
        }
        return error.ContractBreak({
          key: key,
          value: value,
          contract: desc
        });
      };


      /*
      Helper method used by {Record} (and classes that extend it) that prevents
      further properties from being added to the record (i.e. having a contract
      comes with the requirement of finalizing the Record instance once all
      properties and methods are added)
      
      @param [Record] record object to finalize
      
      @return [undefined]
       */

      RecordContract.finalizeRecord = function(record) {
        if (record._options.contract && Object.isExtensible(record)) {
          Object.preventExtensions(record);
        }
      };

      RecordContract.typeDefaults = {
        boolean: false,
        number: 0,
        string: ''
      };

      return RecordContract;

    })();
  }
]);

ksc.factory('ksc.Record', [
  'ksc.EventEmitter', 'ksc.RecordContract', 'ksc.error', 'ksc.util', function(EventEmitter, RecordContract, error, util) {
    var ARRAY, CONTRACT, ID_PROPERTY, Record, define_value, has_own, is_array, is_object, object_required, _ARRAY, _EVENTS, _ID, _OPTIONS, _PARENT, _PARENT_KEY, _PSEUDO, _SAVED;
    _ARRAY = '_array';
    _EVENTS = '_events';
    _ID = '_id';
    _OPTIONS = '_options';
    _PARENT = '_parent';
    _PARENT_KEY = '_parentKey';
    _PSEUDO = '_pseudo';
    _SAVED = '_saved';
    ARRAY = 'array';
    CONTRACT = 'contract';
    ID_PROPERTY = 'idProperty';
    define_value = util.defineValue;
    has_own = util.hasOwn;
    is_array = Array.isArray;
    is_object = util.isObject;
    object_required = function(name, value, arg) {
      var inf;
      if (!is_object(value)) {
        inf = {};
        inf[name] = value;
        inf.argument = arg;
        inf.required = 'object';
        return error.ArgumentType(inf);
      }
    };

    /*
    Read-only key-value style record with supporting methods and optional
    multi-level hieararchy.
    
    Supporting methods and properties start with '_' and are not enumerable
    (e.g. hidden when doing `for k of record`, but will match
    record.hasOwnProperty('special_key_name') )
    
    Also supports contracts (see: {RecordContract})
    
    @example
        record = new Record {a: 1, b: 1}
        console.log record.a # 1
        try
          record.a = 2 # try overriding
        console.log record.a # 1
    
    Options that may be used
    - .options.contract
    - .options.idProperty
    - .options.subtreeClass
    
    @author Greg Varsanyi
     */
    return Record = (function() {
      Record.prototype._array = void 0;

      Record.prototype._events = void 0;

      Record.prototype._id = void 0;

      Record.prototype._options = void 0;

      Record.prototype._parent = void 0;

      Record.prototype._parentKey = void 0;

      Record.prototype._pseudo = void 0;

      Record.prototype._saved = void 0;


      /*
      Create the Record instance with initial data and options
      
      @throw [ArgumentTypeError] data, options, parent, parent_key type mismatch
      
      Possible errors thrown at {Record#_replace}
      @throw [TypeError] Can not take functions as values
      @throw [KeyError] Keys can not start with underscore
      
      @param [object] data (optional) data set for the record
      @param [object] options (optional) options to define endpoint, contract,
        id key property etc
      @param [object] parent (optional) reference to parent (list or
        parent record)
      @param [number|string] parent_key (optional) parent record's key
       */

      function Record(data, options, parent, parent_key) {
        var key, record, ref, refs, _i, _len, _ref;
        if (data == null) {
          data = {};
        }
        if (options == null) {
          options = {};
        }
        if (!is_object(data)) {
          error.Type({
            data: data,
            required: 'object'
          });
        }
        object_required('data', data, 1);
        object_required('options', options, 2);
        record = this;
        define_value(record, _OPTIONS, options);
        define_value(record, _SAVED, {});
        if (has_own(options, CONTRACT)) {
          options[CONTRACT] = new RecordContract(options[CONTRACT]);
        }
        if ((parent != null) || (parent_key != null)) {
          object_required('options', parent, 3);
          define_value(record, _PARENT, parent);
          if (parent_key != null) {
            if (!util.isKeyConform(parent_key)) {
              error.Type({
                parent_key: parent_key,
                argument: 4,
                required: 'key conform value'
              });
            }
            define_value(record, _PARENT_KEY, parent_key);
            delete record[_ID];
            delete record[_PSEUDO];
          }
        }
        _ref = util.propertyRefs(Object.getPrototypeOf(record));
        for (key in _ref) {
          refs = _ref[key];
          for (_i = 0, _len = refs.length; _i < _len; _i++) {
            ref = refs[_i];
            Object.defineProperty(ref, key, {
              enumerable: false
            });
          }
        }
        if (parent_key == null) {
          define_value(record, _ID, void 0);
          define_value(record, _PSEUDO, void 0);
          define_value(record, _EVENTS, new EventEmitter);
          record[_EVENTS].halt();
        }
        record._replace(data);
        if (parent_key != null) {
          define_value(record, _EVENTS, null);
        } else {
          record[_EVENTS].unhalt();
        }
        RecordContract.finalizeRecord(record);
      }


      /*
      Clone record or contents
      
      @param [boolean] return_plain_object (optional) return a vanilla js Object
      
      @return [Object|Record] the new instance with identical data
       */

      Record.prototype._clone = function(return_plain_object) {
        var clone, key, record, value;
        if (return_plain_object == null) {
          return_plain_object = false;
        }
        clone = {};
        record = this;
        for (key in record) {
          value = record[key];
          if (is_object(value)) {
            value = value._clone(1);
          }
          clone[key] = value;
        }
        if (return_plain_object) {
          return clone;
        }
        return new record.constructor(clone);
      };


      /*
      Get the entity of the object, e.g. a vanilla Object with the data set
      This method should be overridden by any extending classes that have their
      own idea about the entity (e.g. it does not match the data set)
      This may be the most useful if you can not have a contract.
      
      Defaults to cloning to a vanilla Object instance.
      
      @return [Object] the new Object instance with the copied data
       */

      Record.prototype._entity = function() {
        return this._clone(1);
      };


      /*
      (Re)define the initial data set
      
      @note Will try and create an ._options.idProperty if it is missing off of
        the first key in the dictionary, so that it can be used as ._id
      @note Will set ._options.idProperty value of the data set to null if it is
        not defined
      
      @throw [TypeError] Can not take functions as values
      @throw [KeyError] Keys can not start with underscore
      
      @param [object] data Key-value map of data
      @param [boolean] emit_event if replace should trigger event emission
        (defaults to true)
      
      @event 'update' sends out message on changes:
        events.emit {node: record, action: 'replace'}
      
      @return [boolean] indicates change in data
       */

      Record.initIdProperty = function(record, data) {
        var contract, id_property, id_property_contract_check, key, options, part, _i, _len, _results;
        options = record[_OPTIONS];
        contract = options[CONTRACT];
        if (options[ID_PROPERTY] == null) {
          for (key in data) {
            options[ID_PROPERTY] = key;
            break;
          }
        }
        id_property_contract_check = function(key) {
          var _ref;
          if (contract) {
            if (contract[key] == null) {
              error.ContractBreak({
                key: key,
                contract: contract,
                mismatch: 'idProperty'
              });
            }
            if ((_ref = contract[key].type) !== 'string' && _ref !== 'number') {
              return error.ContractBreak({
                key: key,
                contract: contract,
                required: 'string or number'
              });
            }
          }
        };
        if (record[_EVENTS]) {
          if (id_property = options[ID_PROPERTY]) {
            if (id_property instanceof Array) {
              _results = [];
              for (_i = 0, _len = id_property.length; _i < _len; _i++) {
                part = id_property[_i];
                id_property_contract_check(part);
                _results.push(data[part] != null ? data[part] : data[part] = null);
              }
              return _results;
            } else {
              id_property_contract_check(id_property);
              return data[id_property] != null ? data[id_property] : data[id_property] = null;
            }
          }
        }
      };

      Record.prototype._valueCheck = function(key, value) {
        var contract;
        if (contract = this[_OPTIONS][CONTRACT]) {
          return contract._match((this[_ARRAY] ? 'all' : key), value);
        } else {
          if (key.substr(0, 1) === '_') {
            error.Key({
              key: key,
              description: 'can not start with "_"'
            });
          }
          if (typeof value === 'function') {
            return error.Type({
              value: value,
              description: 'can not be function'
            });
          }
        }
      };

      Record.valueWrap = function(record, key, value) {
        var class_ref, contract, key_contract, opt, subopts;
        contract = record[_OPTIONS][CONTRACT];
        if (is_object(value)) {
          if (value instanceof Record) {
            value = value._clone(1);
          }
          class_ref = record[_OPTIONS].subtreeClass || Record;
          if (key_contract = contract != null ? contract[key] : void 0) {
            if (opt = key_contract[ARRAY]) {
              subopts = {
                contract: {
                  all: opt
                }
              };
            }
            if (opt = key_contract[CONTRACT]) {
              subopts = {
                contract: opt
              };
            }
          }
          value = new class_ref(value, subopts, record, key);
        }
        return value;
      };

      Record.prototype._initProperty = function(key, value) {
        var record;
        record = this;
        record._valueCheck(key, value);
        if (has_own(record, key) && util.identical(value, record[key])) {
          return;
        }
        record._removeProperty(key);
        value = Record.valueWrap(record, key, value);
        define_value(record[_SAVED], key, value, 0, 1);
        util.defineGetSet(record, key, (function() {
          return record._getProperty(key);
        }), (function(val) {
          return record._setProperty(key, val);
        }), 1);
        return true;
      };

      Record.prototype._getProperty = function(key) {
        var value;
        value = this[_SAVED][key];
        if (!(value != null ? value[_ARRAY] : void 0)) {
          return value;
        }
        return Record.arrayRecord(value[_ARRAY]);
      };

      Record.prototype._setProperty = function(key, value) {
        return error.Permission({
          key: key,
          value: value,
          description: 'Read-only Record'
        });
      };

      Record.prototype._removeProperty = function(key) {
        delete this[key];
        return delete this[_SAVED][key];
      };

      Record.prototype._replace = function(data, emit_event) {
        var arr, arrayified, changed, contract, key, options, record, value;
        if (emit_event == null) {
          emit_event = true;
        }
        record = this;
        options = record[_OPTIONS];
        contract = options[CONTRACT];
        if (record[_EVENTS] === null) {
          error.Permission({
            key: record[_PARENT_KEY],
            description: 'can not replace subobject'
          });
        }
        Record.initIdProperty(record, data);
        changed = false;
        if (is_array(data)) {
          if (!(arr = record[_ARRAY])) {
            define_value(record, _ARRAY, arr = []);
          } else {
            util.empty(arr);
          }
          util.arrayGetterify(arr, function(index, value) {
            if (arrayified) {
              return record._setProperty(key, value);
            } else {
              return record._initProperty(key, value);
            }
          });
          arrayified = 1;
        } else {
          delete record[_ARRAY];
        }
        for (key in data) {
          value = data[key];
          if (record._initProperty(key, value)) {
            changed = true;
          }
        }
        if (!is_array(data)) {
          if (contract) {
            for (key in contract) {
              if (!has_own(data, key)) {
                if (record._initProperty(key, contract._default(key))) {
                  changed = true;
                }
              }
            }
          } else {
            for (key in record) {
              if (!(!has_own(data, key))) {
                continue;
              }
              record._removeProperty(key);
              changed = true;
            }
          }
          util.arrayGetterify(arr, function(index, value) {
            var class_ref, subopts;
            if (Object.isFrozen(arr)) {
              error.Permission({
                array: arr,
                index: index,
                value: value,
                description: 'Can not set on read-only array'
              });
            }
            if (contract != null) {
              contract._match('all', value);
            }
            if (is_object(value)) {
              if (value instanceof Record) {
                value = value._clone(1);
              }
              class_ref = options.subtreeClass || Record;
              subopts = {};
              if (contract != null ? contract.all[CONTRACT] : void 0) {
                subopts[CONTRACT] = contract.all[CONTRACT];
              }
              value = new class_ref(value, subopts, record, index);
            }
            return value;
          });
          arr.push.apply(arr, data);
          Record.arrayRecord(record);
          if (contract && !Object.isFrozen(arr)) {
            Object.freeze(arr);
          }
        }
        if (changed && record[_EVENTS] && emit_event) {
          Record.emitUpdate(record, 'replace');
        }
        return changed;
      };

      Record.arrayRecord = function(record) {
        var arr, desc, key, marked, object, _i, _len, _ref;
        arr = record[_ARRAY];
        object = record;
        marked = {};
        while (object && object.constructor !== Object) {
          _ref = Object.getOwnPropertyNames(object);
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            key = _ref[_i];
            if (key.substr(0, 1) === '_' && !has_own(marked, key)) {
              marked[key] = Object.getOwnPropertyDescriptor(object, key);
            }
          }
          object = Object.getPrototypeOf(object);
        }
        for (key in arr) {
          if (!__hasProp.call(arr, key)) continue;
          if (key.substr(0, 1) === '_' && !has_own(marked, key)) {
            delete arr[key];
          }
        }
        for (key in marked) {
          desc = marked[key];
          Object.defineProperty(arr, key, desc);
        }
        return arr;
      };


      /*
      Event emission - with handling complexity around subobjects
      
      @param [object] record reference to record or subrecord object
      @param [string] action 'revert', 'replace', 'set', 'delete' etc
      @param [object] extra_info (optional) info to be attached to the emission
      
      @return [undefined]
       */

      Record.emitUpdate = function(record, action, extra_info) {
        var events, info, key, old_id, path, source, value, _ref;
        if (extra_info == null) {
          extra_info = {};
        }
        path = [];
        source = record;
        while (!(events = source[_EVENTS])) {
          path.unshift(source[_PARENT_KEY]);
          source = source[_PARENT];
        }
        info = {
          node: record
        };
        if (record !== source) {
          info.parent = source;
          info.path = path;
        }
        info.action = action;
        for (key in extra_info) {
          value = extra_info[key];
          info[key] = value;
        }
        old_id = source[_ID];
        Record.setId(source);
        if (!source[_EVENTS]._halt) {
          if ((_ref = source[_PARENT]) != null) {
            if (typeof _ref._recordChange === "function") {
              _ref._recordChange(source, info, old_id);
            }
          }
        }
        events.emit('update', info);
      };


      /*
      Define _id for the record
      
      Composite IDs will be used and ._primaryId will be created if
      .options.idProperty is an Array. The composite is c
      - Parts are stringified and joined by '-'
      - If a part is empty (e.g. '' or null), the part will be skipped in ._id
      - If primary part of composite ID is null, the whole ._id is going to
        be null (becomes a pseudo/new record)
      @example
        record = new EditableRecord {id: 1, otherId: 2, name: 'x'},
                                    {idProperty: ['id', 'otherId', 'name']}
        console.log record._id, record._primaryId # '1-2-x', 1
      
        record.otherId = null
        console.log record._id, record._primaryId # '1-x', 1
      
        record.id = null
        console.log record._id, record._primaryId # null, null
      
      @param [Record] record record instance to be updated
      
      @return [undefined]
       */

      Record.setId = function(record) {
        var composite, i, id, id_property, part, value, _i, _len;
        if (id_property = record[_OPTIONS][ID_PROPERTY]) {
          if (id_property instanceof Array) {
            composite = [];
            for (i = _i = 0, _len = id_property.length; _i < _len; i = ++_i) {
              part = id_property[i];
              if (util.isKeyConform(record[part])) {
                composite.push(record[part]);
              } else if (!i) {
                break;
              }
            }
            id = composite.length ? composite.join('-') : null;
            define_value(record, _ID, id);
            define_value(record, '_primaryId', record[id_property[0]]);
          } else {
            value = record[id_property];
            define_value(record, _ID, value != null ? value : null);
          }
        }
      };

      return Record;

    })();
  }
]);

ksc.factory('ksc.RestList', [
  '$http', '$q', 'ksc.List', 'ksc.batchLoaderRegistry', 'ksc.error', 'ksc.restUtil', 'ksc.util', function($http, $q, List, batchLoaderRegistry, error, restUtil, util) {
    var PRIMARY_ID, REST_CACHE, REST_PENDING, RestList, define_value;
    REST_CACHE = 'restCache';
    REST_PENDING = 'restPending';
    PRIMARY_ID = '_primaryId';
    define_value = util.defineValue;

    /*
    REST methods for ksc.List
    
    Load, save and delete records in bulks or individually
    
    @example
        list = new RestList
          endpoint:
            url: '/api/MyEndpoint'
          record:
            endpoint:
              url: '/api/MyEndpoint/<id>'
    
    Options that may be used by methods of ksc.RestList
    - .options.cache (full cache - use if the entire list is loaded)
    - .options.endpoint.bulkDelete (delete 2+ records in 1 request)
    - .options.endpoint.bulkSavel (save 2+ records in 1 request)
    - .options.endpoint.responseProperty (array of records in list response)
    - .options.endpoint.url (url for endpoint)
    - .options.record.endpoint.url (url for endpoint with record ID)
    - .options.reloadOnUpdate (force reload on save instead of picking up
      response of POST or PUT request)
    
    Options that may be used by methods of ksc.List
    - .options.record.class (class reference for record objects)
    - .options.record.idProperty (property/properties that define record ID)
    
    @author Greg Varsanyi
     */
    return RestList = (function(_super) {
      __extends(RestList, _super);

      function RestList() {
        return RestList.__super__.constructor.apply(this, arguments);
      }

      RestList.prototype.restCache = null;


      /*
      @property [number] The number of REST requests pending
       */

      RestList.prototype.restPending = 0;


      /*
      Query list endpoint for raw data
      
      Option used:
      - .options.endpoint.url
      
      @param [Object] query_parameters (optional) Query string arguments
      @param [function] callback (optional) Callback function with signiture:
        (err, raw_response) ->
      @option raw_response [HttpError] error (optional) errorous response info
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration
      
      @throw [ValueError] No .options.endpoint.url
      @throw [TypeError] .options.endpoint.url is not a string
      
      @return [Promise] Promise returned by $http
       */

      RestList.prototype.restGetRaw = function(query_parameters, callback) {
        var endpoint, k, list, parts, promise, url, v;
        if (typeof query_parameters === 'function') {
          callback = query_parameters;
          query_parameters = null;
        }
        list = this;
        if (!((endpoint = list.options.endpoint) && (url = endpoint.url) && typeof url === 'string')) {
          error.Type({
            'options.endpoint.url': url,
            required: 'string'
          });
        }
        define_value(list, REST_PENDING, list[REST_PENDING] + 1, 0, 1);
        if (!(promise = batchLoaderRegistry.get(url, query_parameters))) {
          if (query_parameters) {
            parts = (function() {
              var _results;
              _results = [];
              for (k in query_parameters) {
                v = query_parameters[k];
                _results.push(encodeURIComponent(k) + '=' + encodeURIComponent(v));
              }
              return _results;
            })();
            if (parts.length) {
              url += (url.indexOf('?') > -1 ? '&' : '?') + parts.join('&');
            }
          }
          promise = $http.get(url);
        }
        return restUtil.wrapPromise(promise, function(err, result) {
          define_value(list, REST_PENDING, list[REST_PENDING] - 1, 0, 1);
          return callback(err, result);
        });
      };


      /*
      Query list endpoint for records
      
      Options that may be used:
      - .options.cache (full cache - use if the entire list is loaded)
      - .options.endpoint.responseProperty (array of records in list response)
      - .options.endpoint.url (url for endpoint)
      - .options.record.class (class reference for record objects)
      - .options.record.idProperty (property/properties that define record ID)
      
      @param [boolean] force_load (optional) Request disregarding cache
      @param [Object] query_parameters (optional) Query string arguments
      @param [function] callback (optional) Callback function with signiture:
        (err, record_list, raw_response) ->
      @option record_list [Array] insert (optional) List of inserted records
      @option record_list [Array] update (optional) List of updated records
      @option raw_response [HttpError] error (optional) errorous response info
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration
      
      @throw [ValueError] No .options.endpoint.url
      @throw [TypeError] .options.endpoint.url is not a string
      
      @return [Promise] Promise returned by $http
       */

      RestList.prototype.restLoad = function(force_load, query_parameters, callback) {
        var http_get, list, options;
        if (typeof force_load !== 'boolean') {
          callback = query_parameters;
          query_parameters = force_load;
          force_load = null;
        }
        if (typeof query_parameters === 'function') {
          callback = query_parameters;
          query_parameters = null;
        }
        list = this;
        options = list.options;
        http_get = function() {
          return list.restGetRaw(query_parameters, function(err, raw_response) {
            var data, record_list, _err;
            if (!err) {
              try {
                data = RestList.getResponseArray(list, raw_response.data);
                record_list = list.push.apply(list, __slice.call(data).concat([true]));
              } catch (_error) {
                _err = _error;
                err = _err;
              }
            }
            return typeof callback === "function" ? callback(err, record_list, raw_response) : void 0;
          });
        };
        if (!options.cache || !list.restCache || force_load) {
          define_value(list, 'restCache', http_get(), 0, 1);
        } else if (callback) {
          restUtil.wrapPromise(list.restCache, callback);
        }
        return list.restCache;
      };


      /*
      Save record(s)
      
      Uses {RestList#writeBack}
      
      Records may be map IDs from list.map or the record instances
      
      Records must be unique
      
      If records have composite IDs (see: {Record#setId}), ._primaryId will be
      used, all records with identical ._primaryId will be updated
      
      Options that may be used:
      - .options.endpoint.url (url for endpoint)
      - .options.endpoint.bulkSave = true/'PUT' or 'POST'
      - .options.record.idProperty (property/properties that define record ID)
      - .options.record.endpoint.url (url for endpoint with ID)
      - .options.reloadOnUpdate (force reload on save instead of picking up
        response of POST or PUT request)
      
      @param [Record/number] records... 1 or more records or ID's to save
      @param [function] callback (optional) Callback function with signiture:
        (err, record_list, raw_response) ->
      @option record_list [Array] insert (optional) List of new records
      @option record_list [Array] update (optional) List of updated records
      @option raw_response [HttpError] error (optional) errorous response info
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration
      
      @throw [MissingArgumentError] No record to save
      @throw [ValueError] Invalid .options(.record).endpoint.url
      @throw [ValueError] Non-unique record was passed in
      
      @return [HttpPromise] Promise or chained promises returned by $http.put or
      $http.post
       */

      RestList.prototype.restSave = function() {
        var callback, records, _i;
        records = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), callback = arguments[_i++];
        return RestList.writeBack(this, 1, records, callback);
      };


      /*
      Delete record(s)
      
      Uses {RestList#writeBack}
      
      Records may be map IDs from list.map or the record instances
      
      Records must be unique
      
      If records have composite IDs (see: {Record#setId}), ._primaryId will be
      used, all records with identical ._primaryId will be deleted
      
      Options that may be used:
      - .options.endpoint.url (url for endpoint)
      - .options.endpoint.bulkDelete
      - .options.record.idProperty (property/properties that define record ID)
      - .options.record.endpoint.url (url for endpoint with ID)
      
      @param [Record/number] records... 1 or more records or ID's to delete
      @param [function] callback (optional) Callback function with signiture:
        (err, record_list, raw_response) ->
      @option record_list [Array] insert (optional) List of new records
      @option record_list [Array] update (optional) List of updated records
      @option raw_response [HttpError] error (optional) errorous response info
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration
      
      @throw [MissingArgumentError] No record to delete
      @throw [ValueError] Invalid .options(.record).endpoint.url
      @throw [ValueError] Non-unique record was passed in
      
      @return [HttpPromise] Promise or chained promises returned by $http.delete
       */

      RestList.prototype.restDelete = function() {
        var callback, records, _i;
        records = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), callback = arguments[_i++];
        return RestList.writeBack(this, 0, records, callback);
      };


      /*
      ID the array in list GET response
      
      Uses .options.endpoint.responseProperty or attempts to create it based on
      provided data. Returns identified array or throws an error.
      
      Uses option:
      - .options.endpoint.responseProperty (defines which property of response
      JSON object is the record array)
      
      @param [Array] list Array generated by {RestList}
      @param [Object] data Response object from REST API for list GET request
      
      @throw [ValueError] Array not found in data
      
      @return [Array] List of raw records (property of data or data itself)
       */

      RestList.getResponseArray = function(list, data) {
        var endpoint_options, k, key, v;
        endpoint_options = list.options.endpoint;
        key = 'responseProperty';
        if (typeof endpoint_options[key] === 'undefined') {
          if (Array.isArray(data)) {
            endpoint_options[key] = null;
          }
          for (k in data) {
            v = data[k];
            if (Array.isArray(v)) {
              endpoint_options[key] = k;
            }
          }
        }
        if (endpoint_options[key] != null) {
          data = data[endpoint_options[key]];
        }
        if (!(data instanceof Array)) {
          error.Value({
            'options.endpoint.responseProperty': void 0,
            description: 'array type property in response is not found or ' + 'unspecified'
          });
        }
        return data;
      };


      /*
      Find records with identical ._primaryId and return them along with the
      checked record (or just return a single-element array with the checked
      record if it does not have ._primaryId)
      
      @param [Array] list Array generated by {RestList}
      @param [Record] record Record to get related records for
      
      @return [Array] All records on the list with identical ._primaryId
       */

      RestList.relatedRecords = function(list, record) {
        var id, item, _i, _len, _results;
        if ((id = record[PRIMARY_ID]) == null) {
          return [record];
        }
        _results = [];
        for (_i = 0, _len = list.length; _i < _len; _i++) {
          item = list[_i];
          if (item[PRIMARY_ID] === id) {
            _results.push(item);
          }
        }
        return _results;
      };


      /*
      Take the response as update value unless
      - record has composite id
      - .options.reloadOnUpdate is truthy
      
      Option that may be used:
      - .options.reloadOnUpdate (force reload on save instead of picking up
        response of POST or PUT request)
      
      @param [Array] list Array generated by {RestList}
      @param [Array] records Records that were saved
      @param [Array] updates Related responses of PUT/POST request(s)
      @param [function] next callback function - called when updates are done
      
      @return [undefined]
       */

      RestList.updateOnSave = function(list, records, updates, next) {
        var changed, data, i, key, primary_id, promise, promises, query_parameters, record, replacable, replace, tmp_listener_unsubscribe, _i, _j, _len, _len1;
        promises = [];
        replacable = [];
        for (i = _i = 0, _len = records.length; _i < _len; i = ++_i) {
          record = records[i];
          if (((primary_id = record[PRIMARY_ID]) != null) || list.options.reloadOnUpdate) {
            query_parameters = {};
            key = record._options.idProperty;
            if (primary_id) {
              query_parameters[key[0]] = primary_id;
            } else {
              query_parameters[key] = record._id;
            }
            promises.push(list.restLoad(query_parameters));
          } else {
            replacable.push([record, updates[i]]);
          }
        }
        if (replacable.length) {
          list.events.halt();
          changed = [];
          tmp_listener_unsubscribe = list.events.on('1#!update', function(info) {
            return changed.push(info.action.update[0]);
          });
          try {
            for (_j = 0, _len1 = replacable.length; _j < _len1; _j++) {
              replace = replacable[_j];
              record = replace[0], data = replace[1];
              record._replace(data);
            }
          } finally {
            tmp_listener_unsubscribe();
            list.events.unhalt();
          }
          if (changed.length) {
            list.events.emit('update', {
              node: list,
              action: {
                update: changed
              }
            });
          }
        }
        if (promises.length) {
          promise = $q.all(promises);
          promise.then(next, next);
        } else {
          next();
        }
      };


      /*
      PUT, POST and DELETE joint logic
      
      After error checks, it will pass the request to {RestList#writeBulk} or
      {RestList#writeSolo} depending on what the endpoint supports
      
      Records may be map IDs from list.map or the record instances
      
      Records must be unique
      
      If records have composite IDs (see: {Record#setId}), ._primaryId will be
      used, all records with identical ._primaryId will be affected
      
      Options that may be used:
      - .options.endpoint.bulkDelete
      - .options.endpoint.bulkSave = true/'PUT' or 'POST'
      - .options.endpoint.url
      - .options.record.idProperty (property/properties that define record ID)
      - .options.record.endpoint.url (url for endpoint with ID)
      - .options.reloadOnUpdate (force reload on save instead of picking up
        response of POST or PUT request)
      
      @param [Array] list Array generated by {RestList}
      @param [boolean] save_type Save (PUT/POST) e.g. not delete
      @param [Array] records List of records to save/delete
      @param [function] callback (optional) Callback function with signiture:
        (err, record_list, raw_response) ->
      
      @throw [MissingArgumentError] No record to save/delete
      @throw [ValueError] Invalid .options(.record).endpoint.url
      @throw [ValueError] Non-unique record was passed in
      
      @return [Promise] Promise or chained promises of the HTTP action(s)
       */

      RestList.writeBack = function(list, save_type, records, callback) {
        var bulk_method, endpoint_options, i, id, orig_rec, pseudo_id, record, uid, unique_record_map, _i, _len;
        if (!(callback && typeof callback === 'function')) {
          if (callback) {
            records.push(callback);
          }
          callback = null;
        }
        unique_record_map = {};
        for (i = _i = 0, _len = records.length; _i < _len; i = ++_i) {
          record = records[i];
          if (!util.isObject(record)) {
            records[i] = record = list.map[record];
          }
          orig_rec = record;
          pseudo_id = null;
          uid = 'id:' + (id = record != null ? record._id : void 0);
          if ((id = record != null ? record._id : void 0) == null) {
            pseudo_id = record != null ? record._pseudo : void 0;
            uid = 'pseudo:' + pseudo_id;
          } else if (record[PRIMARY_ID] != null) {
            uid = 'id:' + record[PRIMARY_ID];
          }
          if (save_type) {
            record = (pseudo_id && list.pseudo[pseudo_id]) || list.map[id];
            if (!record) {
              error.Key({
                key: orig_rec,
                description: 'no such record on list'
              });
            }
          } else if (!(record = list.map[id])) {
            error.Key({
              key: orig_rec,
              description: 'no such record on map'
            });
          }
          if (unique_record_map[uid]) {
            error.Value({
              uid: uid,
              description: 'not unique'
            });
          }
          unique_record_map[uid] = record;
        }
        if (!records.length) {
          error.MissingArgument({
            name: 'record',
            argument: 1
          });
        }
        endpoint_options = list.options.endpoint || {};
        if (save_type && endpoint_options.bulkSave) {
          bulk_method = String(endpoint_options.bulkSave).toLowerCase();
          if (bulk_method !== 'post') {
            bulk_method = 'put';
          }
          return RestList.writeBulk(list, bulk_method, records, callback);
        } else if (!save_type && endpoint_options.bulkDelete) {
          return RestList.writeBulk(list, 'delete', records, callback);
        } else {
          return RestList.writeSolo(list, save_type, records, callback);
        }
      };


      /*
      PUT, POST or DELETE on .options.endpoint.url - joint operation, single XHR
      thread
      
      If records have composite IDs (see: {Record#setId}), ._primaryId will be
      used, all records with identical ._primaryId will be affected
      
      Options that may be used:
      - .options.endpoint.url (url for endpoint with ID)
      - .options.reloadOnUpdate (force reload on save instead of picking up
        response of POST or PUT request)
      
      @param [Array] list Array generated by {RestList}
      @param [string] method 'put', 'post' or 'delete'
      @param [Array] records List of records to save/delete
      @param [function] callback (optional) Callback function with signiture:
        (err, record_list, raw_response) ->
      
      @throw [ValueError] Invalid .options.record.endpoint.url
      
      @return [Promise] Promise of HTTP action
       */

      RestList.writeBulk = function(list, method, records, callback) {
        var args, data, id, promise, record, saving, url;
        if (!((url = list.options.endpoint.url) && typeof url === 'string')) {
          error.Type({
            'options.endpoint.url': url,
            required: 'string'
          });
        }
        saving = method !== 'delete';
        data = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = records.length; _i < _len; _i++) {
            record = records[_i];
            if (saving) {
              _results.push(record._entity());
            } else {
              if ((id = record[PRIMARY_ID]) == null) {
                id = record._id;
              }
              _results.push(id);
            }
          }
          return _results;
        })();
        args = [url];
        if (saving) {
          args.push(data);
        }
        list[REST_PENDING] += 1;
        promise = $http[method].apply($http, args);
        return restUtil.wrapPromise(promise, function(err, raw_response) {
          var ready, related, _i, _len;
          list[REST_PENDING] -= 1;
          ready = function() {
            return typeof callback === "function" ? callback(err, related, raw_response) : void 0;
          };
          related = [];
          for (_i = 0, _len = records.length; _i < _len; _i++) {
            record = records[_i];
            related.push.apply(related, RestList.relatedRecords(list, record));
          }
          if (!err) {
            if (saving) {
              RestList.updateOnSave(list, records, raw_response.data, ready);
            } else {
              list.cut.apply(list, related);
              ready();
            }
          }
          return ready();
        });
      };


      /*
      PUT, POST or DELETE on .options.record.endpoint.url - separate XHR threads
      
      If records have composite IDs (see: {Record#setId}), ._primaryId will be
      used, all records with identical ._primaryId will be affected
      
      Options that may be used:
      - .options.record.endpoint.url (url for endpoint with ID)
      - .options.reloadOnUpdate (force reload on save instead of picking up
        response of POST or PUT request)
      
      @param [Array] list Array generated by {RestList}
      @param [boolean] save_type Save (PUT/POST) e.g. not delete
      @param [Array] records List of records to save/delete
      @param [function] callback (optional) Callback function with signiture:
        (err, record_list, raw_response) ->
      
      @throw [ValueError] Invalid .options.record.endpoint.url
      
      @return [Promise] Promise or chained promises of the HTTP action(s)
       */

      RestList.writeSolo = function(list, save_type, records, callback) {
        var delayed_cb_args, finished, iteration, pending_refresh, record_list;
        record_list = [];
        delayed_cb_args = pending_refresh = null;
        finished = function(err) {
          var raw_responses;
          raw_responses = Array.prototype.slice.call(arguments, 1);
          delayed_cb_args = [err, record_list].concat(__slice.call(raw_responses));
          if (!pending_refresh) {
            if (typeof callback === "function") {
              callback.apply(null, delayed_cb_args);
            }
            return delayed_cb_args = null;
          }
        };
        iteration = function(record) {
          var args, id, method, promise, url, _ref, _ref1;
          if ((id = record[PRIMARY_ID]) == null) {
            id = record._id;
          }
          method = 'delete';
          url = (_ref = list.options.record.endpoint) != null ? _ref.url : void 0;
          if (save_type) {
            method = 'put';
            if (record._pseudo) {
              method = 'post';
              id = null;
              url = (_ref1 = list.options.endpoint) != null ? _ref1.url : void 0;
            }
          }
          if (!(url && typeof url === 'string')) {
            error.Value({
              'options.record.endpoint.url': url,
              required: 'string'
            });
          }
          url = url.replace('<id>', id);
          args = [url];
          if (save_type) {
            args.push(record._entity());
          }
          list[REST_PENDING] += 1;
          promise = $http[method].apply($http, args);
          return restUtil.wrapPromise(promise, function(err, raw_response) {
            var related;
            list[REST_PENDING] -= 1;
            related = RestList.relatedRecords(list, record);
            if (!err) {
              if (save_type) {
                pending_refresh = (pending_refresh || 0) + 1;
                RestList.updateOnSave(list, [record], [raw_response.data], function() {
                  pending_refresh -= 1;
                  if (delayed_cb_args) {
                    return typeof callback === "function" ? callback.apply(null, delayed_cb_args) : void 0;
                  }
                });
              } else {
                list.cut.apply(list, related);
              }
            }
            record_list.push.apply(record_list, related);
          });
        };
        return restUtil.asyncSquash(records, iteration, finished);
      };

      return RestList;

    })(List);
  }
]);

ksc.factory('ksc.RestRecord', [
  '$http', 'ksc.Record', 'ksc.batchLoaderRegistry', 'ksc.error', 'ksc.restUtil', 'ksc.util', function($http, Record, batchLoaderRegistry, error, restUtil, util) {
    var OPTIONS, REST_CACHE, REST_PENDING, RestRecord, define_value;
    OPTIONS = '_options';
    REST_CACHE = '_restCache';
    REST_PENDING = '_restPending';
    define_value = util.defineValue;

    /*
    Record with REST load binding ($http GET wrapper)
    
    @example
        record = new EditableRestRecord null, {endpoint: {url: '/test'}}
        record._restLoad (err, raw_response) ->
          console.log 'Done with', err, 'error'
          console.log record # will show record with loaded values
    
    Option used:
    - ._options.cache
    - ._options.endpoint.url
    
    @author Greg Varsanyi
     */
    return RestRecord = (function(_super) {
      __extends(RestRecord, _super);

      RestRecord.prototype._restCache = null;

      RestRecord.prototype._restPending = 0;


      /*
      Constructs RestRecord instance, sets ._restPending property and calls
      super ({Record#constructor})
       */

      function RestRecord() {
        define_value(this, REST_PENDING, 0);
        RestRecord.__super__.constructor.apply(this, arguments);
      }


      /*
      Trigger loading data from the record-style endpoint specified in
      _options.cache
      _options.endpoint.url
      
      Bumps up ._restPending counter by 1 when starting to load (and will
      decrease by 1 when done)
      
      @param [boolean] force_load (optinal) Request disregarding cache
      @param [function] callback (optional) will call back with signiture:
        (err, raw_response) ->
      @option raw_response [HttpError] error (optional) errorous response info
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration
      
      @throw [ValueError] Missing endpoint url value
      @throw [TypeError] Endpoint url is not a string
      
      @return [HttpPromise] promise object created by $http
       */

      RestRecord.prototype._restLoad = function(force_load, callback) {
        var http_get, record;
        record = this;
        http_get = function() {
          var promise, url;
          url = RestRecord.getUrl(record);
          if (!(promise = batchLoaderRegistry.get(url))) {
            promise = $http.get(url);
          }
          return RestRecord.async(record, promise, callback);
        };
        if (typeof force_load !== 'boolean') {
          callback = force_load;
          force_load = null;
        }
        if (!record[OPTIONS].cache || !record[REST_CACHE] || force_load) {
          define_value(record, REST_CACHE, http_get());
        } else if (callback) {
          restUtil.wrapPromise(record[REST_CACHE], callback);
        }
        return record[REST_CACHE];
      };


      /*
      Helper that wraps request, increases/decreases pending load counter and
      updates data on incoming
      
      @param [Record] record reference to data container
      @param [HttpPromise] promise $http promise that should be wrapped
      @param [function] callback (optinal) callback function
        (see: {RestRecord#_restLoad})
      
      @return [HttpPromise] the promise that was wrapped
       */

      RestRecord.async = function(record, promise, callback) {
        define_value(record, REST_PENDING, record[REST_PENDING] + 1);
        return restUtil.wrapPromise(promise, function(err, raw_response) {
          define_value(record, REST_PENDING, record[REST_PENDING] - 1);
          if (!err && raw_response.data) {
            record._replace(raw_response.data);
          }
          return typeof callback === "function" ? callback(err, raw_response) : void 0;
        });
      };


      /*
      Get the url from _options.endpoint.url or throw errors as needed
      
      @param [Record] record reference to data container
      
      @throw [ValueError] Missing endpoint url value
      @throw [TypeError] Endpoint url is not a string
      
      @return [string] url
       */

      RestRecord.getUrl = function(record) {
        var endpoint, url;
        if (!((endpoint = record[OPTIONS].endpoint) && ((url = endpoint.url) != null))) {
          error.Value({
            '_options.endpoint.url': void 0
          });
        }
        if (typeof url !== 'string') {
          error.Type({
            '_options.endpoint.url': url,
            required: 'string'
          });
        }
        return url;
      };

      return RestRecord;

    })(Record);
  }
]);

ksc.service('ksc.restUtil', [
  '$q', 'ksc.error', function($q, error) {

    /*
    Rest/XHR call related utilities
    
    @author Greg Varsanyi
     */
    var RestUtil;
    return RestUtil = (function() {
      function RestUtil() {}


      /*
      Squash multiple requests into a single one
      
      @param [Array] list of values that will be used as argument #1 and passed
        to iteration_fn in each iteration. Number of items defines number of
        iterations.
      @param [function] iteration_fn function to be called for each iteration.
        Signiture is: `(iteration_data_set) ->` and should return a Promise
      @param [function] done_callback function to be called when chained promise
        gets resolved
      
      @return [Promise] chained promises of all requests
       */

      RestUtil.asyncSquash = function(iteration_data_sets, iteration_fn, done_callback) {
        var count, error_list, iteration_callback, iteration_data_set, len, promises, results;
        count = 0;
        error_list = [];
        len = iteration_data_sets.length;
        results = [];
        iteration_callback = function(err, result) {
          var config, data, headers, status;
          data = result.data, status = result.status, headers = result.headers, config = result.config;
          count += 1;
          if (err != null) {
            error_list.push(err);
          }
          results.push({
            error: err,
            data: data,
            status: status,
            headers: headers,
            config: config
          });
          if (count === len && done_callback) {
            error = null;
            if (error_list.length === 1) {
              error = error_list[0];
            } else if (error_list.length) {
              error = error_list;
            }
            return done_callback.apply(null, [error].concat(__slice.call(results)));
          }
        };
        promises = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = iteration_data_sets.length; _i < _len; _i++) {
            iteration_data_set = iteration_data_sets[_i];
            _results.push(RestUtil.wrapPromise(iteration_fn(iteration_data_set), iteration_callback));
          }
          return _results;
        })();
        if (promises.length < 2) {
          return promises[0];
        }
        return $q.all(promises);
      };


      /*
      Add listeners to promise so that standard callback functions with
      signiture `(err, results...) ->` can be called when the
      promise gets resolved.
      
      On callback function, argument `err` is null on no errors or an instance
      of Error if there was an error.
      `result` is the raw result of the request, similar to what $http methods
      return: {data, status, headers, config}
      
      @param [Promise] promise $q promise to be wrapped
      @param [function] callback response function
      
      @return [Promise] the provided promise object reference
       */

      RestUtil.wrapPromise = function(promise, callback) {
        var error_fn, success_fn;
        success_fn = function(result) {
          var config, data, headers, status, wrap;
          wrap = (data = result.data, status = result.status, headers = result.headers, config = result.config, result);
          return callback(null, wrap);
        };
        error_fn = function(result) {
          var config, data, err, headers, status, wrap;
          wrap = (data = result.data, status = result.status, headers = result.headers, config = result.config, result);
          err = new error.type.Http(result);
          wrap.error = err;
          return callback(err, wrap);
        };
        promise.then(success_fn, error_fn);
        return promise;
      };

      return RestUtil;

    })();
  }
]);

ksc.service('ksc.util', [
  'ksc.error', function(error) {
    var Util, arg_check, define_property, define_value, get_own_property_descriptor, get_prototype_of, has_own, is_object;
    define_property = Object.defineProperty;
    get_own_property_descriptor = Object.getOwnPropertyDescriptor;
    get_prototype_of = Object.getPrototypeOf;
    arg_check = function(args) {
      if (!args.length) {
        return error.MissingArgument({
          name: 'reference',
          argument: 1
        });
      }
    };

    /*
    Miscellaneous utilities that do not belong to other named utility groups
    (like restUtil)
    
    @author Greg Varsanyi
     */
    Util = (function() {
      function Util() {}


      /*
      Add/update an object property with a getter and an (optional) setter
      
      @param [Object] object target object reference
      @param [string|number] key property name on object
      @param [function] getter function that returns value
      @param [function] setter (optional) function that consumes set value
      @param [boolean] enumerable (optional, default: false) if the property
        should be enumerable in a `for key of object` loop
      
      @return [object] reference to object
       */

      Util.defineGetSet = function(object, key, getter, setter, enumerable) {
        if (typeof setter !== 'function') {
          enumerable = setter;
          setter = void 0;
        }
        return define_property(object, key, {
          configurable: true,
          enumerable: !!enumerable,
          get: getter,
          set: setter
        });
      };


      /*
      Add/update an object property with provided value
      
      @param [Object] object target object reference
      @param [string|number] key property name on object
      @param [any type] value
      @param [boolean] writable (optional, default: false) read-only if false
      @param [boolean] enumerable (optional, default: false) if the property
        should be enumerable in a `for key of object` loop
      
      @return [object] reference to object
       */

      Util.defineValue = function(object, key, value, writable, enumerable) {
        var _ref;
        if (((_ref = get_own_property_descriptor(object, key)) != null ? _ref.writable : void 0) === false) {
          define_property(object, key, {
            writable: true
          });
        }
        return define_property(object, key, {
          configurable: true,
          enumerable: !!enumerable,
          value: value,
          writable: !!writable
        });
      };


      /*
      Helper function that clears Array elements and/or Object properties
      
      @note For arrays it will pop all the elements
      @note For objects it will delete all owned properties
      
      @param [Array|Object] objects... Array and/or Object instance(s) to empty
      
      @return [undefined]
       */

      Util.empty = function() {
        var key, obj, objects, _i, _len;
        objects = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (!objects.length) {
          error.MissingArgument({
            argument: 1
          });
        }
        if (!is_object.apply(this, objects)) {
          error.Type({
            "arguments": objects,
            required: 'All arguments must be objects'
          });
        }
        for (_i = 0, _len = objects.length; _i < _len; _i++) {
          obj = objects[_i];
          if (Array.isArray(obj)) {
            while (Array.prototype.pop.call(obj)) {}
          } else {
            for (key in obj) {
              if (!__hasProp.call(obj, key)) continue;
              delete obj[key];
            }
          }
        }
      };


      /*
      Check if object has own property with provided name and (optionally) if
      it matches enumerability requirement
      
      @param [Object] object target object reference
      @param [string|number] key property name on object
      @param [boolean] is_enumerable (optional) false: should not be enumerable,
        true: must be enumerable
      
      @return [boolean] matched
       */

      Util.hasOwn = function(object, key, is_enumerable) {
        return object && object.hasOwnProperty(key) && ((is_enumerable == null) || is_enumerable === object.propertyIsEnumerable(key));
      };


      /*
      Has own property or property on any if its ancestors.
      
      @param [Object] object target object reference
      @param [string|number] key property name on object
      
      @return [boolean] matched
       */

      Util.hasProperty = function(object, key) {
        while (object) {
          if (object.hasOwnProperty(key)) {
            return true;
          }
          object = get_prototype_of(object);
        }
        return false;
      };


      /*
      Check if compared values are identical or if provided objects have equal
      properties and values.
      
      @param [any type] comparable1
      @param [any type] comparable2
      
      @return [boolean] identical
       */

      Util.identical = function(comparable1, comparable2) {
        var key, v1;
        if (!is_object(comparable1, comparable2)) {
          return comparable1 === comparable2;
        }
        for (key in comparable1) {
          v1 = comparable1[key];
          if (!(Util.identical(v1, comparable2[key]) && has_own(comparable2, key))) {
            return false;
          }
        }
        for (key in comparable2) {
          if (!has_own(comparable1, key)) {
            return false;
          }
        }
        return true;
      };


      /*
      Checks if object property is enumerable
      
      @param [Object] object target object reference
      @param [string|number] key property name on object
      
      @return [boolean] property is enumerable
       */

      Util.isEnumerable = function(object, key) {
        try {
          return !!(get_own_property_descriptor(object, key)).enumerable;
        } catch (_error) {}
        return false;
      };


      /*
      Checks if provided key conforms standards and best practices:
      either a non-empty string or a number (not NaN)
      
      @param [any type] key name/id
      
      @return [boolean] matches key requirements
       */

      Util.isKeyConform = function(key) {
        return !!(typeof key === 'string' && key) || (typeof key === 'number' && !isNaN(key));
      };


      /*
      Checks if refence is or references are all of function type
      
      @param [any type] refs... values to match
      
      @return [boolean] all function
       */

      Util.isFunction = function() {
        var ref, refs, _i, _len;
        refs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        arg_check(refs);
        for (_i = 0, _len = refs.length; _i < _len; _i++) {
          ref = refs[_i];
          if (typeof ref !== 'function') {
            return false;
          }
        }
        return true;
      };


      /*
      Checks if refence is or references are all of object type
      
      @param [any type] refs... values to match
      
      @return [boolean] all object
       */

      Util.isObject = function() {
        var ref, refs, _i, _len;
        refs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        arg_check(refs);
        for (_i = 0, _len = refs.length; _i < _len; _i++) {
          ref = refs[_i];
          if (!ref || typeof ref !== 'object') {
            return false;
          }
        }
        return true;
      };


      /*
      Merge properties from source object(s) to target object
      
      @param [object] target_object object to be updated
      @param [object] source_objects... Source for new properties/overrides to
        be copied onto target_object
      
      @return [object] target_object
       */

      Util.mergeIn = function() {
        var i, key, object, source_objects, target_object, value, _i, _len;
        target_object = arguments[0], source_objects = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        if (source_objects.length < 1) {
          error.MissingArgument({
            required: 'Merged and mergee objects'
          });
        }
        if (!is_object(target_object)) {
          error.Type({
            target_object: target_object,
            argument: 1,
            required: 'object'
          });
        }
        for (i = _i = 0, _len = source_objects.length; _i < _len; i = ++_i) {
          object = source_objects[i];
          if (!is_object(object)) {
            error.Type({
              object: object,
              argument: i + 2,
              required: 'object'
            });
          }
          for (key in object) {
            value = object[key];
            target_object[key] = value;
          }
        }
        return target_object;
      };


      /*
      Get all enumerable properties readable on provided object and all its
      ancestors and turn them into key-value maps where values are arrays with
      object references that own the named property.
      
      @param [Object] object target object reference
      
      @return [object] map with all keys, values are arrays with references to
        property owner objects
       */

      Util.propertyRefs = function(object) {
        var checked, key, properties;
        properties = {};
        while (is_object(object)) {
          checked = true;
          for (key in object) {
            if (!__hasProp.call(object, key)) continue;
            if (!Array.isArray(properties[key])) {
              properties[key] = [];
            }
            properties[key].push(object);
          }
          object = get_prototype_of(object);
        }
        if (!checked) {
          error.ArgumentType({
            object: object,
            argument: 1,
            accepts: 'object'
          });
        }
        return properties;
      };


      /*
      Generate simple numeric unique IDs
      
      For each name (or no name) it starts with 1 and gets incremented by 1 on
      every read
      
      @param [string|number] name (optional) uid group name
      
      @return [number] unique integer ID that is >= 1 and unique within the name
        group
       */

      Util.uid = function(name) {
        var target, uid_store;
        uid_store = (Util._uidStore != null ? Util._uidStore : Util._uidStore = {
          named: {}
        });
        if (name != null) {
          if (!Util.isKeyConform(name)) {
            error.Key({
              name: name,
              requirement: 'Key type name'
            });
          }
          target = uid_store.named;
        } else {
          target = uid_store;
          name = 'unnamed';
        }
        return target[name] = (target[name] || 0) + 1;
      };

      return Util;

    })();
    define_value = Util.defineValue;
    has_own = Util.hasOwn;
    is_object = Util.isObject;
    return Util;
  }
]);
