/**
 * Created by Anykey on 21.07.2015.
 *
 * Provides bootstrap dynamic form rows
 */
'use strict';

var input_classes     = 'form-control';
var input_col_classes = 'col-md-9 col-sm-9';

var label_classes     = 'control-label';
var label_col_classes = 'col-md-3 col-sm-3';

function getInput(type, name, id, value, attr) {
  var $input = $('<input/>', {
    'class' : input_classes,
    type  : type,
    name  : name,
    id    : id,
    value : value
  });
  
  if (attr){
    $input.attr(attr);
  }
      
  return $input;
  
  //return '<input class="' + input_classes + '" type=' + type + ' name=' + name + ' id=' + id
  //    + (typeof value !== 'undefined' ? ' value="' + value + '" ' : '')
  //    + ' />'
}

function getSelect(name, id, options, selected) {
  var $select = $('<select></select>', {
    'class': "form-control",
    'name' : name,
    'id'   : id
  });
  
  for (var i = 0; i < options.length; i++) {
    var option = options[i];
    $select.append($('<option></option>',
        {
          value: option.value
        })
        .prop('selected', (option.value === selected))
        .text(option.label || option.name)
    );
  }
  
  
  return $select;
}

function getLabel(for_, text) {
  return $('<label></label>', {
    'class': label_classes + ' ' + label_col_classes,
    'for'  : for_
  }).text(text);
}

function getWrappedDiv(classes, elements_arr) {
  return getWrappedElement('div', classes, elements_arr);
}

function getWrappedElement(tag, classes, elements_arr) {
  var $res = $('<' + tag + '></' + tag + '>', {
    'class': classes
  });
  
  if ($.isArray(elements_arr)) {
    elements_arr.forEach(function (el) { $res.append(el) });
  }
  else {
    $res.html(elements_arr)
  }
  
  return $res;
}

/**
 * Returns a simple bootstrap form-group row with label and text typed input;
 *
 * @param name
 * @param id
 * @param label_text
 * @param value
 * @returns {*}
 */
function getSimpleRow(name, id, label_text, value) {
  return getWrappedDiv('form-group', [getLabel(id, label_text), getWrappedDiv(input_col_classes, getInput('text', name, id, value))]);
}

function getCheckboxRow(name, id, label_text) {
  // TODO: check for form-contol-static-class for checkbox
  return getWrappedDiv('form-group', [getLabel(id, label_text), getWrappedDiv('control-element', getInput('checkbox', name, id))]);
}


function getSelectRow(id, label, select) {
  var $label = getLabel(id, label);
  
  return getWrappedDiv('form-group', [$label, getWrappedDiv('col-md-9', select)]);
}
/**
 * Returns text of grouped simple rows
 * @param arrRows - two-dimensional array [[Input_name,Input_id,Label_value],[Input_name1,Input_id1,Label_value1]]
 */
function getMultiSimpleRow(arrRows) {
  var result = '';
  arrRows.forEach(function (row) {
    var name  = row[0];
    var id    = row[1];
    var label = row[2];
    result += getSimpleRow(name, id, label);
  });
  return result;
}

function getWrappedInForm(form_name, nullable_classes, element) {
  if (!nullable_classes) nullable_classes = '';
  return getWrappedElement('form name="' + form_name + '" id="' + form_name + '"', nullable_classes, element);
}

function parseCSV(CSVData) {
  var arrRows = CSVData.split('\n');
  console.log(arrRows);
  
  return true;
}

function wrap($element, classes) {
  $($element).wrap("<div class='" + classes + "'></div>");
}

