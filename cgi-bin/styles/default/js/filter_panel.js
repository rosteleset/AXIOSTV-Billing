/**
 * Created by Anykey on 10.10.2016.
 */
'use strict';

function FilterPanel(id, options) {
  
  this.element = $('#' + id);
  
  
  
  this.init = function (options) {
    for (var key in options) {
      if (!options.hasOwnProperty(key)) continue;
      
      var column_type = options[key];
      
      // Check if is list
      if ($.isArray(column_type)) {
        addArraySelect(key, column_type);
        continue;
      }
      
      switch (column_type) {
        case ('STR'):
          addStrSelect(key);
          break;
        case ('INT'):
          addIntSelect(key);
          break;
        case ('DATE'):
          addDateSelect(key);
          break;
        default:
          console.warn('[ Filter panel ] unknown type :', column_type);
      }
    }
  };
  
  
  function addArraySelect(name, options) {
    
  }
  
  function addIntSelect(name) {
    
  }
  
  function addStrSelect(name) {
    
  }
  
  function addDateSelect(name) {
    
  }
  
}
