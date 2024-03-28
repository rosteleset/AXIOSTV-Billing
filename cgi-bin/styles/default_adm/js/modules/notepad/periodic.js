/**
 * Created by Anykey on 22.06.2017.
 */

var predefined_rules = [
  'once',
  'every_day',
  'on_weekdays',
  'weekdays_list',
  'every_week',
  'every_month',
  'every_year'
];

$(function () {
  'use strict';
  
  var $rule_select = $('select#RULE_ID');
  
  var $all_togglable = $('div.show-hide-group');
  
  var $weekdays_wrapper = $('div#weekday_wrapper');
  var $mday_wrapper     = $('div#mday_wrapper');
  var $month_wrapper    = $('div#month_wrapper');
  //var $holidays_wrapper = $('div#holidays_wrapper');
  
  var $weekdays_select = $weekdays_wrapper.find('select');
  var $mday_input      = $mday_wrapper.find('input');
  var $month_select    = $month_wrapper.find('select');
  //var $holidays_chb    = $holidays_wrapper.find('input');
  
  $rule_select.on('change', function () {
    updateForm(this.value)
  });
  
  if ($rule_select.val()) {
    updateForm($rule_select.val(), true);
  }
  
  var $submit = $rule_select.parents('form').find('input[type="submit"]');
  
  $submit.on('click', function (e) {
    if ($weekdays_select.prop('required') && !$weekdays_select.val()) {
      cancelEvent(e);
      $weekdays_wrapper.addClass('has-error');
      $weekdays_select.trigger('chosen:activate');
    }
  });
  
  
  function updateForm(value, save_old_info) {
    var rule_name = predefined_rules[value];
    
    // Hide all
    $all_togglable.hide();
    $weekdays_select.prop('required', false);
    $mday_input.prop('required', false);
    $month_select.prop('required', false);
    
    switch (rule_name) {
      case 'on_weekdays' : {
        if (!save_old_info) {
          // Select first 5 days
          $weekdays_select.find('option').slice(1, 6).prop('selected', true);
        }
        
        $weekdays_select.prop('required', true);
        updateChosen();
        
        // Show and activate weekdays
        $weekdays_wrapper.show();
        break;
      }
      case 'weekdays_list' : {
        if (!save_old_info) {
          $weekdays_select.find('option').prop('selected', false);
        }
        
        $weekdays_select.prop('required', true);
        updateChosen();
        
        // Show and activate weekdays
        $weekdays_wrapper.show();
        break;
      }
      case 'every_week' : {
        // Make weekdays single
        if (!save_old_info) {
          $weekdays_select.find('option').prop('selected', false);
        }
        
        $weekdays_select.prop('required', true);
        updateChosen();
        
        // Show and activate weekdays
        $weekdays_wrapper.show();
        break;
      }
      case 'every_month': {
        // Show month_day select
        $mday_wrapper.show();
        $mday_input.prop('required', true);
        break;
      }
      case  'every_year': {
        // Show month_day select
        $mday_wrapper.show();
        $mday_input.prop('required', true);
        // Show month select
        $month_wrapper.show();
        $month_select.prop('required', true);
      }
    }
    
  }
  
});