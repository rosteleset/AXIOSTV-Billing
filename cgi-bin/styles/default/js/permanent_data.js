/**
 * Created by Anykey on 21.06.2016.
 *
 *  Manipulation of permanent data, stored in cookies or browser
 *
 */
'use strict';

function storageAvailable(type) {
  try {
    var storage = window[type],
        x = '__storage_test__';
    storage.setItem(x, x);
    storage.removeItem(x);
    return true;
  }
  catch(e) {
    return false;
  }
}

function AStorage(type){
  this.storageAvailable = storageAvailable(type);
}
AStorage.prototype = {
  setValue          : function (name, value) {
    localStorage.setItem(name, value);
  },
  getValue          : function (name, defaultValue) {
    var result = localStorage.getItem(name);
    if (result !== null && typeof (result) !== 'undefined') {
      return result;
    }
    else {
      this.setValue(name, defaultValue);
      return defaultValue;
    }
  },
  subscribeToChanges: function (name, callback) {
    if (window.addEventListener) {
      window.addEventListener('storage', function (e) {
        if (e.key === name) {
          callback(e.newValue, e.oldValue);
        }
      });
    }
    else {
      console.warn('[ AStorage ] subscribeToChanges is not available ')
    }
  }
};

var ACookieStorage = function () {
  
  this.setValue = function(name, value, expires) {
    Cookies.set(name, value, expires);
  };
  
  this.getValue = function(name, defaultValue) {
    var result = Cookies.get(name);
    if (result) {
      this.setValue(name, defaultValue);
      return defaultValue;
    }
    else {
      return result;
    }
  }
};

var aStorage = new AStorage('localStorage');
var aSessionStorage = new AStorage('sessionStorage');
var aCookieStorage = new ACookieStorage();

function setCookie(name, value, expires) {
  Cookies.set(name, value, expires);
}

function getCookie(name, defaultValue) {
  var result = Cookies.get(name);

  if (result) {
    setCookie(name, defaultValue);
    return defaultValue;
  }
  else {
    return result;
  }
}

function setPermanentValue(name, value) {
  if (typeof(Storage) !== "undefined") {
    localStorage.setItem(name, value);
  }
  else {
    setCookie(name, value);
  }
}

function getPermanentValue(name, defaultValue) {
  if (typeof(Storage) !== "undefined") {
    var result = localStorage.getItem(name);
    if (result) {
      return result;
    }
    else {
      setPermanentValue(name, defaultValue);
      return defaultValue;
    }
  }
  else {
    getCookie(name, defaultValue);
  }
}

function setSessionValue(name, value) {
  if (typeof(sessionStorage) !== "undefined") {
    sessionStorage.setItem(name, value);
  } else {
    setCookie(name, value);
  }
}

function getSessionValue(name, defValue) {
  if (typeof(sessionStorage) !== "undefined") {
    var result = sessionStorage.getItem(name);
    if (result) {
      return result;
    }
    else {
      setSessionValue(name, defValue);
      return defValue;
    }
  }
  else {
    getCookie(name, defValue);
  }
}

