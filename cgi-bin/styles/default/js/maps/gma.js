/**
 * Created by Anykey on 02.06.2016.
 */

"use strict";

var build = {
  city         : "Коломия",
  coordx       : "0.00000000000000",
  coordy       : "0.00000000000000",
  country      : "804",
  district_id  : "1",
  district_name: "Main District",
  full_address : "Коломия, Main District, Моцарта, 1",
  id           : "2",
  number       : "1",
  postalCode   : "78200",
  street_id    : "2",
  street_name  : "Моцарта"
};

var result = {
  add_index   : "199",
  message     : "Нема результатів",
  requested_id: "2",
  set_class   : "danger",
  status      : "2"
};


$(function () {
  
  var single_coord_index = window['single_coord_index'];
  
  var builds_to_process = [];
  var builds_count      = 0;
  var build_with_id     = {};
  
  var aProgressBar = null;
  
  function updateBuilds(new_builds) {
    builds_to_process = new_builds;
    builds_count      = new_builds.length;
    
    build_with_id = {};
    $.each(builds_to_process, function (i, build) {
      build_with_id[build.id] = build;
    });
    
    console.log('update');
    
    if (aProgressBar !== null) aProgressBar.destroy();
    aProgressBar = new AProgressBar('progress_status', builds_count);
  }
  
  updateBuilds(window['builds_for_auto_coords']);
  
  var ATableModifier = (function () {
    
    var position_of = {
      ID     : 0,
      ADDRESS: 1,
      STATUS : 2,
      BUTTON : 4
    };
    
    var $table = $('#GMA_TABLE_ID_');
    
    var table_row_for_id = {};
    
    function updateIndex(callback) {
      
      $table.find('tr').map(function (index, entry) {
        var $entry           = $(entry);
        var id               = $entry.find('td').first().text();
        table_row_for_id[id] = $entry;
      });
      
      var params = {
        qindex                : INDEX,
        header                : 2,
        GET_UNFILLED_ADDRESSES: 1
      };
      
      $.extend(params, ABuildProcessor.getFormParams());
      
      $.getJSON('?' + $.param(params), function (data) {
        if (callback) callback(data);
      });
      
    }
    
    function reloadTable() {
      ABuildProcessor.setInputsLocked(true);
      
      var form_params = ABuildProcessor.getFormParams();
      
      $.extend(form_params, {
        index: INDEX
      });
      
      var params = $.param(form_params);
      
      $table.load(SELF_URL + ' #GMA_TABLE_ID_', params, function () {
        updateIndex(function (new_builds) {
          updateBuilds(new_builds);
          ABuildProcessor.setInputsLocked(false);
        });
      });
    }
    
    function handleStatus(status, result) {
      // Set class
      var id = result.requested_id;
      
      table_row_for_id[id].attr('class', 'text-' + result.set_class);
      
      var $status_td = $(table_row_for_id[id].children('td')[position_of.STATUS]);
      $status_td.text(result.message);
    }
    
    return {
      reloadTable : reloadTable,
      updateIndex : updateIndex,
      handleStatus: handleStatus
    }
    
  })();
  
  
  var ABuildProcessor = (function () {
    
    var $exec_btn         = $('#GMA_EXECUTE_BTN');
    var $stop_btn         = $('#GMA_STOP_BTN');
    var $country_code_inp = $('#COUNTRY_CODE_id');
    var $districts_chb    = $('#DISTRICTS_ARE_NO_REAL');
    var $districts_select = $('select#DISTRICT_ID');
    var $streets_select   = $('select#STREET_ID');
    var $zip_code_inp     = $('input#ZIP_CODE_ID');
  
    var current_request = null;
    var stopped = false;
    
    $districts_chb.on('change', function () {
      ATableModifier.reloadTable();
    });
    
    $districts_select.on('change', function () {
      ATableModifier.reloadTable();
      $.getJSON('?qindex=70&header=2&json=1&chg=' + jQuery(this).val(), function(district_info){
        try {
          $zip_code_inp.val(district_info['_INFO']['ZIP']);
        }
        catch (Error){
          console.log("Can't load ZIP_CODE : " + Error);
        }
      });
      
      $streets_select.load('?qindex=30&address=1&DISTRICT_ID=' + this.value);
    });
    
    $streets_select.on('change', function () {
      ATableModifier.reloadTable();
    });
    
    $exec_btn.on('click', function () {
      setInputsLocked(true);
      startExecution();
    });
    
    $stop_btn.on('click', function(){
      stopExecution();
      setInputsLocked(false);
    });
    
    function startExecution() {
      aProgressBar.set(0);
      stopped = false;
      requestCoordsFor(0);
      $exec_btn.css({ display : 'none' });
      $stop_btn.css({ display : 'inline-block' });
    }
    
    function stopExecution(){
      stopped = true;
      if (current_request !== null){
        current_request.abort();
      }
      
      $exec_btn.css({ display : 'inline-block' });
      $stop_btn.css({ display : 'none' });
    }
    
    function getFormParams() {
      
      var params = {
        COUNTRY_CODE          : $country_code_inp.val(),
        DISTRICTS_ARE_NOT_REAL: $districts_chb.prop('checked') ? 1 : 0
      };
      
      var districts_val =  $districts_select.val();
      if (districts_val){
        params['DISTRICT_ID'] = districts_val;
      }
      
      var street_val = $streets_select.val();
      if (street_val){
        params['STREET_ID'] = street_val;
      }
      
      return params;
    }
    
    function requestCoordsFor(index_of_build) {
      
      var build = builds_to_process[index_of_build];
      
      // Exit from recursion
      if (stopped || index_of_build >= builds_to_process.length) {
        stopExecution();
        current_request = null;
        setInputsLocked(false);
        return true;
      }
      
      var zip_code               = $zip_code_inp.val();
      var country_code           = $country_code_inp.val();
      var districts_are_not_real = $districts_chb.prop('checked');
      var district_name          = (districts_are_not_real) ? '' : ( build.district_name + ", ");
      var requested_addr         = country_code + ' '
          + build.city + ', '
          + district_name
          + build.street_name + ', '
          + build.number;
      
      var params = {
        qindex         : single_coord_index,
        header         : 2,
        //json : 1,
        REQUEST_ADDRESS: requested_addr,
        BUILD_ID       : build.id
      };
      if (zip_code){
        params['ZIP_CODE'] = zip_code;
      }
      
      current_request = $.getJSON(SELF_URL, $.param(params), function (responce) {
        aProgressBar.update(1, responce.status);
        
        ATableModifier.handleStatus(responce.status, responce);
        
        if (responce.status < 500) {
          // Recursive async requests
          debounce(function(){requestCoordsFor(index_of_build + 1)}, 1000)();
        }
        else {
          aProgressBar.setMax();
          aProgressBar.setClass('progress-bar-danger');
        }
        
      })
    }
    
    function setInputsLocked(boolean) {
      (boolean) ? $exec_btn.addClass('disabled') : $exec_btn.removeClass('disabled');
      $districts_chb.prop('disabled', boolean);
      $districts_select.prop('disabled', boolean);
      $streets_select.prop('disabled', boolean);
      updateChosen();
    }
    
    return {
      setInputsLocked: setInputsLocked,
      getFormParams  : getFormParams
    }
  })();
  
  ATableModifier.updateIndex();
  
  function AProgressBar(id, max_count) {
    this.max_value     = max_count;
    this.$progress_bar = $('#' + id);
    this.progress      = 0;
    this.current_class = 'progress-bar-success';
    
    this.update = function (value) {
      // Overall progress
      this.progress += value;
      this.setWidth(this.progress);
    };
    
    this.set = function (value) {
      this.progress = value;
      this.setWidth(this.progress);
    };
    
    this.setClass = function (new_class) {
      this.$progress_bar.removeClass(this.current_class);
      this.$progress_bar.addClass(new_class);
    };
    
    this.setMax = function () {
      this.set(this.max_value);
    };
    
    this.setWidth = function (progress) {
      var new_width     = progress / this.max_value * 100;
      var new_width_int = Math.round(new_width);
      this.$progress_bar.attr('style', 'width : ' + new_width_int + '%');
    };
    
    this.destroy = function () {
      this.set(0);
      this.setClass('progress-bar-success');
    }
  }
});