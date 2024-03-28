/**
 * Created by Anykey on 08.11.2016.
 */
'use strict';
function initCopyButton() {
  var copyTextareaBtn = document.querySelector('.js-textareacopybtn');
  
  if (copyTextareaBtn)
    copyTextareaBtn.addEventListener('click', function (event) {
      var copyTextarea  = document.querySelector('.js-copytextarea');
      var $copyTextarea = $(copyTextarea);
      
      var text = $copyTextarea.text();
      text     = text.replace(/ttextarea/g, 'textarea');
      
      $copyTextarea.text(text);
      
      copyTextarea.select();
      
      try {
        document.execCommand('copy');
        document.getSelection().removeAllRanges();
      }
      catch (err) {
        alert('Oops, unable to copy');
      }
    });
}

function initAddFieldModalButton() {
  var $modal     = $('#addNewFieldModal');
  var $modalBody = $modal.find('#addNewFieldModalBody');
  var clearBody  = $modalBody.html();
  
  var openModalBtn = $('#addNewFieldButton');
  
  openModalBtn.on('click', function () {
    $modal.modal('show');
  });
  
  $modal.on('show.bs.modal', initModalLogic);
  
  $modal.on('hidden.bs.modal', function () {
    $modalBody.html(clearBody);
  });
  
}

function initModalLogic() {
  var $modal       = $('#addNewFieldModal');
  var $type_select = $modal.find('select#TYPE');
  
  var $name        = $modal.find('input#NAME');
  var $label       = $modal.find('input#LABEL');
  var $placeholder = $modal.find('input#PLACEHOLDER');
  var $required    = $modal.find('input#REQUIRED');
  
  $name.on('input', function () {
    var text = this.value;
    var type = $type_select.val();
    var text_upper = text.toUpperCase();
    
    $name.val(text_upper);
    
    // If select, there's propably '_ID' part we don't want in label
    if (type === 'select' && text_upper.length > 4){
      if (text_upper.substr(text_upper.length - 3, text_upper.length) === '_ID'){
        text_upper = text_upper.substr(0, text_upper.length - 3);
      }
    }
    
    $label.val('_{' + text_upper + '}_');
    
  });
  
  $type_select.on('change', function () {
    showAllFields();
    
    switch (this.value) {
      case 'textarea':
      case 'select':
      case 'checkbox':
        hideFields([$placeholder]);
        break;
      case 'hidden' :
        hideFields([$placeholder, $label, $required]);
        break;
      case 'collapse':
        hideFields([$placeholder, $required]);
        break;
      case 'collapse_':
        hideFields([$placeholder, $required, $label, $name]);
        break;
    }
  });
}

function showAllFields() {
  var $modal = $('#addNewFieldModal');
  $modal.find('div.form-group,div.checkbox').show();
}

function hideFields(field_$elements_array) {
  $.each(field_$elements_array, function (i, e) {
    getElementFormGroup(e).hide();
  });
}

function getElementFormGroup($element) {
  if ($element.is('[type="checkbox"]')) return $element.parents('div.checkbox').first();
  return $element.parents('div.form-group').first();
}

function readFormInputs($context) {
  var result  = {};
  var $inputs = $context.find('select,input');
  
  $.each($inputs, function (i, element) {
    var $element = $(element);
    var name     = $element.attr('name');
    
    var val = '';
    if ($element.is('[type="checkbox"]')) {
      val = ($element.prop('checked')) ? 1 : 0;
    }
    else {
      val = $element.val();
    }
    result[name] = val;
  });

  return result;
}

function formValueRowText(attributes) {
  var result = [];
  switch (attributes['TYPE']) {
    case 'hidden' :
      result = [
        attributes['TYPE'],
        attributes['NAME']
      ];
      break;
    case 'text':
      result = [
        attributes['TYPE'],
        attributes['LABEL'] || '',
        attributes['NAME'] || '',
        attributes['PLACEHOLDER'] || '',
        attributes['REQUIRED'] || 0
      ];
      break;
    case 'textarea':
    case 'checkbox':
    case 'select':
      result = [
        attributes['TYPE'],
        attributes['LABEL'] || '',
        attributes['NAME'] || '',
        attributes['REQUIRED'] || 0
      ];
      break;
    case 'collapse':
      result = [
        attributes['TYPE'],
        attributes['LABEL'] || '',
        attributes['NAME'] || ''
      ];
      break;
    case 'collapse_':
      result = [
        attributes['TYPE']
      ];
      break;
  }
  
  return result.join(':');
}

function addFieldRow(attr) {
  var $textarea = $('textarea#INPUT');
  
  var form_row = formValueRowText(attr);
  
  var current_text = $textarea.val();
  
  $textarea.val(current_text + ((current_text) ? '\n' : '') + form_row);
}

function initAddFieldModal() {
  var $modal     = $('#addNewFieldModal');
  var $addButton = $modal.find('#addButton');
  
  var textarea = $('textarea#INPUT');
  
  // Fill default values
  if (!textarea.val()) {
    addFieldRow({
      TYPE: 'hidden',
      NAME: 'ID'
    });
    addFieldRow({
      TYPE       : 'text',
      NAME       : 'NAME',
      LABEL      : '_{NAME}_',
      REQUIRED   : 1
    });
    addFieldRow({
      TYPE : 'textarea',
      NAME : 'COMMENTS',
      LABEL: '_{COMMENTS}_'
    });
  }
  
  $addButton.on('click', function () {
    var values = readFormInputs($modal);
    addFieldRow(values);
    
    $modal.modal('hide');
  })
  
}

jQuery(function () {
  initCopyButton();
  initAddFieldModalButton();
  initAddFieldModal();
});