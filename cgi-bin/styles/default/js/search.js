/**
 * Created by Anykey
 * Version 0.15
 *
 *  Uses dynamicForms.js;
 *
 */
'use strict';
if (typeof(window['getSimpleRow']) === 'undefined')
  $.getScript('/styles/default/js/dynamicForms.js');

/*Global section*/
jQuery(document).ready(function(){
  $('.clear_results').click(function (event) {
    cancelEvent(event);
    $(this).parents('.input-group').find('input').val('').change();
  });
})

/**
 * Makes one row form for going to specified index with a GET parameter;
 * @param params
 */
function fillOneRowArrayBasedSearchForm(params) {
  var label         = params[0];
  var name          = params[1];
  var index         = params[2];
  var url           = params[3];
  var custom_params = params[4] || '';
  var id            = 'popup_' + name;
  
  var search_row_input = getSimpleRow(name, id, label);
  
  var data =
          "<div class='modal-content'>" +
          "<div class='modal-header'>" +
          "<div class='modal-title'>Search for <b>" + name + "</b></div>" +
          "<button type='button' class='close' data-dismiss='modal' aria-label='Close'><span aria-hidden='true'>&times;</span></button>" +
          "</div>" +
          "<div class='modal-body form-horizontal'>" +
           search_row_input[0].outerHTML +
          "</div>" +
          "<div class='modal-footer'>" +
          "<a id='btn_popup_" + name + "' class='btn btn-primary' href=''>" + "Go</a>" +
          "</div>" +
          "</div>";
  
  aModal.clear()
      .setRawMode(true)
      .setBody(data)
      .show(function () {
        $('#' + id).on('change', function () {
          $('#btn_popup_' + name).attr('href', href(url, index, name, custom_params));
        });
      })
  
}

/**
 * fill Array based multi-row search popup window
 */
function fillArrayBased(params) {
  var modalData = openAsSearchForm(getMultiSimpleRow(params));
  loadDataToModal(modalData);
}

//function fillArrayBasedSearch(params, stringCSV_URL) {
//  var modalData = openAsSearchForm(getMultiSimpleRow(params), stringCSV_URL);
//  loadDataToModal(modalData);
//}

/**
 * get some variables values from DOM input with specified name
 *
 * $("input[name|=SELECTOR]").val();
 * @param strInputName
 */
function getInputVal(strInputName) {
  return $("input[name|=" + strInputName + "]").val();
}

function setupSearchForm(popup_name, formURL) {
  // Set up inner window logic
  var $search_button = $('button#search');
  var have_results   = $('.clickSearchResult').length > 0;
  
  if ($search_button.length) {
    $search_button.on('click', function () {
      getDataURL(formURL, function () {
        makeChoosableTr(popup_name);
      });
    });
  }
  
  if (have_results) {
    makeChoosableTr(popup_name);
  }
  
  if (typeof (should_open_results_tab) !== 'undefined' && should_open_results_tab === '1') {
    enableResultPill();
  }
  console.log('setuop');
}

function fillTemplateBasedSearchForm(template_params, size) {
  var formURL           = template_params[0];
  var popup_name        = template_params[1];
  var parent_input_name = template_params[2];
  var searchString      = template_params[3];
  var window_type       = template_params[4];
  
  if (parent_input_name !== '') {
    searchString += "&" + parent_input_name + "=" + getInputVal(parent_input_name);
  }
  
  console.log('search_string : \'' + searchString + "\'");
  
  if (window_type === 'choose') {
    
    loadRawToModal(
        //Origin
        formURL + '?' + searchString,
        
        // Callback
        function () {
          makeChoosableTd(popup_name);
          bindClickSearchResult(popup_name);
        },
        
        //Size
        size
    );
    
    setupSearchForm(popup_name, formURL);
  }
  
  if (window_type === 'search') {
    loadRawToModal(formURL + '?' + searchString, function () {
      setupSearchForm(popup_name, formURL)
    });
  }
}

function makeChoosableTd(popup_name) {
  $('td').on('click', function () {
    fillSearchResults(popup_name, $(this).text());
  });
}

function makeChoosableTr(popup_name) {
  
  if (!popup_name) {
    console.warn('Wrong popup_name', popup_name);
    return false;
  }
  
  $('tr').on('click', function () {
    var $clickSearchResult = $(this).find('.clickSearchResult');
    fillSearchResults(popup_name, $clickSearchResult.attr('data-value'));
  });
  
}

function bindClickSearchResult(popup_name) {
  $('.clickSearchResult').on('click', function (event) {
    event.stopPropagation();
    fillSearchResults(popup_name, $(this).attr('value') || $(this).data('value'));
    aModal.hide();
  });
}

