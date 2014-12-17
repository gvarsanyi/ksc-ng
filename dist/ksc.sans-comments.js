var __hasProp = {}.hasOwnProperty, __bind = function(fn, me) {
    return function() {
        return fn.apply(me, arguments);
    };
}, __extends = function(child, parent) {
    for (var key in parent) {
        if (__hasProp.call(parent, key)) child[key] = parent[key];
    }
    function ctor() {
        this.constructor = child;
    }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.__super__ = parent.prototype;
    return child;
}, __indexOf = [].indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
        if (i in this && this[i] === item) return i;
    }
    return -1;
}, __slice = [].slice;

ksc = angular.module("ksc", []);

ksc.factory("ksc.ArrayTracker", [ "ksc.error", "ksc.util", function(error, util) {
    var ArrayTracker, define_get_set, define_value, has_own, is_array, is_object, plainify, process, set_element;
    define_get_set = util.defineGetSet;
    define_value = util.defineValue;
    has_own = util.hasOwn;
    is_array = Array.isArray;
    is_object = util.isObject;
    ArrayTracker = function() {
        function ArrayTracker(list, options) {
            var fn, fnize, functions, key, orig_fn, store, tracker, _fn, _fn1, _i, _len, _ref;
            if (options == null) {
                options = {};
            }
            if (has_own(list, "_tracker")) {
                error.Value({
                    list: list,
                    description: "List is already tracked"
                });
            }
            if (!is_array(list)) {
                error.ArgumentType({
                    argument: 1,
                    list: list,
                    description: "Must be an array"
                });
            }
            if (!is_object(options)) {
                error.ArgumentType({
                    argument: 2,
                    options: options,
                    description: "Must be an object"
                });
            }
            store = has_own(options, "store") ? options.store : {};
            if (!is_object(store)) {
                error.Type({
                    store: store,
                    description: "Must be an object"
                });
            }
            tracker = this;
            define_value(list, "_tracker", tracker);
            define_value(tracker, "list", list, 0, 1);
            define_value(tracker, "store", store, 0, 1);
            define_value(tracker, "origFn", orig_fn = {});
            fnize = function(fn) {
                if (fn != null) {
                    if (typeof fn !== "function") {
                        error.Type({
                            fn: fn,
                            "Must be a function": "Must be a function"
                        });
                    }
                } else {
                    fn = void 0;
                }
                return fn;
            };
            functions = {};
            _ref = [ "del", "get", "set" ];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                key = _ref[_i];
                functions[key] = options[key] || void 0;
            }
            _fn = function(key) {
                return define_get_set(tracker, key, function() {
                    return functions[key] || void 0;
                }, function(fn) {
                    return functions[key] = fnize(fn);
                }, 1);
            };
            for (key in functions) {
                fn = functions[key];
                functions[key] = fnize(fn);
                _fn(key);
            }
            _fn1 = function(key) {
                return define_value(list, key, function() {
                    var args;
                    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
                    return ArrayTracker["_" + key].apply(tracker, args);
                });
            };
            for (key in ArrayTracker) {
                fn = ArrayTracker[key];
                if (!(key.substr(0, 1) === "_")) {
                    continue;
                }
                key = key.substr(1);
                orig_fn[key] = has_own(list, key) ? {
                    v: list[key]
                } : {
                    n: 1
                };
                _fn1(key);
            }
            process(tracker);
        }
        ArrayTracker.prototype.unload = function(keep_store_values) {
            var inf, key, list, store, tracker, _ref, _ref1;
            _ref = tracker = this, list = _ref.list, store = _ref.store;
            plainify(tracker);
            _ref1 = tracker.origFn;
            for (key in _ref1) {
                inf = _ref1[key];
                if (inf.n) {
                    delete list[key];
                } else {
                    define_value(list, key, inf.v);
                }
            }
            delete tracker.list._tracker;
            delete tracker.list;
            if (!keep_store_values) {
                util.empty(store);
            }
        };
        ArrayTracker.add = function(tracker, items, index, move_to_right) {
            var i, items_len, list, orig_len, record, store, value, _i, _j, _len, _ref;
            if (move_to_right == null) {
                move_to_right = true;
            }
            list = tracker.list, store = tracker.store;
            items_len = items.length;
            orig_len = list.length;
            if (move_to_right && orig_len > index) {
                for (i = _i = _ref = orig_len - 1; _i >= index; i = _i += -1) {
                    record = store[i];
                    store[i] = void 0;
                    set_element(tracker, i + items_len, record, "move");
                }
            }
            for (i = _j = 0, _len = items.length; _j < _len; i = ++_j) {
                value = items[i];
                set_element(tracker, i + index, value);
                if (move_to_right) {
                    ArrayTracker.getterify(tracker, i + orig_len);
                }
            }
            return list.length;
        };
        ArrayTracker.getElement = function(tracker, index) {
            if (tracker.get) {
                return tracker.get(index, tracker.store[index]);
            }
            return tracker.store[index];
        };
        ArrayTracker.getterify = function(tracker, index) {
            define_get_set(tracker.list, index, function() {
                return ArrayTracker.getElement(tracker, index);
            }, function(val) {
                return set_element(tracker, index, val);
            }, 1);
        };
        ArrayTracker.plainify = function(tracker) {
            var copy, i, list, store;
            list = tracker.list, store = tracker.store;
            copy = function() {
                var _i, _ref, _results;
                _results = [];
                for (i = _i = 0, _ref = list.length; _i < _ref; i = _i += 1) {
                    _results.push(store[i]);
                }
                return _results;
            }();
            list.length = 0;
            Array.prototype.push.apply(list, copy);
        };
        ArrayTracker.process = function(tracker, set_type) {
            var index, value, _i, _len, _ref;
            _ref = tracker.list;
            for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
                value = _ref[index];
                ArrayTracker.getterify(tracker, index);
                set_element(tracker, index, value, set_type);
            }
        };
        ArrayTracker.rm = function(tracker, index) {
            var del, deletable, i, list, orig_len, record, res, store, _i, _ref;
            list = tracker.list, store = tracker.store;
            if (list.length) {
                orig_len = list.length;
                res = list[index];
                if (del = tracker.del) {
                    deletable = store[orig_len - 1];
                }
                for (i = _i = _ref = index + 1; _i < orig_len; i = _i += 1) {
                    record = store[i];
                    store[i] = void 0;
                    set_element(tracker, i - 1, record, "move");
                }
                list.length = orig_len - 1;
                if ((typeof del === "function" ? del(orig_len - 1, deletable) : void 0) !== false) {
                    delete store[orig_len - 1];
                }
                return res;
            }
        };
        ArrayTracker.setElement = function(tracker, index, value, set_type) {
            var store, work;
            work = function() {
                if (arguments.length) {
                    value = arguments[0];
                }
                if (store[index] === value) {
                    return false;
                }
                store[index] = value;
                return true;
            };
            store = tracker.store;
            if (tracker.set) {
                tracker.set(index, value, work, set_type || "external");
            } else {
                work();
            }
        };
        ArrayTracker._pop = function() {
            return ArrayTracker.rm(this, this.list.length - 1);
        };
        ArrayTracker._shift = function() {
            return ArrayTracker.rm(this, 0);
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
            var how_many, i, index, items, items_len, list, move, orig_len, res, store, tracker, _i, _j, _k, _l, _ref, _ref1, _ref2, _ref3, _ref4;
            index = arguments[0], how_many = arguments[1], items = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
            _ref = tracker = this, list = _ref.list, store = _ref.store;
            items_len = items.length;
            orig_len = list.length;
            index = parseInt(index, 10) || 0;
            if (index < 0) {
                index = Math.max(0, orig_len + index);
            } else {
                index = Math.min(index, orig_len);
            }
            how_many = parseInt(how_many, 10) || 0;
            how_many = Math.max(0, Math.min(how_many, orig_len - index));
            res = list.slice(index, index + how_many);
            move = function(i, to_right) {
                var record;
                record = store[i];
                if (to_right) {
                    store[i] = void 0;
                }
                return set_element(tracker, i - how_many + items_len, record, "move");
            };
            if (how_many > items_len) {
                for (i = _i = _ref1 = index + how_many; _i < orig_len; i = _i += 1) {
                    move(i);
                }
                for (i = _j = 0, _ref2 = how_many - items_len; _j < _ref2; i = _j += 1) {
                    ArrayTracker.rm(tracker, orig_len - i - 1);
                }
            } else if (how_many < items_len) {
                for (i = _k = _ref3 = orig_len - 1, _ref4 = index + how_many; _k >= _ref4; i = _k += -1) {
                    move(i, 1);
                }
            }
            if (items_len) {
                for (i = _l = how_many; _l < items_len; i = _l += 1) {
                    ArrayTracker.getterify(tracker, i + orig_len);
                }
                ArrayTracker.add(tracker, items, index, 0);
            }
            return res;
        };
        ArrayTracker._sort = function(fn) {
            var res, tracker;
            tracker = this;
            plainify(tracker);
            res = Array.prototype.sort.call(tracker.list, fn);
            process(tracker, "reload");
            return res;
        };
        ArrayTracker._reverse = function() {
            var res, tracker;
            tracker = this;
            plainify(tracker);
            res = Array.prototype.reverse.call(tracker.list);
            process(tracker, "reload");
            return res;
        };
        return ArrayTracker;
    }();
    plainify = ArrayTracker.plainify;
    process = ArrayTracker.process;
    set_element = ArrayTracker.setElement;
    return ArrayTracker;
} ]);

ksc.service("ksc.batchLoaderRegistry", [ "ksc.error", function(error) {
    var BatchLoaderRegistry;
    BatchLoaderRegistry = function() {
        function BatchLoaderRegistry() {}
        BatchLoaderRegistry.prototype.map = {};
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
        BatchLoaderRegistry.prototype.register = function(loader) {
            var endpoint;
            if (!(typeof (endpoint = loader != null ? loader.endpoint : void 0) === "string" && endpoint)) {
                error.Value({
                    endpoint: endpoint,
                    required: "url"
                });
            }
            if (this.map[endpoint]) {
                error.Value({
                    endpoint: endpoint,
                    description: "already registered"
                });
            }
            return this.map[endpoint] = loader;
        };
        BatchLoaderRegistry.prototype.unregister = function(loader) {
            if (!this.map[loader.endpoint]) {
                return false;
            }
            return delete this.map[loader.endpoint];
        };
        return BatchLoaderRegistry;
    }();
    return new BatchLoaderRegistry();
} ]);

