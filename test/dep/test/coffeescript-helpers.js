
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