function fillSearchResults(popup_name, data_value) {
  
  if (data_value.match('#@#')) {
    var key_value_arr = data_value.split('#@#');
    
    for (var i = 0; i < key_value_arr.length; i++) {
      var current_name_value = key_value_arr[i].split('::');
      var input_name         = current_name_value[0];
      var input_value        = current_name_value[1];
      
      //$("input[name|='" + input_name + "1']").val(input_value);
      var $select = $("select[name|='" + input_name + "']");
      if ($select.length) {
        renewChosenValue($select, input_value)
      }
      else {
        $("input[name|='" + input_name + "']").val(input_value).change();
        Events.emit('search_form.value_selected.' + input_name, data_value);
      }
    }
  }
  else {
    $("input[name|='" + popup_name + "']").val(data_value).change();
    $("input[name|='" + popup_name + "1']").val(data_value);
    Events.emit('search_form.value_selected.' + popup_name, data_value);
  }
  
  aModal.hide();
  $('#modalContent').html('');
}

function openAsSearchForm(formContent, formSearchURL) {
  var str_func_close = '$("#PopupModal").hide();';
  
  var ddata = '';
  ddata += "<div class='modal-content'>";
  ddata += "  <div class='modal-header'>";
  ddata += "    <div class='row'>";
  ddata += "      <div class='hidden-xs col-sm-4 col-md-4 col-lg-4'></div>";
  ddata += "      <div class='hidden-xs col-md-4'>";
  ddata += "        <div class='text-centered'>";
  ddata += "          <input type='button' class='btn' data-toggle='dropdown' onclick='enableSearchPill();' value='Search' />";
  ddata += "          <input type='button' class='btn' data-toggle='dropdown' onclick='enableResultPill();' value='Result' />";
  ddata += "        </div>";
  ddata += "      </div>";
  ddata += "      <div class='hidden-xs col-sm-3 col-md-3 col-lg-3'></div>";
  ddata += "      <div class='col-md-1 col-xs-1 col-lg-1 col-sm-1 float-right'>";
  ddata += "        <button type='button' class='close' onclick='" + str_func_close + "'>";
  ddata += "          <span aria-hidden='true'>&times;</span>";
  ddata += "        </button>";
  ddata += "      </div>";
  ddata += "    </div>";
  ddata += "   </div>";
  ddata += " <div class='modal-body'>";
  ddata += "<div id='search_pill' class='dropdown-toggle'>";
  ddata += '<form id="form-search" name="frmSearch" class="form-horizontal">';
  ddata += getWrappedInForm('frmSearch', 'form-horizontal', formContent);
  ddata += "</form>";
  ddata += "</div>";
  ddata += "<div id='result_pill' class='dropdown-toggle hidden'>";
  ddata += "<h1 class='text-centered'>Please search before trying get result</h1>";
  ddata += "</div>";
  ddata += " </div>";
  ddata += "  <div class='modal-footer'>";
  ddata += getGetDataURLBtn(formSearchURL);
  ddata += "  </div>";
  ddata += "</div>";
  
  return ddata;
}

/**
 *  function forms GET request and returns reply in modal #Result_pill;
 */
function getDataURL(formURL, callback) {
  
  var request_string = $('#form-search').serialize();
  console.log(request_string);
  $.get(
      formURL, request_string,
      function (data) {
        enableResultPill();
        $('#result_pill').empty().append(data);
        
        if (callback) callback();
      }
  );
}

function href(url, index, name, custom_params) {
  var value   = $('#popup_' + name).val();
  var request = "?" + custom_params + "&index=" + index + "&" + name + "=" + value;
  return url + request;
}

function hrefIndex(url, index) {
  return url + "?index=" + index;
}

function hrefValue(url, index, name, value) {
  return hrefIndex(url, index) + "&" + name + "=" + (value || getInputVal(name));
}

function replace(url) {
  location.replace(url);
}

function getGetDataURLBtn() {
  return "<button class='btn btn-primary form-control' onclick='getDataURL()' > Search </button>"
}


//buttons
function enableSearchPill() {
  if ($('#search_pill').hasClass('hidden')) {
    $('#search_pill').removeClass('hidden');
    $('#result_pill').addClass('hidden');
    $('button#search').removeClass('hidden');
  }
}

function enableResultPill() {
  if ($('#result_pill').hasClass('hidden')) {
    $('#search_pill').addClass('hidden');
    $('#result_pill').removeClass('hidden');
    $('button#search').addClass('hidden');
  }
}