window['ModalSelectChooser'] = function (selector, options) {
  
  var self      = this;
  this.selector = selector;
  this.$element = $('' + this.selector);
  if (!this.$element.length) {
    throw new Error('Can\' find element ' + selector);
  }
  
  this.onFinish = options.onFinish;
  
  this.event      = options.event;
  this.defaultUrl = options.url;
  this.items      = options.items;
  
  this.steps       = [];
  this.steps_count = 0;
  
  this.formURLParams = function (items) {
    var params = '';
    
    for (var key in items) {
      if (!items.hasOwnProperty(key)) continue;
      params += '&' + key + '=' + items[key];
    }
    
    
    return params;
  };
  
  this.nextStep = function (prev_option, prev_parent, recursive) {
    // Check next operation
    // Next can be written for option or for all option in select
    // Option.next has higher priority
    var next_step = prev_option.next || prev_parent.next;
    
    var should_load_next_step = (typeof next_step === 'undefined');
    console.log('should_load', should_load_next_step);
    
    if (!recursive) {
      // Add prev step to stash
      if (typeof (this.steps[prev_parent.name]) !== 'undefined') {
        this.clearAfter(prev_parent.name);
      }
      this.steps[prev_parent.name] = prev_option.value;
      this.steps_count++;
    }
  
    // Finish execution if no next step
    if (!next_step || next_step === 'finish') {
      return this.finish();
    }
    
    if (typeof next_step['load'] !== 'undefined') {
      
      var url = (next_step['load'] === 1)
          ? this.defaultUrl
          : next_step['load'];
      
      url += this.formURLParams(this.steps);
      
      $.getJSON(url, function (step) {
        console.log('received', step);
        // Saving responce to step as it was always defined there
        prev_option.next = step;
        
        // And call self with updated value
        self.nextStep(prev_option, prev_parent, true);
      });
      
      return false;
    }
    
    
    if (typeof next_step['select'] !== 'undefined') {
      this.appendSelect(next_step['select']);
    }
    else if (typeof next_step['input'] !== 'undefined') {
      this.appendInput(next_step['input']);
    }
    else if (typeof next_step['text'] !== 'undefined'){
      this.appendText(next_step['text']);
    }
    else {
      console.warn('Undefined next step for ', next_step);
    }
    
  };
  
  this.appendInput = function (input) {
    var $input    = getInput(input.type || 'text', input.name, input.name, '', input.attr);
    var input_row = getWrappedDiv('form-group', [getLabel(input.id, input.label), getWrappedDiv(input_col_classes, $input)]);
    
    // Add it to Page
    this.$element.append(input_row);
  };
  
  this.appendText = function(text){
    this.$element.append(
        $('<div></div>', {'class' : 'form-group text-center text-warning'})
        .html(
            $('<span></span>').text(text)
        )
    );
  };
  
  this.appendSelect = function (select) {
    if (!select.id) select.id = select.name;
    // Apply first select
    var $select    = getSelect(select.id, select.id, select.options, 0);
    var select_row = getSelectRow(select.id, select.label, $select);
    
    // Add it to Page
    this.$element.append(select_row);
    
    // Chosen should be called when rendered element
    $select.chosen(CHOSEN_PARAMS);
    $select.data('step', this.steps_count);
    
    $select.on('change', function () {
      var selected_value = $select.val();
      // Find option for this value;
      console.log(select.options);
      var option_found   = select.options.find(function (opt) {
        return '' + opt.value === '' + selected_value
      });
      
      console.log('change', selected_value, option_found, select);
      
      self.nextStep(option_found, select);
    });

  };
  
  this.clearAfter = function (name) {
    // Find current
    var elements = this.$element.find('[name="' + name + '"]')
    // Find parent div.form-group
        .parents('div.form-group').first()
        // Get all next div.form-group
        .nextAll();
    
    // In each div.form-group find select, we now have not to count
    elements.each(function (i, form_group) {
      var select = $(form_group).find('select');
      
      //if (!select.length) return true;
      var name = select.attr('name');
      
      delete self.steps[name];
    });
    // Remove all found div.form-group
    elements.remove();
  };
  
  this.finish = function(){
    Events.emit(self.event, self.steps);
    self.$element.empty();
    
    if (self.onFinish)
      self.onFinish(self.steps);
  };
  
  Events.on(this.selector + '.finish', self.finish);
  
  // Start
  this.appendSelect(options.select);
};