ksc.factory("ksc.BatchLoader", [ "$http", "$q", "ksc.batchLoaderRegistry", "ksc.error", "ksc.util", function($http, $q, batchLoaderRegistry, error, util) {
    var BatchLoader, argument_type_error, is_object;
    argument_type_error = error.ArgumentType;
    is_object = util.isObject;
    return BatchLoader = function() {
        function BatchLoader(endpoint, map) {
            var key, loader, open, setter, url;
            this.endpoint = endpoint;
            this.map = map;
            loader = this;
            if (!(endpoint && typeof endpoint === "string")) {
                argument_type_error({
                    endpoint: endpoint,
                    required: "string"
                });
            }
            if (!is_object(map)) {
                argument_type_error({
                    map: map,
                    required: "object"
                });
            }
            for (key in map) {
                url = map[key];
                if (typeof url !== "string" || !key) {
                    error.Type({
                        key: key,
                        url: url,
                        required: "url string"
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
            util.defineGetSet(loader, "open", function() {
                return open;
            }, setter, 1);
            util.defineValue(loader, "requests", [], 0, 1);
            batchLoaderRegistry.register(loader);
        }
        BatchLoader.prototype.get = function(url, query_parameters) {
            var deferred, key, loader, matched_key, requests, value, _ref;
            loader = this;
            requests = loader.requests;
            if (!(url && typeof url === "string")) {
                argument_type_error({
                    url: url,
                    required: "string"
                });
            }
            if (query_parameters != null && !is_object(query_parameters)) {
                argument_type_error({
                    query_parameters: query_parameters,
                    required: "object"
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
                    if (200 <= (_ref = res.status) && _ref < 400) {
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
    }();
} ]);

ksc.factory("ksc.EditableRecord", [ "ksc.Record", "ksc.error", "ksc.util", function(Record, error, util) {
    var EditableRecord, define_value, has_own, is_array, is_enumerable, is_object, _ARRAY, _CHANGED_KEYS, _CHANGES, _DELETED_KEYS, _EDITED, _EVENTS, _OPTIONS, _PARENT, _PARENT_KEY, _SAVED;
    _ARRAY = "_array";
    _CHANGES = "_changes";
    _CHANGED_KEYS = "_changedKeys";
    _DELETED_KEYS = "_deletedKeys";
    _EDITED = "_edited";
    _EVENTS = "_events";
    _OPTIONS = "_options";
    _PARENT = "_parent";
    _PARENT_KEY = "_parentKey";
    _SAVED = "_saved";
    define_value = util.defineValue;
    has_own = util.hasOwn;
    is_array = Array.isArray;
    is_enumerable = util.isEnumerable;
    is_object = util.isObject;
    return EditableRecord = function(_super) {
        __extends(EditableRecord, _super);
        EditableRecord.prototype._changes = 0;
        function EditableRecord(data, options, parent, parent_key) {
            var record;
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
                    required: "object"
                });
            }
            options.subtreeClass = EditableRecord;
            record = this;
            define_value(record, _EDITED, {});
            define_value(record, _CHANGES, 0);
            define_value(record, _CHANGED_KEYS, {});
            define_value(record, _DELETED_KEYS, {});
            define_value(record, _SAVED, {});
            EditableRecord.__super__.constructor.call(this, data, options, parent, parent_key);
        }
        EditableRecord.prototype._clone = function(return_plain_object, exclude_static, saved_only) {
            var clone, key, record, value, _ref;
            record = this;
            clone = EditableRecord.__super__._clone.call(this, return_plain_object, exclude_static);
            if (!saved_only) {
                _ref = record[_EDITED];
                for (key in _ref) {
                    value = _ref[key];
                    if (value != null ? value._clone : void 0) {
                        value = value._clone(return_plain_object, exclude_static);
                    }
                    if (return_plain_object) {
                        clone[key] = value;
                    } else {
                        clone._setProperty(key, value);
                    }
                }
                for (key in record[_DELETED_KEYS]) {
                    if (return_plain_object) {
                        delete clone[key];
                    } else {
                        clone._delete(key);
                    }
                }
            }
            if (!(return_plain_object || exclude_static)) {
                Record.getAllStatic(record, clone);
            }
            return clone;
        };
        EditableRecord.prototype._delete = function() {
            var changed, contract, i, id_property, key, keys, record, _i, _len;
            keys = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            if (!keys.length) {
                error.MissingArgument({
                    name: "key",
                    argument: 1
                });
            }
            record = this;
            changed = [];
            for (i = _i = 0, _len = keys.length; _i < _len; i = ++_i) {
                key = keys[i];
                util.isKeyConform(key, 1, i);
                if (!i && (contract = record[_OPTIONS].contract)) {
                    error.ContractBreak({
                        key: key,
                        value: value,
                        contract: contract[key]
                    });
                }
                if ((id_property = record._idProperty) === key || is_array(id_property) && __indexOf.call(id_property, key) >= 0) {
                    error.Permission({
                        key: key,
                        description: "idProperty keys can not be deleted"
                    });
                }
                if (has_own(record[_SAVED], key)) {
                    if (record[_DELETED_KEYS][key]) {
                        continue;
                    }
                    record[_DELETED_KEYS][key] = true;
                    if (!record[_CHANGED_KEYS][key]) {
                        define_value(record, _CHANGES, record[_CHANGES] + 1);
                        define_value(record[_CHANGED_KEYS], key, true, 0, 1);
                    }
                    delete record[_EDITED][key];
                    Object.defineProperty(record, key, {
                        enumerable: false
                    });
                    changed.push(key);
                } else if (has_own(record, key)) {
                    if (!is_enumerable(record, key)) {
                        error.Key({
                            key: key,
                            description: "can not be changed"
                        });
                    }
                    delete record[key];
                    if (record[_EDITED][key]) {
                        delete record[_EDITED][key];
                        define_value(record, _CHANGES, record[_CHANGES] - 1);
                        delete record[_CHANGED_KEYS][key];
                    }
                    changed.push(key);
                }
            }
            if (changed.length) {
                Record.emitUpdate(record, "delete", {
                    keys: changed
                });
            }
            return !!changed.length;
        };
        EditableRecord.prototype._getProperty = function(key) {
            var record, value;
            record = this;
            value = EditableRecord.__super__._getProperty.apply(this, arguments);
            if (record[_DELETED_KEYS][key]) {
                return;
            } else if (has_own(record[_EDITED], key)) {
                return Record.arrayFilter(record[_EDITED][key]);
            }
            return value;
        };
        EditableRecord.prototype._replace = function(data) {
            var changed, dropped, events, record;
            record = this;
            if (events = record[_EVENTS]) {
                events.halt();
            }
            try {
                dropped = record._revert(0);
                changed = EditableRecord.__super__._replace.call(this, data, 0);
            } finally {
                if (events) {
                    events.unhalt();
                }
            }
            if (events && (dropped || changed)) {
                Record.emitUpdate(record, "replace");
            }
            return dropped || changed;
        };
        EditableRecord.prototype._revert = function(emit_event) {
            var changed, key, record;
            if (emit_event == null) {
                emit_event = true;
            }
            changed = false;
            record = this;
            for (key in record[_DELETED_KEYS]) {
                delete record[_DELETED_KEYS][key];
                delete record[_CHANGED_KEYS][key];
                changed = true;
            }
            for (key in record[_EDITED]) {
                delete record[_EDITED][key];
                delete record[_CHANGED_KEYS][key];
                changed = true;
            }
            if (changed) {
                define_value(record, _CHANGES, 0);
                if (emit_event) {
                    Record.emitUpdate(record, "revert");
                }
            }
            return changed;
        };
        EditableRecord.prototype._setProperty = function(key, value, initial) {
            var arr, changed, contract, delete_unmatched_keys, edited, i, id_property, item, k, record, res, saved, saved_arr, v, was_changed, _i, _j, _len, _ref, _ref1, _ref2, _ref3, _ref4;
            if (initial) {
                return EditableRecord.__super__._setProperty.apply(this, arguments);
            }
            record = this;
            saved = record[_SAVED];
            edited = record[_EDITED];
            contract = record[_OPTIONS].contract;
            Record.valueCheck(record, key, value);
            if ((id_property = record._idProperty) === key || is_array(id_property) && __indexOf.call(id_property, key) >= 0) {
                if (!(value === null || ((_ref = typeof value) === "string" || _ref === "number"))) {
                    error.Value({
                        value: value,
                        required: "string or number or null"
                    });
                }
            }
            value = Record.valueWrap(record, key, value);
            if (util.identical(saved[key], value)) {
                delete edited[key];
                changed = 1;
            } else if (!util.identical(edited[key], value)) {
                if (contract != null) {
                    contract._match(key, value);
                }
                res = value;
                delete_unmatched_keys = function() {
                    var k;
                    for (k in res) {
                        if (is_enumerable(res, k) && !has_own(value, k)) {
                            res._delete(k);
                        }
                    }
                };
                if (arr = value != null ? value[_ARRAY] : void 0) {
                    if (is_object(saved[key])) {
                        res = saved[key];
                        if (saved_arr = res[_ARRAY]) {
                            for (i = _i = _ref1 = arr.length, _ref2 = saved_arr.length; _i < _ref2; i = _i += 1) {
                                saved_arr.pop();
                            }
                            _ref3 = arr.slice(0, saved_arr.length);
                            for (i = _j = 0, _len = _ref3.length; _j < _len; i = ++_j) {
                                item = _ref3[i];
                                saved_arr[i] = item;
                            }
                            saved_arr.push.apply(saved_arr, arr.slice(saved_arr.length));
                        } else {
                            delete_unmatched_keys();
                            Record.arrayify(res);
                            (_ref4 = res[_ARRAY]).push.apply(_ref4, arr);
                        }
                    }
                } else if (is_object(value)) {
                    if (is_object(saved[key])) {
                        res = saved[key];
                        if (res[_ARRAY]) {
                            Record.dearrayify(res);
                        }
                        delete_unmatched_keys();
                        for (k in value) {
                            v = value[k];
                            res._setProperty(k, v);
                        }
                    }
                }
                edited[key] = res;
                changed = 1;
            }
            if (record[_DELETED_KEYS][key]) {
                delete record[_DELETED_KEYS][key];
                changed = 1;
            }
            if (edited[key] === saved[key]) {
                delete edited[key];
            }
            was_changed = record[_CHANGED_KEYS][key];
            if (is_object(saved[key]) && saved[key]._changes || has_own(edited, key) && !util.identical(saved[key], edited[key])) {
                if (!was_changed) {
                    define_value(record, _CHANGES, record[_CHANGES] + 1);
                    define_value(record[_CHANGED_KEYS], key, true, 0, 1);
                }
            } else if (was_changed) {
                define_value(record, _CHANGES, record[_CHANGES] - 1);
                delete record[_CHANGED_KEYS][key];
            }
            Record.getterify(record, key);
            if (changed) {
                if (record[_PARENT_KEY]) {
                    EditableRecord.subChanges(record[_PARENT], record[_PARENT_KEY], record[_CHANGES]);
                }
                Object.defineProperty(record, key, {
                    enumerable: true
                });
                Record.emitUpdate(record, "set", {
                    key: key
                });
            }
            return !!changed;
        };
        EditableRecord.subChanges = function(record, key, n) {
            var changed;
            if (record[_CHANGED_KEYS][key]) {
                if (!n) {
                    define_value(record, _CHANGES, record[_CHANGES] - 1);
                    delete record[_CHANGED_KEYS][key];
                    changed = true;
                }
            } else if (n) {
                define_value(record, _CHANGES, record[_CHANGES] + 1);
                define_value(record[_CHANGED_KEYS], key, true, 0, 1);
                changed = true;
            }
            if (changed && record[_PARENT_KEY]) {
                EditableRecord.subChanges(record[_PARENT], record[_PARENT_KEY], record[_CHANGES]);
            }
        };
        return EditableRecord;
    }(Record);
} ]);

ksc.factory("ksc.EditableRestRecord", [ "$http", "ksc.EditableRecord", "ksc.Mixin", "ksc.RestRecord", function($http, EditableRecord, Mixin, RestRecord) {
    var EditableRestRecord;
    return EditableRestRecord = function(_super) {
        __extends(EditableRestRecord, _super);
        function EditableRestRecord() {
            return EditableRestRecord.__super__.constructor.apply(this, arguments);
        }
        Mixin.extend(EditableRestRecord, RestRecord);
        EditableRestRecord.prototype._restSave = function(callback) {
            var url;
            url = EditableRestRecord.getUrl(this);
            return EditableRestRecord.async(this, $http.put(url, this._entity()), callback);
        };
        return EditableRestRecord;
    }(EditableRecord);
} ]);

ksc.service("ksc.error", function() {
    var ArgumentTypeError, ContractBreakError, CustomError, ErrorTypes, HttpError, KeyError, MissingArgumentError, PermissionError, TypeError, ValueError, class_ref, error, name, _fn;
    CustomError = function(_super) {
        __extends(CustomError, _super);
        function CustomError(options) {
            var key, msg, value;
            msg = "";
            if (options && typeof options === "object") {
                for (key in options) {
                    value = options[key];
                    try {
                        value = JSON.stringify(value, null, 2);
                    } catch (_error) {
                        value = String(value);
                    }
                    msg += "\n  " + key + ": " + value;
                }
            } else if (options != null) {
                msg += String(options);
            }
            this.message = msg;
        }
        return CustomError;
    }(Error);
    ArgumentTypeError = function(_super) {
        __extends(ArgumentTypeError, _super);
        function ArgumentTypeError() {
            return ArgumentTypeError.__super__.constructor.apply(this, arguments);
        }
        return ArgumentTypeError;
    }(CustomError);
    ContractBreakError = function(_super) {
        __extends(ContractBreakError, _super);
        function ContractBreakError() {
            return ContractBreakError.__super__.constructor.apply(this, arguments);
        }
        return ContractBreakError;
    }(CustomError);
    HttpError = function(_super) {
        __extends(HttpError, _super);
        function HttpError() {
            return HttpError.__super__.constructor.apply(this, arguments);
        }
        return HttpError;
    }(CustomError);
    KeyError = function(_super) {
        __extends(KeyError, _super);
        function KeyError() {
            return KeyError.__super__.constructor.apply(this, arguments);
        }
        return KeyError;
    }(CustomError);
    MissingArgumentError = function(_super) {
        __extends(MissingArgumentError, _super);
        function MissingArgumentError() {
            return MissingArgumentError.__super__.constructor.apply(this, arguments);
        }
        return MissingArgumentError;
    }(CustomError);
    PermissionError = function(_super) {
        __extends(PermissionError, _super);
        function PermissionError() {
            return PermissionError.__super__.constructor.apply(this, arguments);
        }
        return PermissionError;
    }(CustomError);
    TypeError = function(_super) {
        __extends(TypeError, _super);
        function TypeError() {
            return TypeError.__super__.constructor.apply(this, arguments);
        }
        return TypeError;
    }(CustomError);
    ValueError = function(_super) {
        __extends(ValueError, _super);
        function ValueError() {
            return ValueError.__super__.constructor.apply(this, arguments);
        }
        return ValueError;
    }(CustomError);
    ErrorTypes = function() {
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
    }();
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
        class_ref.prototype.name = name + "Error";
        _fn(class_ref);
    }
    return error;
});

ksc.factory("ksc.EventEmitter", [ "$interval", "$rootScope", "$timeout", "ksc.error", "ksc.util", function($interval, $rootScope, $timeout, error, util) {
    var EventEmitter, EventSubscriptions, UNSUBSCRIBER, argument_type_error, is_function, is_object, name_check, subscription_decorator;
    UNSUBSCRIBER = "__unsubscriber__";
    argument_type_error = error.ArgumentType;
    is_function = util.isFunction;
    is_object = util.isObject;
    EventSubscriptions = function() {
        function EventSubscriptions() {}
        EventSubscriptions.prototype.emit = function() {
            var args, block, callback, callback_found, id, name, names, once, _i, _len, _ref, _ref1;
            name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
            names = this.names != null ? this.names : this.names = {};
            block = names[name] != null ? names[name] : names[name] = {};
            callback_found = false;
            block.fired = (block.fired || 0) + 1;
            block.lastArgs = args;
            _ref = [ 0, 1 ];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                once = _ref[_i];
                if (block[once]) {
                    _ref1 = block[once];
                    for (id in _ref1) {
                        callback = _ref1[id];
                        if (!is_function(callback)) {
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
        EventSubscriptions.prototype.instantCall = function(name, callback) {
            var names, _ref;
            names = this.names != null ? this.names : this.names = {};
            if ((_ref = names[name]) != null ? _ref.fired : void 0) {
                callback.apply(null, names[name].lastArgs);
                return true;
            }
            return false;
        };
        EventSubscriptions.prototype.push = function(names, once, callback) {
            var block, fn, ids, name, pseudo_unsubscriber, subscription_names, unsubscribed, _base, _i, _len;
            subscription_names = this.names != null ? this.names : this.names = {};
            ids = [];
            once = once ? 1 : 0;
            for (_i = 0, _len = names.length; _i < _len; _i++) {
                name = names[_i];
                if (subscription_names[name] == null) {
                    subscription_names[name] = {};
                }
                block = (_base = subscription_names[name])[once] != null ? _base[once] : _base[once] = {
                    i: 0
                };
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
    }();
    name_check = function(name) {
        if (typeof name !== "string") {
            argument_type_error({
                name: name,
                argument: 1,
                required: "string"
            });
        }
        if (!name) {
            return error.Value({
                name: name,
                description: "must be a non-empty string"
            });
        }
    };
    subscription_decorator = function(names, unsubscribe_target, callback, next) {
        var name, scope, unsubscriber_fn, _i, _len;
        if (this.subscriptions == null) {
            this.subscriptions = new EventSubscriptions();
        }
        if (!is_function(callback)) {
            argument_type_error({
                callback: callback,
                argument: "last",
                required: "function"
            });
        }
        if (!((unsubscribe_target != null ? unsubscribe_target[UNSUBSCRIBER] : void 0) || is_object(unsubscribe_target) && (scope = $rootScope.isPrototypeOf(unsubscribe_target)))) {
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
                unsubscribe_target.$on("$destroy", unsubscriber_fn);
            } else {
                unsubscribe_target.add(unsubscriber_fn);
            }
            return true;
        }
        return unsubscriber_fn;
    };
    return EventEmitter = function() {
        function EventEmitter() {
            this.on = __bind(this.on, this);
            this.on1 = __bind(this.on1, this);
            this["if"] = __bind(this["if"], this);
            this.if1 = __bind(this.if1, this);
        }
        EventEmitter.prototype.emit = function() {
            var args, name, _ref;
            name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
            name_check(name);
            if (this._halt) {
                name = this._halt + "#!" + name;
            }
            return (_ref = this.subscriptions != null ? this.subscriptions : this.subscriptions = new EventSubscriptions()).emit.apply(_ref, [ name ].concat(__slice.call(args)));
        };
        EventEmitter.prototype.emitted = function(name) {
            var subscriptions, _ref, _ref1;
            name_check(name);
            if ((_ref = subscriptions = (_ref1 = this.subscriptions) != null ? _ref1.names[name] : void 0) != null ? _ref.fired : void 0) {
                return subscriptions.lastArgs;
            }
            return false;
        };
        EventEmitter.prototype.halt = function() {
            return this._halt = (this._halt || 0) + 1;
        };
        EventEmitter.prototype.unhalt = function() {
            return this._halt -= 1;
        };
        EventEmitter.prototype.if1 = function() {
            var callback, names, unsubscribe_target, _i;
            names = 3 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 2) : (_i = 0, 
            []), unsubscribe_target = arguments[_i++], callback = arguments[_i++];
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
        EventEmitter.prototype["if"] = function() {
            var callback, names, unsubscribe_target, _i;
            names = 3 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 2) : (_i = 0, 
            []), unsubscribe_target = arguments[_i++], callback = arguments[_i++];
            return subscription_decorator.call(this, names, unsubscribe_target, callback, function() {
                var name, _j, _len;
                for (_j = 0, _len = names.length; _j < _len; _j++) {
                    name = names[_j];
                    this.subscriptions.instantCall(name, callback);
                }
                return this.subscriptions.push(names, 0, callback);
            });
        };
        EventEmitter.prototype.on1 = function() {
            var callback, names, unsubscribe_target, _i;
            names = 3 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 2) : (_i = 0, 
            []), unsubscribe_target = arguments[_i++], callback = arguments[_i++];
            return subscription_decorator.call(this, names, unsubscribe_target, callback, function() {
                return this.subscriptions.push(names, 1, callback);
            });
        };
        EventEmitter.prototype.on = function() {
            var callback, names, unsubscribe_target, _i;
            names = 3 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 2) : (_i = 0, 
            []), unsubscribe_target = arguments[_i++], callback = arguments[_i++];
            return subscription_decorator.call(this, names, unsubscribe_target, callback, function() {
                return this.subscriptions.push(names, 0, callback);
            });
        };
        EventEmitter.prototype.unsubscriber = function(scope) {
            var attached, fn, increment;
            attached = {};
            increment = 0;
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
                        required: "$rootScope descendant"
                    });
                }
                scope.$on("$destroy", fn);
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
                            required: [ "function", "Promise" ]
                        });
                    };
                    if (is_object(unsubscriber)) {
                        if (unsubscriber.$$timeoutId != null && unsubscriber["finally"] != null) {
                            unsubscriber["finally"](del);
                        } else if (unsubscriber.$$intervalId != null && unsubscriber["finally"] != null) {
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
    }();
} ]);

ksc.factory("ksc.ListMapper", [ "ksc.util", function(util) {
    var ListMapper, define_value;
    define_value = util.defineValue;
    return ListMapper = function() {
        function ListMapper(parent) {
            var build_maps, has_mapped_source, mapped, mapper, source;
            this.parent = parent;
            mapper = this;
            source = parent.source;
            define_value(mapper, "multi", source && !source._, 0, 1);
            define_value(mapper, "_sources", [], 0, 1);
            has_mapped_source = function(target) {
                var k, ref, _ref;
                if (target.source) {
                    _ref = target.source;
                    for (k in _ref) {
                        ref = _ref[k];
                        if (has_mapped_source(ref)) {
                            return true;
                        }
                    }
                    return false;
                }
                return target.idProperty != null;
            };
            if (mapped = has_mapped_source(parent)) {
                define_value(mapper, "idMap", {}, 0, 1);
                define_value(mapper, "pseudoMap", {}, 0, 1);
            }
            build_maps = function(parent, target_map, target_pseudo, names) {
                var item, source_list, source_name, src, subnames, _results;
                if (target_map == null) {
                    target_map = {};
                }
                if (target_pseudo == null) {
                    target_pseudo = {};
                }
                if (src = parent.source) {
                    if (src._) {
                        return build_maps(src._, target_map, target_pseudo, names);
                    } else {
                        _results = [];
                        for (source_name in src) {
                            source_list = src[source_name];
                            if (mapped && has_mapped_source(parent)) {
                                target_map[source_name] = {};
                                target_pseudo[source_name] = {};
                            }
                            subnames = function() {
                                var _i, _len, _results1;
                                _results1 = [];
                                for (_i = 0, _len = names.length; _i < _len; _i++) {
                                    item = names[_i];
                                    _results1.push(item);
                                }
                                return _results1;
                            }();
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
            build_maps(parent, mapper.idMap, mapper.pseudoMap, []);
            Object.freeze(mapper._sources);
        }
        ListMapper.prototype.add = function(record, source_names) {
            var id, mapper, target;
            mapper = this;
            if (record._id != null) {
                id = record._id;
                target = mapper.idMap;
            } else {
                id = record._pseudo;
                target = mapper.pseudoMap;
            }
            target = ListMapper.deepTarget(target, source_names);
            util.defineGetSet(target, id, function() {
                return record;
            }, function(value) {
                return record._replace(value);
            }, 1);
            return record;
        };
        ListMapper.prototype.del = function(map_id, pseudo_id, source_names) {
            var mapper, target;
            mapper = this;
            if (util.isObject(map_id)) {
                pseudo_id = map_id._pseudo;
                map_id = map_id._id;
            }
            if (pseudo_id != null) {
                target = mapper.pseudoMap;
                map_id = pseudo_id;
            } else {
                target = mapper.idMap;
            }
            target = ListMapper.deepTarget(target, source_names);
            delete target[map_id];
        };
        ListMapper.prototype.has = function(map_id, pseudo_id, source_names) {
            var id, mapper, target;
            mapper = this;
            if (util.isObject(map_id)) {
                pseudo_id = map_id._pseudo;
                map_id = map_id._id;
            }
            if (pseudo_id != null) {
                id = pseudo_id;
                target = mapper.parent.pseudoMap;
            } else {
                id = map_id;
                target = mapper.parent.idMap;
            }
            target = ListMapper.deepTarget(target, source_names);
            return target[id] || false;
        };
        ListMapper.deepTarget = function(target, source_names) {
            var source_name, _i, _len;
            if (source_names) {
                for (_i = 0, _len = source_names.length; _i < _len; _i++) {
                    source_name = source_names[_i];
                    target = target[source_name];
                }
            }
            return target;
        };
        ListMapper.register = function(list) {
            var mapper;
            mapper = new ListMapper(list);
            define_value(list, "_mapper", mapper);
            if (mapper.idMap) {
                define_value(list, "idMap", mapper.idMap);
                define_value(list, "pseudoMap", mapper.pseudoMap);
            }
        };
        return ListMapper;
    }();
} ]);

ksc.factory("ksc.ListMask", [ "$rootScope", "ksc.ArrayTracker", "ksc.EventEmitter", "ksc.List", "ksc.ListMapper", "ksc.ListSorter", "ksc.Record", "ksc.error", "ksc.util", function($rootScope, ArrayTracker, EventEmitter, List, ListMapper, ListSorter, Record, error, util) {
    var ListMask, SCOPE_UNSUBSCRIBER, argument_type_error, define_get_set, define_value, is_object;
    SCOPE_UNSUBSCRIBER = "_scopeUnsubscriber";
    argument_type_error = error.ArgumentType;
    define_get_set = util.defineGetSet;
    define_value = util.defineValue;
    is_object = util.isObject;
    return ListMask = function() {
        function ListMask(source, filter, options, scope) {
            var flat_sources, key, list, record, source_count, source_info, source_list, source_name, sources, unsubscriber, value, _fn, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2, _ref3;
            if (source instanceof Array || typeof source !== "object") {
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
                        required: "List"
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
                    required: "object"
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
                        required: "$rootScope descendant"
                    });
                }
            }
            if (filter) {
                options.filter = filter;
            }
            list = [];
            new ArrayTracker(list, {
                set: function(index, value, next, set_type) {
                    var record;
                    if (set_type === "external" && (record = list._tracker.store[index]) instanceof Record) {
                        record._replace(value);
                    } else {
                        next();
                    }
                }
            });
            define_value(list, "_origFn", {});
            _ref = this.constructor.prototype;
            for (key in _ref) {
                value = _ref[key];
                if (value != null && key !== "constructor") {
                    list._origFn[key] = list[key];
                    define_value(list, key, value);
                }
            }
            _ref1 = [ "pop", "push", "reverse", "shift", "sort", "splice", "unshift" ];
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
                key = _ref1[_i];
                list._origFn[key] = list[key];
                define_value(list, key);
            }
            define_value(list, "events", new EventEmitter());
            define_value(list, "options", options);
            define_value(list, "source", source);
            ListMask.registerFilter(list);
            ListMask.registerSplitter(list);
            ListMapper.register(list);
            sources = list._mapper._sources;
            if (scope) {
                define_value(list, SCOPE_UNSUBSCRIBER, scope.$on("$destroy", function() {
                    delete list[SCOPE_UNSUBSCRIBER];
                    return list.destroy();
                }));
            }
            unsubscriber = null;
            flat_sources = [];
            _fn = function(source_info) {
                var unsub;
                unsub = source_info.source.events.on("update", function(info) {
                    return ListMask.update.call(list, info, source_info.names);
                });
                if (unsubscriber) {
                    unsubscriber.add(unsub);
                } else {
                    unsubscriber = unsub;
                }
                return unsubscriber.add(source_info.source.events.on("destroy", function() {
                    return list.destroy();
                }));
            };
            for (_j = 0, _len1 = sources.length; _j < _len1; _j++) {
                source_info = sources[_j];
                if (_ref2 = source_info.source, __indexOf.call(flat_sources, _ref2) >= 0) {
                    error.Value({
                        sources: sources,
                        conflict: "Source can not be referenced twice to keep list unique"
                    });
                }
                flat_sources.push(source_info.source);
                _fn(source_info);
            }
            define_value(list, "_sourceUnsubscriber", unsubscriber);
            ListSorter.register(list, options.sorter);
            for (_k = 0, _len2 = sources.length; _k < _len2; _k++) {
                source_info = sources[_k];
                _ref3 = source_info.source;
                for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
                    record = _ref3[_l];
                    if (!list.filter(record)) {
                        continue;
                    }
                    if (record._parent.idProperty != null) {
                        list._mapper.add(record, source_info.names);
                    }
                    ListMask.add(list, record);
                }
            }
            return list;
        }
        ListMask.prototype.destroy = function() {
            return List.prototype.destroy.call(this);
        };
        ListMask.prototype.update = function() {
            var action, is_on, list, mapped, mapper, record, source_info, source_names, _i, _j, _len, _len1, _ref, _ref1;
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
                    if (mapped = record._parent.idProperty) {
                        is_on = mapper.has(record, null, source_names);
                    } else {
                        is_on = __indexOf.call(list, record) >= 0;
                    }
                    if (list.filter(record)) {
                        if (!is_on) {
                            if (mapped) {
                                mapper.add(record, source_names);
                            }
                            ListMask.add(list, record);
                            (action.add != null ? action.add : action.add = []).push(record);
                        }
                    } else if (is_on) {
                        if (mapped) {
                            mapper.del(record, null, source_names);
                        }
                        (action.cut != null ? action.cut : action.cut = []).push(record);
                    }
                }
            }
            if (action.cut) {
                ListMask.cut(list, action.cut);
            }
            ListMask.rebuild(list);
            if (action.add || action.cut) {
                list.events.emit("update", {
                    node: list,
                    action: action
                });
            }
            return action;
        };
        ListMask.add = function(list, record) {
            var item, pos, records, _i, _len;
            records = ListMask.splitterWrap(list, record);
            if (list.sorter) {
                for (_i = 0, _len = records.length; _i < _len; _i++) {
                    item = records[_i];
                    pos = list.sorter.position(item);
                    list._origFn.splice.call(list, pos, 0, item);
                }
            } else {
                list._origFn.push.apply(list, records);
            }
        };
        ListMask.cut = function(list, records) {
            var record, target, tmp_container;
            tmp_container = [];
            while (record = list._origFn.pop()) {
                target = record._original || record;
                if (__indexOf.call(records, target) < 0) {
                    tmp_container.push(record);
                }
            }
            if (tmp_container.length) {
                tmp_container.reverse();
                list._origFn.push.apply(list, tmp_container);
            }
        };
        ListMask.rebuild = function(list) {
            var record, source_info, _i, _j, _len, _len1, _ref, _ref1;
            util.empty(list);
            _ref = list._mapper._sources;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                source_info = _ref[_i];
                _ref1 = source_info.source;
                for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
                    record = _ref1[_j];
                    if (list.filter(record)) {
                        list._origFn.push.apply(list, ListMask.splitterWrap(list, record));
                    }
                }
            }
        };
        ListMask.registerFilter = function(list) {
            var default_fn, filter, filter_get, filter_set;
            default_fn = function() {
                return true;
            };
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
                if (typeof filter_function !== "function") {
                    error.Type({
                        filter_function: filter_function,
                        required: "function"
                    });
                }
                filter = filter_function;
                return list.update();
            };
            define_get_set(list, "filter", filter_get, filter_set, 1);
            define_get_set(list.options, "filter", filter_get, filter_set, 1);
        };
        ListMask.registerSplitter = function(list) {
            var default_fn, splitter, splitter_get, splitter_set;
            default_fn = function() {
                return false;
            };
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
                if (typeof splitter_function !== "function") {
                    error.Type({
                        splitter_function: splitter_function,
                        required: "function"
                    });
                }
                splitter = splitter_function;
                return list.update();
            };
            define_get_set(list, "splitter", splitter_get, splitter_set, 1);
            define_get_set(list.options, "splitter", splitter_get, splitter_set, 1);
        };
        ListMask.splitterWrap = function(list, record) {
            var info, key, record_mask, record_masks, result, value, _fn, _i, _len;
            if ((result = list.splitter(record)) && result instanceof Array) {
                record_masks = [];
                for (_i = 0, _len = result.length; _i < _len; _i++) {
                    info = result[_i];
                    if (!is_object(info)) {
                        error.Type({
                            splitter: list.splitter,
                            description: "If Array is returned, all elements must be " + "objects with override data"
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
                    define_value(record_mask, "_original", record);
                    record_masks.push(record_mask);
                }
                return record_masks;
            }
            return [ record ];
        };
        ListMask.update = function(info, source_names) {
            var action, add_action, cut, cutter, delete_if_on, find_and_add, from, incoming, is_on, key, list, mapper, merge, move, record, remapper, source, source_found, target_found, to, update_info, value, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _ref3, _ref4;
            action = null;
            cut = [];
            list = this;
            incoming = info.action;
            mapper = list._mapper;
            add_action = function(name, info) {
                var _base;
                return ((_base = action != null ? action : action = {})[name] != null ? _base[name] : _base[name] = []).push(info);
            };
            is_on = function(map_id, pseudo_id, record) {
                if (record._parent.idProperty) {
                    return [ 1, mapper.has(map_id, pseudo_id, source_names) ];
                } else {
                    return [ 0, __indexOf.call(list, record) >= 0 ];
                }
            };
            cutter = function(map_id, pseudo_id, record) {
                var mapped, was_on, _ref;
                _ref = is_on(map_id, pseudo_id, record), mapped = _ref[0], was_on = _ref[1];
                if (was_on) {
                    add_action("cut", record);
                    cut.push(record);
                    if (mapped) {
                        mapper.del(map_id, pseudo_id, source_names);
                    }
                }
            };
            find_and_add = function(map_id, pseudo_id, record) {
                var mapped, was_on, _ref;
                _ref = is_on(map_id, pseudo_id, record), mapped = _ref[0], was_on = _ref[1];
                if (mapped && !was_on) {
                    mapper.add(record, source_names);
                }
                return was_on;
            };
            delete_if_on = function(map_id, pseudo_id) {
                var mapped, was_on, _ref;
                _ref = is_on(map_id, pseudo_id, record), mapped = _ref[0], was_on = _ref[1];
                if (mapped && was_on) {
                    mapper.del(map_id, pseudo_id, source_names);
                }
                return was_on;
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
                    if (!list.filter(record)) {
                        continue;
                    }
                    find_and_add(record._id, record._pseudo, record);
                    ListMask.add(list, record);
                    add_action("add", record);
                }
            }
            if (incoming.update) {
                _ref2 = incoming.update;
                for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
                    info = _ref2[_k];
                    _ref3 = info, record = _ref3.record, info = _ref3.info, merge = _ref3.merge, move = _ref3.move, 
                    source = _ref3.source;
                    from = to = null;
                    if (remapper = merge || move) {
                        from = remapper.from, to = remapper.to;
                    }
                    if (list.filter(record)) {
                        source_found = from && delete_if_on(from.idMap, from.pseudoMap);
                        if (to) {
                            target_found = find_and_add(to.idMap, to.pseudoMap, record);
                        } else {
                            target_found = find_and_add(record._id, record._pseudo, record);
                        }
                        if (source_found && target_found) {
                            add_action("update", {
                                record: record,
                                info: info,
                                merge: remapper,
                                source: source
                            });
                            cut.push(source);
                        } else if (source_found) {
                            add_action("update", {
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
                            add_action("update", update_info);
                        } else {
                            ListMask.add(list, record);
                            add_action("add", record);
                        }
                    } else {
                        if (merge) {
                            cutter(from.idMap, from.pseudoMap, source);
                            cutter(to.idMap, to.pseudoMap, record);
                        } else if (move) {
                            cutter(from.idMap, from.pseudoMap, record);
                        } else {
                            cutter(record._id, record._pseudo, record);
                        }
                    }
                }
            }
            if (!list.sorter) {
                ListMask.rebuild(list);
            } else if (cut.length) {
                ListMask.cut(list, cut);
            }
            if (action) {
                list.events.emit("update", {
                    node: list,
                    action: action
                });
            }
        };
        return ListMask;
    }();
} ]);

