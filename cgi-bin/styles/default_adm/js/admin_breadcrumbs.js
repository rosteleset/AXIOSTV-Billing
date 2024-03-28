/**
 * Created by Anykey on 21.06.2016.
 */

$(function () {
  'use strict';
  
  var HISTORY_KEY_NAME = 'admin_history';
  var HISTORY_LIMIT    = 10;
  
  var $breadcrumb_wrapper = $('#breadcrumb-wrapper');
  
  var path          = window.location.href;
  var current_name  = get_current_path_name();
  var locations_arr = get_history_arr();
  
  add_current_path_to_history();
  
  var dropdown_list = generate_history_menu_list(locations_arr);
  var history_btn   = generate_history_dropdown(current_name, dropdown_list);
  
  // Replacing old breadcrumb
  $breadcrumb_wrapper.html(history_btn);
  
  // Events handler
  $breadcrumb_wrapper.find('a').on('click', function (e) {
    e.preventDefault();
    var $this = $(this);
    var index = $this.data('index');
    
    return_to(index);
  });
  
  function add_current_path_to_history() {
    
    // Check we are not on the same page
    var last_history_entry = locations_arr[0] || '';
    
    if (path !== last_history_entry.path) {
      var name = get_current_path_name();
      add_history_entry(name, path);
    }
    
  }
  
  function get_current_path_name() {
    
    if (current_name != null) return current_name;
    
    var $breadcrumb = $('.breadcrumb');
    
    if ($breadcrumb.length == 1) {
      // Concatenate names of inner li elements
      var a_list = $breadcrumb.find('li>a');
      
      // Get name for first list item
      var name = $(a_list[0]).html();
      
      for (var i = 1, len = a_list.length; i < len; i++) {
        name += ' / ' + $(a_list[i]).html();
      }
      current_name = name;
    }
    else {
      current_name = document.title;
    }
    
    return current_name;
  }
  
  function get_history_arr() {
    var history_string = getSessionValue(HISTORY_KEY_NAME, "[]");
    
    try {
      return JSON.parse(history_string) || [];
    }
    catch (JSONParseError) {
      console.log(JSONParseError);
      return [];
    }
    
  }
  
  function add_history_entry(title, path) {
    locations_arr.unshift({title: title, path: path});
    save_history(locations_arr);
  }
  
  function save_history(new_history) {
    
    var obsolete_elements_count = new_history.length - HISTORY_LIMIT;
    
    if (obsolete_elements_count > 0) {
      while (obsolete_elements_count--) {
        
        new_history.pop();
      }
    }
    
    var new_history_string = JSON.stringify(new_history);
    
    setSessionValue(HISTORY_KEY_NAME, new_history_string);
  }
  
  function return_to(linkIndex) {
    var link_to_go = locations_arr[linkIndex];
    window.location.replace(link_to_go.path);
  }
  
  function generate_history_menu_list(history_array) {
    var list = '<ul class="dropdown-menu">';
    
    $.each(history_array, function (i, e) {
      list += '<li><a data-index="' + i + '" href="' + e.path + '">' + e.title + '</a></li>'
    });
    
    list += '</ul>';
    return list;
  }
  
  function generate_history_dropdown(name, list) {
    return '<div class="btn-group">'
        + '<button type="button" class="btn btn-secondary dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">'
        + name + ' <span class="caret"></span>'
        + '</button>'
        + list
        + '</div>';
  }
  
  
});