ksc.factory("ksc.ListSorter", [ "ksc.error", "ksc.util", function(error, util) {
    var ListSorter, define_value, is_key_conform;
    define_value = util.defineValue;
    is_key_conform = util.isKeyConform;
    return ListSorter = function() {
        function ListSorter(list, description) {
            var key, sorter, type;
            sorter = this;
            define_value(sorter, "list", list);
            if (typeof description === "function") {
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
                        requirement: "function or string or array or object: " + "{key: <string|array>, reverse: <bool>, type: " + "'natural|number|byte'}"
                    });
                }
                if (type = description.type) {
                    if (type !== "byte" && type !== "natural" && type !== "number") {
                        error.Value({
                            type: type,
                            required: "byte, natural or number"
                        });
                    }
                } else {
                    type = "natural";
                }
                define_value(sorter, "key", key, 0, 1);
                define_value(sorter, "reverse", !!description.reverse, 0, 1);
                define_value(sorter, "type", type, 0, 1);
                define_value(sorter, "fn", ListSorter.getSortFn(sorter), 0, 1);
            }
            Object.preventExtensions(sorter);
        }
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
                if (typeof value !== "number" || isNaN(value)) {
                    error.Type({
                        sort_fn_output: value,
                        required: "number"
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
        ListSorter.getSortFn = function(sorter) {
            var joint, key, natural_cmp, numerify, reverse, type;
            key = sorter.key, reverse = sorter.reverse, type = sorter.type;
            reverse = reverse ? -1 : 1;
            joint = function(obj, parts) {
                var part;
                return function() {
                    var _i, _len, _results;
                    _results = [];
                    for (_i = 0, _len = parts.length; _i < _len; _i++) {
                        part = parts[_i];
                        if (obj[part] != null) {
                            _results.push(obj[part]);
                        }
                    }
                    return _results;
                }().join(" ");
            };
            numerify = function(n) {
                if (typeof n !== "number") {
                    if (typeof n === "string" && n !== "") {
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
                    if (b == null || b[i] === void 0) {
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
                if (type === "number") {
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
                        a = "";
                    }
                    if (b == null) {
                        b = "";
                    }
                }
                if (type === "natural") {
                    return natural_cmp(a, b) * reverse;
                } else if (type === "byte") {
                    a = String(a);
                    b = String(b);
                }
                if (a === b) {
                    return 0;
                }
                return (a > b ? 1 : -1) * reverse;
            };
        };
        ListSorter.register = function(list, description) {
            var getter, setter, sorter;
            sorter = void 0;
            if (description) {
                sorter = new ListSorter(list, description);
            }
            getter = function() {
                return sorter;
            };
            setter = function(description) {
                if (description) {
                    sorter = new ListSorter(list, description);
                    list._origFn.sort(sorter.fn);
                    return list.events.emit("update", {
                        node: list,
                        action: {
                            sort: true
                        }
                    });
                } else {
                    return sorter = void 0;
                }
            };
            util.defineGetSet(list, "sorter", getter, setter);
            util.defineGetSet(list.options, "sorter", getter, setter, 1);
        };
        return ListSorter;
    }();
} ]);

ksc.factory("ksc.List", [ "$rootScope", "ksc.ArrayTracker", "ksc.EditableRecord", "ksc.EventEmitter", "ksc.ListMapper", "ksc.ListSorter", "ksc.Record", "ksc.error", "ksc.util", function($rootScope, ArrayTracker, EditableRecord, EventEmitter, ListMapper, ListSorter, Record, error, util) {
    var List, SCOPE_UNSUBSCRIBER, argument_type_error, define_value, is_object;
    SCOPE_UNSUBSCRIBER = "_scopeUnsubscriber";
    argument_type_error = error.ArgumentType;
    define_value = util.defineValue;
    is_object = util.isObject;
    return List = function() {
        List.prototype._mapper = void 0;
        List.prototype._origFn = void 0;
        List.prototype._tracker = void 0;
        List.prototype.events = void 0;
        List.prototype.idMap = void 0;
        List.prototype.idProperty = void 0;
        List.prototype.pseudoMap = void 0;
        List.prototype.options = void 0;
        function List() {
            var argument, i, id_property, id_property_set, initial_set, key, list, options, scope, value, _ref, _ref1;
            list = [];
            initial_set = options = id_property = scope = void 0;
            for (i in arguments) {
                argument = arguments[i];
                if (Array.isArray(argument)) {
                    if (initial_set) {
                        argument_type_error({
                            argument: argument,
                            number: i,
                            description: "Ambiguous: can only take 1 array"
                        });
                    }
                    initial_set = argument;
                } else if (is_object(argument)) {
                    if ($rootScope.isPrototypeOf(argument)) {
                        if (scope) {
                            argument_type_error({
                                argument: argument,
                                number: i,
                                description: "Ambiguous: can only take 1 scope"
                            });
                        }
                        scope = argument;
                    } else {
                        if (options) {
                            argument_type_error({
                                argument: argument,
                                number: i,
                                description: "Ambiguous: can only take 1 object for options"
                            });
                        }
                        options = argument;
                    }
                } else if (util.isKeyConform(argument)) {
                    if (id_property != null) {
                        argument_type_error({
                            argument: argument,
                            number: i,
                            description: "Ambiguous: can only take 1 id_property"
                        });
                    }
                    id_property = argument;
                } else {
                    argument_type_error({
                        argument: argument,
                        number: i,
                        description: "Unknown type for a List argument"
                    });
                }
            }
            if ((options != null ? (_ref = options.record) != null ? _ref.idProperty : void 0 : void 0) != null && id_property) {
                argument_type_error({
                    argument: id_property,
                    options: options,
                    description: "id_property argument conflicts with " + ".options.record.idProperty"
                });
            }
            options = angular.copy(options) || {};
            define_value(list, "options", options);
            if (options.record == null) {
                options.record = {};
            }
            Record.checkIdProperty(id_property != null ? id_property : id_property = options.record.idProperty);
            id_property_set = function() {
                return error.Permission({
                    description: "idProperty can not be changed run-time"
                });
            };
            util.defineGetSet(list, "idProperty", function() {
                return id_property;
            }, id_property_set);
            util.defineGetSet(options.record, "idProperty", function() {
                return id_property;
            }, id_property_set, 1);
            define_value(list, "_sourceType", "List");
            define_value(list, "events", new EventEmitter());
            if (id_property != null) {
                ListMapper.register(list);
            }
            if (scope) {
                define_value(list, SCOPE_UNSUBSCRIBER, scope.$on("$destroy", function() {
                    delete list[SCOPE_UNSUBSCRIBER];
                    return list.destroy();
                }));
            }
            new ArrayTracker(list, {
                set: function(index, value, next, set_type) {
                    var record;
                    if (set_type === "external" && (record = list._tracker.store[index]) instanceof Record) {
                        record._replace(value);
                    } else {
                        next();
                    }
                }
            });
            define_value(list, "_origFn", {});
            _ref1 = this.constructor.prototype;
            for (key in _ref1) {
                value = _ref1[key];
                if (value != null && key !== "constructor") {
                    list._origFn[key] = list[key];
                    define_value(list, key, value);
                }
            }
            ListSorter.register(list, options.sorter);
            if (initial_set) {
                list.push.apply(list, initial_set);
            }
            return list;
        }
        List.prototype.destroy = function() {
            var list;
            list = this;
            if (Object.isFrozen(list)) {
                return false;
            }
            list.events.emit("destroy");
            if (typeof list[SCOPE_UNSUBSCRIBER] === "function") {
                list[SCOPE_UNSUBSCRIBER]();
            }
            if (typeof list._sourceUnsubscriber === "function") {
                list._sourceUnsubscriber();
            }
            util.empty(list);
            delete list.options;
            delete list._sourceUnsubscriber;
            Object.freeze(list);
            return true;
        };
        List.prototype.cut = function() {
            var action, cut, id, item, list, mapper, record, records, removable, tmp_container, _i, _len;
            records = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            if (!records.length) {
                error.MissingArgument({
                    name: "record",
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
                            description: "not found in list"
                        });
                    }
                    if (mapper) {
                        if (!mapper.has(record)) {
                            error.Key({
                                record: record,
                                description: "idMap/pseudoMap id error"
                            });
                        }
                        mapper.del(record);
                    }
                    cut.push(record);
                } else {
                    id = record;
                    if (!(record = mapper.has(id))) {
                        error.Key({
                            id: id,
                            description: "map id error"
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
            while (item = list._origFn.pop()) {
                if (__indexOf.call(removable, item) < 0) {
                    tmp_container.push(item);
                }
            }
            if (tmp_container.length) {
                tmp_container.reverse();
                List.inject(list, list.length, tmp_container);
            }
            action = {
                cut: cut
            };
            List.emitAction(list, action);
            return action;
        };
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
                List.emitAction(list, action);
            }
            if (return_action) {
                return action;
            }
            return this;
        };
        List.prototype.pop = function() {
            return List.remove(this, "pop");
        };
        List.prototype.push = function() {
            var action, items, list, return_action, _i;
            items = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, 
            []), return_action = arguments[_i++];
            return_action = List.normalizeReturnAction(items, return_action);
            list = this;
            action = List.add(list, items, list.length);
            if (return_action) {
                return action;
            }
            return list.length;
        };
        List.prototype.shift = function() {
            return List.remove(this, "shift");
        };
        List.prototype.unshift = function() {
            var action, items, list, return_action, _i;
            items = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, 
            []), return_action = arguments[_i++];
            return_action = List.normalizeReturnAction(items, return_action);
            list = this;
            action = List.add(list, items, 0);
            if (return_action) {
                return action;
            }
            return list.length;
        };
        List.prototype.splice = function() {
            var action, count, items, len, list, pos, positive_int_or_zero, return_action, _i;
            pos = arguments[0], count = arguments[1], items = 4 <= arguments.length ? __slice.call(arguments, 2, _i = arguments.length - 1) : (_i = 2, 
            []), return_action = arguments[_i++];
            return_action = List.normalizeReturnAction(items, return_action);
            if (typeof items[0] === "undefined" && items.length === 1) {
                items.pop();
            }
            if (typeof count === "boolean" && !items.length) {
                return_action = count;
                count = null;
            }
            positive_int_or_zero = function(value, i) {
                if (!(typeof value === "number" && (value > 0 || value === 0) && value === Math.floor(value))) {
                    return argument_type_error({
                        value: value,
                        argument: i,
                        required: "int >= 0"
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
                List.emitAction(list, action);
            }
            if (return_action) {
                return action;
            }
            return action.cut || [];
        };
        List.prototype.reverse = function() {
            var list;
            list = this;
            if (list.sorter) {
                error.Permission("can not reverse an auto-sorted list");
            }
            if (list.length > 1) {
                list._origFn.reverse();
                List.emitAction(list, {
                    reverse: true
                });
            }
            return list;
        };
        List.prototype.sort = function(sorter_fn) {
            var cmp, i, list, record, _i, _len;
            list = this;
            if (list.sorter) {
                error.Permission("can not reverse an auto-sorted list");
            }
            if (list.length > 1) {
                cmp = function() {
                    var _i, _len, _results;
                    _results = [];
                    for (_i = 0, _len = list.length; _i < _len; _i++) {
                        record = list[_i];
                        _results.push(record);
                    }
                    return _results;
                }();
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
                list._origFn.sort(sorter_fn);
                for (i = _i = 0, _len = list.length; _i < _len; i = ++_i) {
                    record = list[i];
                    if (!(record !== cmp[i])) {
                        continue;
                    }
                    List.emitAction(list, {
                        sort: true
                    });
                    break;
                }
            }
            return list;
        };
        List.prototype._recordChange = function(record, record_info, old_id) {
            var add_to_map, info, item, list, map, mapper, new_pos, pos, _i, _len;
            if (!(record instanceof Record)) {
                error.Type({
                    record: record,
                    required: "Record"
                });
            }
            list = this;
            add_to_map = function() {
                define_value(record, "_pseudo", null);
                return mapper.add(record);
            };
            info = {
                record: record,
                info: record_info
            };
            if (map = list.idMap) {
                mapper = list._mapper;
                if (old_id !== record._id) {
                    list.events.halt();
                    try {
                        if (record._id == null) {
                            mapper.del(old_id);
                            define_value(record, "_pseudo", util.uid("record.pseudoMap"));
                            mapper.add(record);
                            info.move = {
                                from: {
                                    idMap: old_id
                                },
                                to: {
                                    pseudoMap: record._pseudo
                                }
                            };
                        } else if (old_id == null) {
                            if (map[record._id]) {
                                info.merge = {
                                    from: {
                                        pseudoMap: record._pseudo
                                    },
                                    to: {
                                        idMap: record._id
                                    }
                                };
                                info.record = map[record._id];
                                info.source = record;
                                list.cut(record);
                                list.push(record);
                            } else {
                                info.move = {
                                    from: {
                                        pseudoMap: record._pseudo
                                    },
                                    to: {
                                        idMap: record._id
                                    }
                                };
                                mapper.del(null, record._pseudo);
                                add_to_map();
                            }
                        } else {
                            if (map[record._id]) {
                                info.merge = {
                                    from: {
                                        idMap: old_id
                                    },
                                    to: {
                                        idMap: record._id
                                    }
                                };
                                info.record = map[record._id];
                                info.source = record;
                                list.cut(old_id);
                                list.push(record);
                            } else {
                                info.move = {
                                    from: {
                                        idMap: old_id
                                    },
                                    to: {
                                        idMap: record._id
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
            }
            if (list.sorter) {
                record = info.record;
                for (pos = _i = 0, _len = list.length; _i < _len; pos = ++_i) {
                    item = list[pos];
                    if (!(item === record)) {
                        continue;
                    }
                    list._origFn.splice(pos, 1);
                    new_pos = list.sorter.position(record);
                    List.inject(list, new_pos, [ record ]);
                    break;
                }
            }
            return List.emitAction(list, {
                update: [ info ]
            });
        };
        List.add = function(list, items, pos) {
            var action, existing, item, mapper, original, record_class, record_opts, tmp, _i, _j, _len, _len1;
            if (!items.length) {
                error.MissingArgument({
                    name: "item",
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
                    if (item instanceof Record) {
                        if (item._parent && item._parent !== list) {
                            item._parent.cut(item);
                        }
                        util.mergeIn(item._options, record_opts);
                        define_value(item, "_parent", list);
                    } else {
                        item = new record_class(item, record_opts, list);
                    }
                    if (item._idProperty !== list.idProperty) {
                        error.Value({
                            "list.idProperty": list.idProperty,
                            "record._idProperty": record._idProperty,
                            description: "record._idProperty conflicts with list.idProperty"
                        });
                    }
                    Record.setId(item);
                    if (item._id != null) {
                        if (existing = mapper.has(item._id)) {
                            existing._replace(item._clone(1));
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
                            define_value(item, "_pseudo", null);
                        }
                    } else {
                        if (mapper) {
                            define_value(item, "_pseudo", util.uid("record.pseudoMap"));
                            mapper.add(item);
                        }
                        tmp.push(item);
                        (action.add != null ? action.add : action.add = []).push(item);
                    }
                }
                if (tmp.length) {
                    if (list.sorter) {
                        for (_j = 0, _len1 = tmp.length; _j < _len1; _j++) {
                            item = tmp[_j];
                            pos = list.sorter.position(item);
                            List.inject(list, pos, [ item ]);
                        }
                    } else {
                        List.inject(list, pos, tmp);
                    }
                }
            } finally {
                list.events.unhalt();
            }
            List.emitAction(list, action);
            return action;
        };
        List.emitAction = function(list, action) {
            return list.events.emit("update", {
                node: list,
                action: action
            });
        };
        List.inject = function(list, pos, records) {
            var _ref;
            (_ref = list._origFn.splice).call.apply(_ref, [ list, pos, 0 ].concat(__slice.call(records)));
        };
        List.normalizeReturnAction = function(items, return_action) {
            if (typeof return_action !== "boolean") {
                items.push(return_action);
                return_action = false;
            }
            return return_action;
        };
        List.remove = function(list, orig_fn) {
            var record, _ref;
            if (record = list._origFn[orig_fn]()) {
                if ((_ref = list._mapper) != null) {
                    _ref.del(record);
                }
                List.emitAction(list, {
                    cut: [ record ]
                });
            }
            return record;
        };
        return List;
    }();
} ]);

ksc.factory("ksc.Mixin", [ "ksc.error", "ksc.util", function(error, util) {
    var Mixin, normalize, validate_key;
    normalize = function(explicit, properties, next) {
        var property, _i, _len;
        if (explicit != null) {
            if (typeof explicit !== "boolean") {
                properties.unshift(explicit);
                explicit = true;
            }
        }
        for (_i = 0, _len = properties.length; _i < _len; _i++) {
            property = properties[_i];
            util.isKeyConform(property, 1);
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
        return explicit && found || !explicit && !found;
    };
    return Mixin = function() {
        function Mixin() {}
        Mixin.extend = function() {
            var explicit, extensible, mixin, properties;
            extensible = arguments[0], mixin = arguments[1], explicit = arguments[2], properties = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
            Mixin.extendProto.apply(Mixin, [ extensible, mixin, explicit ].concat(__slice.call(properties)));
            return Mixin.extendInstance.apply(Mixin, [ extensible, mixin, explicit ].concat(__slice.call(properties)));
        };
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
        Mixin.extendProto = function() {
            var explicit, extensible, mixin, properties;
            extensible = arguments[0], mixin = arguments[1], explicit = arguments[2], properties = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
            return Mixin.extendInstance.apply(Mixin, [ extensible.prototype, mixin.prototype, explicit ].concat(__slice.call(properties)));
        };
        return Mixin;
    }();
} ]);

ksc.factory("ksc.RecordContract", [ "ksc.error", "ksc.util", function(error, util) {
    var NULLABLE, RecordContract, define_value, has_own, is_object;
    NULLABLE = "nullable";
    has_own = util.hasOwn;
    is_object = util.isObject;
    define_value = util.defineValue;
    return RecordContract = function() {
        function RecordContract(contract) {
            var arr, desc, desc_key, exclusive_count, key, subcontract, typ, _i, _len, _ref;
            if (contract === null || contract instanceof RecordContract) {
                return contract;
            }
            if (!is_object(contract)) {
                error.Type({
                    contract: contract,
                    required: "object"
                });
            }
            for (key in contract) {
                desc = contract[key];
                if (key.substr(0, 1) === "_") {
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
                _ref = [ "array", "contract", "default" ];
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
                            description: "array, default, contract are mutually exclusive"
                        });
                    }
                }
                typ = desc.type;
                if (((arr = desc.array) || typ === "array") && !is_object(arr)) {
                    error.Type({
                        array: arr,
                        description: "array description required"
                    });
                }
                if (arr = desc.array) {
                    if (has_own(desc, "type") && typ !== "array") {
                        error.Type({
                            type: type,
                            array: arr,
                            requiredType: "array"
                        });
                    }
                    delete desc.type;
                    typ = null;
                }
                if (((subcontract = desc.contract) || typ === "object") && !is_object(subcontract)) {
                    error.Type({
                        contract: subcontract,
                        description: "contract description required"
                    });
                }
                if (subcontract) {
                    if (has_own(desc, "type") && typ !== "object") {
                        error.Type({
                            type: type,
                            contract: subcontract,
                            requiredType: "object"
                        });
                    }
                    delete desc.type;
                    typ = null;
                }
                if (!arr) {
                    if (subcontract) {
                        desc.contract = new RecordContract(subcontract);
                    } else {
                        if (has_own(desc, "default") && !has_own(desc, "type") && RecordContract.typeDefaults[typeof desc["default"]] != null) {
                            desc.type = typ = typeof desc["default"];
                        }
                        if (RecordContract.typeDefaults[typ] == null) {
                            error.Type({
                                type: typ,
                                required: "array, boolean, number, object, string"
                            });
                        }
                    }
                }
                this._match(key, this._default(key));
            }
            Object.freeze(this);
        }
        RecordContract.prototype._default = function(key) {
            var desc, value, _ref;
            desc = this[key];
            if (!desc) {
                error.Key({
                    key: key,
                    description: "Key not found on contract"
                });
            }
            if (has_own(desc, "default")) {
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
        RecordContract.prototype._match = function(key, value) {
            var desc;
            desc = this[key];
            if (desc != null && (desc.array && Array.isArray(value) || (desc.contract && is_object(value) || typeof value === desc.type) || value === null && desc[NULLABLE])) {
                return true;
            }
            return error.ContractBreak({
                key: key,
                value: value,
                contract: desc
            });
        };
        RecordContract.finalizeRecord = function(record) {
            if (record._options.contract && Object.isExtensible(record)) {
                if (!has_own(record, "$$hashKey")) {
                    define_value(record, "$$hashKey", void 0, 1);
                }
                Object.preventExtensions(record);
            }
        };
        RecordContract.typeDefaults = {
            "boolean": false,
            number: 0,
            string: ""
        };
        return RecordContract;
    }();
} ]);

ksc.factory("ksc.Record", [ "ksc.ArrayTracker", "ksc.EventEmitter", "ksc.RecordContract", "ksc.error", "ksc.util", function(ArrayTracker, EventEmitter, RecordContract, error, util) {
    var CONTRACT, Record, define_get_set, define_value, has_own, is_array, is_key_conform, is_object, _ARRAY, _EVENTS, _ID, _OPTIONS, _PARENT, _PARENT_KEY, _PRIMARY_KEY, _PSEUDO, _SAVED;
    _ARRAY = "_array";
    _EVENTS = "_events";
    _ID = "_id";
    _OPTIONS = "_options";
    _PARENT = "_parent";
    _PARENT_KEY = "_parentKey";
    _PRIMARY_KEY = "_primaryId";
    _PSEUDO = "_pseudo";
    _SAVED = "_saved";
    CONTRACT = "contract";
    define_get_set = util.defineGetSet;
    define_value = util.defineValue;
    has_own = util.hasOwn;
    is_array = Array.isArray;
    is_key_conform = util.isKeyConform;
    is_object = util.isObject;
    return Record = function() {
        function Record(data, options, parent, parent_key) {
            var contract, id_property, id_property_get, id_property_set, key, record, ref, refs, target, _i, _j, _len, _len1, _ref, _ref1;
            if (data == null) {
                data = {};
            }
            if (options == null) {
                options = {};
            }
            if (!is_object(data)) {
                error.Type({
                    data: data,
                    required: "object"
                });
            }
            Record.objReq("data", data, 1);
            Record.objReq("options", options, 2);
            record = this;
            define_value(record, _OPTIONS, options);
            define_value(record, _SAVED, {});
            if (has_own(options, CONTRACT)) {
                contract = options[CONTRACT] = new RecordContract(options[CONTRACT]);
            }
            define_value(record, _PARENT, parent);
            if (parent != null || parent_key != null) {
                Record.objReq("options", parent, 3);
                if (parent_key != null) {
                    is_key_conform(parent_key, 1, 4);
                    define_value(record, _PARENT_KEY, parent_key);
                    delete record[_ID];
                    delete record[_PRIMARY_KEY];
                    delete record[_PSEUDO];
                }
            }
            _ref = contract ? [ record, contract ] : [ record ];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                target = _ref[_i];
                _ref1 = util.propertyRefs(Object.getPrototypeOf(target));
                for (key in _ref1) {
                    refs = _ref1[key];
                    for (_j = 0, _len1 = refs.length; _j < _len1; _j++) {
                        ref = refs[_j];
                        Object.defineProperty(ref, key, {
                            enumerable: false
                        });
                    }
                }
            }
            id_property = options.idProperty;
            if (parent_key == null) {
                define_value(record, _ID);
                define_value(record, _PRIMARY_KEY);
                define_value(record, _PSEUDO);
                define_value(record, _EVENTS, new EventEmitter());
                Record.checkIdProperty(id_property);
                id_property_get = function() {
                    var _ref2;
                    if (id_property != null) {
                        return id_property;
                    }
                    return (_ref2 = record[_PARENT]) != null ? _ref2.idProperty : void 0;
                };
                id_property_set = function(value) {
                    Record.checkIdProperty(value);
                    Record.setId(record);
                };
                define_get_set(record, "_idProperty", id_property_get, id_property_set);
                define_get_set(options, "idProperty", id_property_get, id_property_set, 1);
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
        Record.prototype._clone = function(return_plain_object, exclude_static) {
            var clone, key, key2, record, statics, value, value2, _ref, _ref1;
            record = this;
            clone = {};
            if (return_plain_object) {
                _ref = record[_SAVED];
                for (key in _ref) {
                    value = _ref[key];
                    if (value != null ? value._clone : void 0) {
                        value = value._clone(1, exclude_static);
                    }
                    clone[key] = value;
                }
            } else {
                statics = {};
                _ref1 = record[_SAVED];
                for (key in _ref1) {
                    value = _ref1[key];
                    if (value != null ? value._clone : void 0) {
                        if (!exclude_static) {
                            statics[key] = Record.getAllStatic(value);
                        }
                        value = value._clone(0, 1, 1);
                    }
                    clone[key] = value;
                }
                clone = new record.constructor(clone);
                for (key in statics) {
                    value = statics[key];
                    for (key2 in value) {
                        value2 = value[key2];
                        clone[key][key2] = value2;
                    }
                }
            }
            if (!exclude_static) {
                Record.getAllStatic(record, clone);
            }
            return clone;
        };
        Record.prototype._delete = function() {
            return error.Permission({
                keys: keys,
                description: "Read-only Record"
            });
        };
        Record.prototype._entity = function() {
            return this._clone(1);
        };
        Record.prototype._getProperty = function(key) {
            is_key_conform(key, 1, 1);
            return Record.arrayFilter(this[_SAVED][key]);
        };
        Record.prototype._replace = function(data, emit_event) {
            var arr, changed, contract, events, flat, key, record, replacing, value;
            if (emit_event == null) {
                emit_event = true;
            }
            record = this;
            events = record[_EVENTS];
            if (events === null) {
                error.Permission({
                    key: record[_PARENT_KEY],
                    description: "can not replace subobject"
                });
            }
            replacing = true;
            if (is_array(data)) {
                flat = function() {
                    var _i, _len, _results;
                    _results = [];
                    for (_i = 0, _len = data.length; _i < _len; _i++) {
                        value = data[_i];
                        _results.push(value);
                    }
                    return _results;
                }();
                Record.arrayify(record);
                changed = 1;
                arr = record[_ARRAY];
                arr._tracker.set = function(index, value) {
                    return record._setProperty(index, value, replacing);
                };
                if (flat.length && arr.push.apply(arr, flat)) {
                    changed = 1;
                }
            } else {
                Record.dearrayify(record);
                flat = {};
                for (key in data) {
                    value = data[key];
                    flat[key] = value;
                }
                if (contract = record[_OPTIONS][CONTRACT]) {
                    for (key in contract) {
                        value = contract[key];
                        if (!has_own(flat, key)) {
                            flat[key] = contract._default(key);
                        }
                    }
                }
                for (key in flat) {
                    value = flat[key];
                    Record.getterify(record, key);
                    if (record._setProperty(key, value, replacing)) {
                        changed = 1;
                    }
                }
            }
            for (key in record[_SAVED]) {
                if (!!has_own(flat, key)) {
                    continue;
                }
                delete record[key];
                delete record[_SAVED][key];
                changed = 1;
            }
            if (changed && events && emit_event) {
                Record.emitUpdate(record, "replace");
            }
            replacing = false;
            return !!changed;
        };
        Record.prototype._setProperty = function(key, value, initial) {
            var record, saved;
            record = this;
            saved = record[_SAVED];
            if (!initial) {
                error.Permission({
                    key: key,
                    value: value,
                    description: "Read-only Record"
                });
            }
            Record.valueCheck(record, key, value);
            if (has_own(saved, key) && util.identical(value, record[key])) {
                return false;
            }
            define_value(saved, key, Record.valueWrap(record, key, value), 0, 1);
            Record.getterify(record, key);
            return true;
        };
        Record.arrayFilter = function(record) {
            var arr, desc, key, marked, object, _i, _len, _ref;
            if (!(arr = record != null ? record[_ARRAY] : void 0)) {
                return record;
            }
            object = record;
            marked = {};
            while (object && object.constructor !== Object) {
                _ref = Object.getOwnPropertyNames(object);
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                    key = _ref[_i];
                    if (key !== _ARRAY && key.substr(0, 1) === "_" && !has_own(marked, key)) {
                        marked[key] = Object.getOwnPropertyDescriptor(object, key);
                    }
                }
                object = Object.getPrototypeOf(object);
            }
            for (key in arr) {
                if (key !== "_record" && key.substr(0, 1) === "_" && !has_own(marked, key)) {
                    delete arr[key];
                }
            }
            for (key in marked) {
                desc = marked[key];
                Object.defineProperty(arr, key, desc);
            }
            define_value(arr, "_record", record);
            return arr;
        };
        Record.arrayify = function(record) {
            var arr;
            define_value(record, _ARRAY, arr = []);
            return new ArrayTracker(arr, {
                store: record[_SAVED],
                get: function(index) {
                    return record._getProperty(index);
                },
                set: function(index, value) {
                    return record._setProperty(index, value);
                },
                del: function(index) {
                    record._delete(index);
                    return false;
                }
            });
        };
        Record.checkIdProperty = function(id_property) {
            var check, err, item, _i, _len;
            err = function() {
                return error.Value({
                    item: item,
                    description: "idProperty items must be key conform"
                });
            };
            if (id_property != null) {
                if (is_array(id_property)) {
                    check = id_property;
                } else {
                    check = [ id_property ];
                }
                if (!check.length) {
                    err();
                }
                for (_i = 0, _len = check.length; _i < _len; _i++) {
                    item = check[_i];
                    if (!is_key_conform(item)) {
                        err();
                    }
                }
            }
        };
        Record.dearrayify = function(record) {
            return delete record[_ARRAY];
        };
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
                    _ref._recordChange(source, info, old_id);
                }
            }
            events.emit("update", info);
        };
        Record.getAllStatic = function(record, target) {
            var key, value;
            if (target == null) {
                target = {};
            }
            for (key in record) {
                value = record[key];
                if (has_own(Object.getOwnPropertyDescriptor(record, key), "value")) {
                    target[key] = value;
                }
            }
            return target;
        };
        Record.getterify = function(record, index) {
            if (!has_own(record, index)) {
                define_get_set(record, index, function() {
                    return record._getProperty(index);
                }, function(value) {
                    return record._setProperty(index, value);
                }, 1);
            }
        };
        Record.objReq = function(name, value, arg) {
            var inf;
            if (!is_object(value)) {
                inf = {};
                inf[name] = value;
                inf.argument = arg;
                inf.required = "object";
                error.ArgumentType(inf);
            }
        };
        Record.setId = function(record) {
            var composite, i, id, id_property, id_property_check, part, primary, value, _i, _len;
            id_property_check = function(key) {
                var contract, _ref;
                if (contract = record[_OPTIONS][CONTRACT]) {
                    if (contract[key] == null) {
                        error.ContractBreak({
                            key: key,
                            contract: contract,
                            mismatch: "idProperty"
                        });
                    }
                    if ((_ref = contract[key].type) !== "string" && _ref !== "number") {
                        error.ContractBreak({
                            key: key,
                            contract: contract,
                            required: "string or number"
                        });
                    }
                    if (record[key] == null) {
                        error.ContractBreak({
                            key: key,
                            value: record[key],
                            mismatch: "idProperty value must exist (not nullable)"
                        });
                    }
                }
            };
            if ((id_property = record._idProperty) != null) {
                if (is_array(id_property)) {
                    composite = [];
                    for (i = _i = 0, _len = id_property.length; _i < _len; i = ++_i) {
                        part = id_property[i];
                        id_property_check(part);
                        if (is_key_conform(value = record[part])) {
                            composite.push(value);
                        } else if (!i) {
                            break;
                        }
                    }
                    primary = record[id_property[0]];
                    id = composite.length ? composite.join("-") : primary;
                    define_value(record, _ID, id);
                    define_value(record, _PRIMARY_KEY, primary);
                } else {
                    id_property_check(id_property);
                    define_value(record, _ID, record[id_property]);
                }
            } else {
                define_value(record, _ID);
                define_value(record, _PRIMARY_KEY);
            }
        };
        Record.valueCheck = function(record, key, value) {
            var contract;
            is_key_conform(key, 1, 1);
            if (contract = record[_OPTIONS][CONTRACT]) {
                contract._match(record[_ARRAY] ? "all" : key, value);
            } else {
                if (typeof key === "string" && key.substr(0, 1) === "_") {
                    error.ArgumentType({
                        key: key,
                        argument: 1,
                        description: 'can not start with "_"'
                    });
                }
                if (typeof value === "function") {
                    error.Value({
                        value: value,
                        description: "can not be function"
                    });
                }
            }
        };
        Record.valueWrap = function(record, key, value) {
            var class_ref, contract, key_contract, subopts;
            contract = record[_OPTIONS][CONTRACT];
            if (is_object(value)) {
                if (value._clone) {
                    value = value._clone(1);
                }
                class_ref = record[_OPTIONS].subtreeClass || Record;
                if (contract) {
                    if (key_contract = contract[key]) {
                        if (key_contract.array) {
                            subopts = {
                                contract: {
                                    all: key_contract.array
                                }
                            };
                        } else {
                            subopts = {
                                contract: key_contract[CONTRACT]
                            };
                        }
                    } else {
                        subopts = {
                            contract: contract.all.contract
                        };
                    }
                }
                value = new class_ref(value, subopts, record, key);
            }
            return value;
        };
        return Record;
    }();
} ]);

ksc.factory("ksc.RestList", [ "$http", "$q", "ksc.List", "ksc.batchLoaderRegistry", "ksc.error", "ksc.restUtil", "ksc.util", function($http, $q, List, batchLoaderRegistry, error, restUtil, util) {
    var PRIMARY_ID, REST_CACHE, REST_PENDING, RestList, define_value;
    REST_CACHE = "restCache";
    REST_PENDING = "restPending";
    PRIMARY_ID = "_primaryId";
    define_value = util.defineValue;
    return RestList = function(_super) {
        __extends(RestList, _super);
        RestList.prototype.restCache = void 0;
        RestList.prototype.restPending = 0;
        function RestList() {
            var list;
            list = RestList.__super__.constructor.apply(this, arguments);
            if (list.idProperty == null) {
                error.MissingArgument({
                    required: "idProperty is mandatory for RestList"
                });
            }
            return list;
        }
        RestList.prototype.restGetRaw = function(query_parameters, callback) {
            var endpoint, k, list, parts, promise, url, v;
            if (typeof query_parameters === "function") {
                callback = query_parameters;
                query_parameters = null;
            }
            list = this;
            if (!((endpoint = list.options.endpoint) && (url = endpoint.url) && typeof url === "string")) {
                error.Type({
                    "options.endpoint.url": url,
                    required: "string"
                });
            }
            define_value(list, REST_PENDING, list[REST_PENDING] + 1, 0, 1);
            if (!(promise = batchLoaderRegistry.get(url, query_parameters))) {
                if (query_parameters) {
                    parts = function() {
                        var _results;
                        _results = [];
                        for (k in query_parameters) {
                            v = query_parameters[k];
                            _results.push(encodeURIComponent(k) + "=" + encodeURIComponent(v));
                        }
                        return _results;
                    }();
                    if (parts.length) {
                        url += (url.indexOf("?") > -1 ? "&" : "?") + parts.join("&");
                    }
                }
                promise = $http.get(url);
            }
            return restUtil.wrapPromise(promise, function(err, result) {
                define_value(list, REST_PENDING, list[REST_PENDING] - 1, 0, 1);
                return callback(err, result);
            });
        };
        RestList.prototype.restLoad = function(force_load, query_parameters, callback) {
            var http_get, list, options;
            if (typeof force_load !== "boolean") {
                callback = query_parameters;
                query_parameters = force_load;
                force_load = null;
            }
            if (typeof query_parameters === "function") {
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
                            record_list = list.push.apply(list, __slice.call(data).concat([ true ]));
                        } catch (_error) {
                            _err = _error;
                            err = _err;
                        }
                    }
                    return typeof callback === "function" ? callback(err, record_list, raw_response) : void 0;
                });
            };
            if (!options.cache || !list.restCache || force_load) {
                define_value(list, "restCache", http_get(), 0, 1);
            } else if (callback) {
                restUtil.wrapPromise(list.restCache, callback);
            }
            return list.restCache;
        };
        RestList.prototype.restSave = function() {
            var callback, records, _i;
            records = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, 
            []), callback = arguments[_i++];
            return RestList.writeBack(this, 1, records, callback);
        };
        RestList.prototype.restDelete = function() {
            var callback, records, _i;
            records = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, 
            []), callback = arguments[_i++];
            return RestList.writeBack(this, 0, records, callback);
        };
        RestList.getResponseArray = function(list, data) {
            var endpoint_options, k, key, v;
            endpoint_options = list.options.endpoint;
            key = "responseProperty";
            if (typeof endpoint_options[key] === "undefined") {
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
                    "options.endpoint.responseProperty": void 0,
                    description: "array type property in response is not found or " + "unspecified"
                });
            }
            return data;
        };
        RestList.relatedRecords = function(list, record) {
            var id, item, _i, _len, _results;
            if ((id = record[PRIMARY_ID]) == null) {
                return [ record ];
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
        RestList.updateOnSave = function(list, records, updates, next) {
            var changed, data, i, key, primary_id, promise, promises, query_parameters, record, replacable, replace, tmp_listener_unsubscribe, _i, _j, _len, _len1;
            promises = [];
            replacable = [];
            for (i = _i = 0, _len = records.length; _i < _len; i = ++_i) {
                record = records[i];
                if ((primary_id = record[PRIMARY_ID]) != null || list.options.reloadOnUpdate) {
                    query_parameters = {};
                    key = list.idProperty;
                    if (primary_id) {
                        query_parameters[key[0]] = primary_id;
                    } else {
                        query_parameters[key] = record._id;
                    }
                    promises.push(list.restLoad(query_parameters));
                } else {
                    replacable.push([ record, updates[i] ]);
                }
            }
            if (replacable.length) {
                list.events.halt();
                changed = [];
                tmp_listener_unsubscribe = list.events.on("1#!update", function(info) {
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
                    list.events.emit("update", {
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
        RestList.writeBack = function(list, save_type, records, callback) {
            var bulk_method, endpoint_options, i, id, orig_rec, pseudo_id, record, uid, unique_record_map, _i, _len;
            if (!(callback && typeof callback === "function")) {
                if (callback) {
                    records.push(callback);
                }
                callback = null;
            }
            unique_record_map = {};
            for (i = _i = 0, _len = records.length; _i < _len; i = ++_i) {
                record = records[i];
                if (!util.isObject(record)) {
                    records[i] = record = list.idMap[record];
                }
                orig_rec = record;
                pseudo_id = null;
                uid = "id:" + (id = record != null ? record._id : void 0);
                if ((id = record != null ? record._id : void 0) == null) {
                    pseudo_id = record != null ? record._pseudo : void 0;
                    uid = "pseudo:" + pseudo_id;
                } else if (record[PRIMARY_ID] != null) {
                    uid = "id:" + record[PRIMARY_ID];
                }
                if (save_type) {
                    record = pseudo_id && list.pseudoMap[pseudo_id] || list.idMap[id];
                    if (!record) {
                        error.Key({
                            key: orig_rec,
                            description: "no such record on list"
                        });
                    }
                } else if (!(record = list.idMap[id])) {
                    error.Key({
                        key: orig_rec,
                        description: "no such record on .idMap"
                    });
                }
                if (unique_record_map[uid]) {
                    error.Value({
                        uid: uid,
                        description: "not unique"
                    });
                }
                unique_record_map[uid] = record;
            }
            if (!records.length) {
                error.MissingArgument({
                    name: "record",
                    argument: 1
                });
            }
            endpoint_options = list.options.endpoint || {};
            if (save_type && endpoint_options.bulkSave) {
                bulk_method = String(endpoint_options.bulkSave).toLowerCase();
                if (bulk_method !== "post") {
                    bulk_method = "put";
                }
                return RestList.writeBulk(list, bulk_method, records, callback);
            } else if (!save_type && endpoint_options.bulkDelete) {
                return RestList.writeBulk(list, "delete", records, callback);
            } else {
                return RestList.writeSolo(list, save_type, records, callback);
            }
        };
        RestList.writeBulk = function(list, method, records, callback) {
            var args, data, id, promise, record, saving, url;
            if (!((url = list.options.endpoint.url) && typeof url === "string")) {
                error.Type({
                    "options.endpoint.url": url,
                    required: "string"
                });
            }
            saving = method !== "delete";
            data = function() {
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
            }();
            args = [ url ];
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
        RestList.writeSolo = function(list, save_type, records, callback) {
            var delayed_cb_args, finished, iteration, pending_refresh, record_list;
            record_list = [];
            delayed_cb_args = pending_refresh = null;
            finished = function(err) {
                var raw_responses;
                raw_responses = Array.prototype.slice.call(arguments, 1);
                delayed_cb_args = [ err, record_list ].concat(__slice.call(raw_responses));
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
                method = "delete";
                url = (_ref = list.options.record.endpoint) != null ? _ref.url : void 0;
                if (save_type) {
                    method = "put";
                    if (record._pseudo) {
                        method = "post";
                        id = null;
                        url = (_ref1 = list.options.endpoint) != null ? _ref1.url : void 0;
                    }
                }
                if (!(url && typeof url === "string")) {
                    error.Value({
                        "options.record.endpoint.url": url,
                        required: "string"
                    });
                }
                url = url.replace("<id>", id);
                args = [ url ];
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
                            RestList.updateOnSave(list, [ record ], [ raw_response.data ], function() {
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
    }(List);
} ]);

ksc.factory("ksc.RestRecord", [ "$http", "ksc.Record", "ksc.batchLoaderRegistry", "ksc.error", "ksc.restUtil", "ksc.util", function($http, Record, batchLoaderRegistry, error, restUtil, util) {
    var OPTIONS, REST_CACHE, REST_PENDING, RestRecord, define_value;
    OPTIONS = "_options";
    REST_CACHE = "_restCache";
    REST_PENDING = "_restPending";
    define_value = util.defineValue;
    return RestRecord = function(_super) {
        __extends(RestRecord, _super);
        RestRecord.prototype._restPending = 0;
        function RestRecord() {
            define_value(this, REST_PENDING, 0);
            RestRecord.__super__.constructor.apply(this, arguments);
        }
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
            if (typeof force_load !== "boolean") {
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
        RestRecord.getUrl = function(record) {
            var endpoint, url;
            if (!((endpoint = record[OPTIONS].endpoint) && (url = endpoint.url) != null)) {
                error.Value({
                    "_options.endpoint.url": void 0
                });
            }
            if (typeof url !== "string") {
                error.Type({
                    "_options.endpoint.url": url,
                    required: "string"
                });
            }
            return url;
        };
        return RestRecord;
    }(Record);
} ]);

ksc.service("ksc.restUtil", [ "$q", "ksc.error", function($q, error) {
    var RestUtil;
    return RestUtil = function() {
        function RestUtil() {}
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
                    return done_callback.apply(null, [ error ].concat(__slice.call(results)));
                }
            };
            promises = function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = iteration_data_sets.length; _i < _len; _i++) {
                    iteration_data_set = iteration_data_sets[_i];
                    _results.push(RestUtil.wrapPromise(iteration_fn(iteration_data_set), iteration_callback));
                }
                return _results;
            }();
            if (promises.length < 2) {
                return promises[0];
            }
            return $q.all(promises);
        };
        RestUtil.wrapPromise = function(promise, callback) {
            var error_fn, success_fn;
            success_fn = function(result) {
                var config, data, headers, status, wrap;
                wrap = (data = result.data, status = result.status, headers = result.headers, config = result.config, 
                result);
                return callback(null, wrap);
            };
            error_fn = function(result) {
                var config, data, err, headers, status, wrap;
                wrap = (data = result.data, status = result.status, headers = result.headers, config = result.config, 
                result);
                err = new error.type.Http(result);
                wrap.error = err;
                return callback(err, wrap);
            };
            promise.then(success_fn, error_fn);
            return promise;
        };
        return RestUtil;
    }();
} ]);

ksc.service("ksc.util", [ "ksc.error", function(error) {
    var Util, arg_check, define_property, define_value, get_own_property_descriptor, get_prototype_of, has_own, is_object;
    define_property = Object.defineProperty;
    get_own_property_descriptor = Object.getOwnPropertyDescriptor;
    get_prototype_of = Object.getPrototypeOf;
    arg_check = function(args) {
        if (!args.length) {
            return error.MissingArgument({
                name: "reference",
                argument: 1
            });
        }
    };
    Util = function() {
        function Util() {}
        Util.defineGetSet = function(object, key, getter, setter, enumerable) {
            if (typeof setter !== "function") {
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
        Util.empty = function() {
            var fn, i, key, obj, objects, _i, _j, _len, _ref, _ref1;
            objects = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            if (!objects.length) {
                error.MissingArgument({
                    argument: 1
                });
            }
            if (!is_object.apply(this, objects)) {
                error.Type({
                    arguments: objects,
                    required: "All arguments must be objects"
                });
            }
            for (_i = 0, _len = objects.length; _i < _len; _i++) {
                obj = objects[_i];
                if (Array.isArray(obj)) {
                    fn = obj.pop || ((_ref = obj._origFn) != null ? _ref.pop : void 0) || Array.prototype.pop;
                    for (i = _j = 0, _ref1 = obj.length; _j < _ref1; i = _j += 1) {
                        fn.call(obj);
                    }
                } else {
                    for (key in obj) {
                        if (!__hasProp.call(obj, key)) continue;
                        delete obj[key];
                    }
                }
            }
        };
        Util.hasOwn = function(object, key, is_enumerable) {
            return object && object.hasOwnProperty(key) && (is_enumerable == null || is_enumerable === object.propertyIsEnumerable(key));
        };
        Util.hasProperty = function(object, key) {
            while (object) {
                if (object.hasOwnProperty(key)) {
                    return true;
                }
                object = get_prototype_of(object);
            }
            return false;
        };
        Util.identical = function(comparable1, comparable2) {
            var key, v1;
            if (!is_object(comparable1, comparable2)) {
                return comparable1 === comparable2;
            }
            if (comparable1._array) {
                comparable1 = comparable1._array;
            }
            if (comparable2._array) {
                comparable2 = comparable2._array;
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
        Util.isEnumerable = function(object, key) {
            try {
                return !!get_own_property_descriptor(object, key).enumerable;
            } catch (_error) {}
            return false;
        };
        Util.isKeyConform = function(key, error_trigger, argument_n) {
            var err;
            if (!(typeof key === "string" && key || typeof key === "number" && !isNaN(key))) {
                if (error_trigger) {
                    if (typeof error_trigger !== "string") {
                        error_trigger = "Key conform value";
                    }
                    err = {
                        key: key,
                        description: error_trigger
                    };
                    if (argument_n) {
                        err.argument = argument_n;
                        error.ArgumentType(err);
                    } else {
                        error.Key(err);
                    }
                }
                return false;
            }
            return true;
        };
        Util.isFunction = function() {
            var ref, refs, _i, _len;
            refs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            arg_check(refs);
            for (_i = 0, _len = refs.length; _i < _len; _i++) {
                ref = refs[_i];
                if (typeof ref !== "function") {
                    return false;
                }
            }
            return true;
        };
        Util.isObject = function() {
            var ref, refs, _i, _len;
            refs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            arg_check(refs);
            for (_i = 0, _len = refs.length; _i < _len; _i++) {
                ref = refs[_i];
                if (!ref || typeof ref !== "object") {
                    return false;
                }
            }
            return true;
        };
        Util.mergeIn = function() {
            var i, key, object, source_objects, target_object, value, _i, _len;
            target_object = arguments[0], source_objects = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
            if (source_objects.length < 1) {
                error.MissingArgument({
                    required: "Merged and mergee objects"
                });
            }
            if (!is_object(target_object)) {
                error.Type({
                    target_object: target_object,
                    argument: 1,
                    required: "object"
                });
            }
            for (i = _i = 0, _len = source_objects.length; _i < _len; i = ++_i) {
                object = source_objects[i];
                if (!is_object(object)) {
                    error.Type({
                        object: object,
                        argument: i + 2,
                        required: "object"
                    });
                }
                for (key in object) {
                    value = object[key];
                    target_object[key] = value;
                }
            }
            return target_object;
        };
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
                    accepts: "object"
                });
            }
            return properties;
        };
        Util.uid = function(name) {
            var target, uid_store;
            uid_store = Util._uidStore != null ? Util._uidStore : Util._uidStore = {
                named: {}
            };
            if (name != null) {
                Util.isKeyConform(name, 1);
                target = uid_store.named;
            } else {
                target = uid_store;
                name = "unnamed";
            }
            return target[name] = (target[name] || 0) + 1;
        };
        return Util;
    }();
    define_value = Util.defineValue;
    has_own = Util.hasOwn;
    is_object = Util.isObject;
    return Util;
} ]);