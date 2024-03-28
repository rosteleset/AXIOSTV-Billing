/**
 * Created by Anykey on 25.04.2017.
 */

/**
 * DynamicTable is wrapper above DOM <table> that is aware of its headings, rows, columns
 * @constructor
 */

var DynamicTable = function (id, options) {
  var self   = this;
  this.table = jQuery('#' + id);
  
  if (!this.table.length) {
    alert('Wrong id');
    throw new Error('Wrong table id passed : ' + id);
  }
  
  this.thead = this.table.find('thead');
  this.tbody = this.table.find('tbody');
  
  this.rows        = [];
  this.tds_for_row = [];
  this.headings    = [];
  
  this.renewDOM();
  
  if (options.headings) {
    this.headings_selectable = options.headings;
    this.setSelectableHeadings(this.headings_selectable);
  }
  this.headings.last().after(this.getAddColumnButton());
  
  this.add_row_btn = this.getAddRowButton();
  this.table.after(this.add_row_btn);
};

DynamicTable.prototype.renewDOM = function () {
  var self = this;
  
  // Collect headings
  this.headings = this.thead.find('tr').first().find('th');
  
  if (this.headings_selectable) {
    this.headings.each(function (number, heading) {
      jQuery(heading).find('div.dropdown').data('dropdown_selectable').num = number;
    });
  }
  
  // Collect rows
  this.rows = this.tbody.find('tr');
  
  // Collect columns
  this.rows.each(function (row_num, row) {
    self.tds_for_row[row_num] = jQuery(row).find('td');
  })
};

DynamicTable.prototype.getRow = function (row_num) {
  return this.rows[row_num];
};

DynamicTable.prototype.getRows = function () {
  return this.rows;
};

DynamicTable.prototype.getTd = function (row_num, col_num) {
  return this.tds_for_row[row_num].get(col_num);
};

DynamicTable.prototype.getTdsForColumn = function (col_num) {
  // For each table row, retrieve it's *num* td
  return this.rows.map(function () {
    return jQuery(this).find('td').get(col_num);
  });
};

DynamicTable.prototype.getHeading = function (head_num) {
  return this.headings.get(head_num);
};

DynamicTable.prototype.getHeadings = function () {
  return this.headings;
};

DynamicTable.prototype.appendRow = function (e) {
  cancelEvent(e);
  var row_num = this.rows.length;
  
  var new_row = jQuery('<tr></tr>');
  for (var i = 0; i < this.headings.length; i++) {
    var dropdown = jQuery(this.headings[i]).find('div.dropdown').data('dropdown_selectable');
    var name     = dropdown.value;
    
    var new_input = jQuery('<input/>', {
      'class'                    : 'form-control',
      'type'                     : 'text',
      name                       : row_num + '_' + name,
      id                         : row_num + '_' + name,
      'data-original-column-name': name,
      'data-original-column-row' : row_num,
      placeholder                : this.headings_selectable.getColumnName(name) || name
    });
    
    new_row.append(jQuery('<td></td>').html(new_input));
  }
  
  this.tbody.append(new_row);
  
  this.renewDOM();
  
};

DynamicTable.prototype.deleteRow = function (row_num) {

};

DynamicTable.prototype.appendColumn = function (after_col_) {
  
  var after_col = isDefined(after_col_)
      ? after_col_
      : (this.headings.length - 1);
  
  // Append td forEachRow
  // This should go first, because DropdownSelectable will look for this tds when created
  this.rows.map(function () {
    var new_input = jQuery('<input/>').addClass('form-control');
    jQuery('<td/>').html(new_input).insertAfter(jQuery(this).find('td').get(after_col));
  });
  
  // Append new DropdownSelectable
  var selectableHeading = new DropdownSelectable(after_col + 1, {
    options: this.headings_selectable,
    table  : this
  });
  
  jQuery('<th/>').html(selectableHeading).insertAfter(this.getHeading(after_col));
  
  this.renewDOM();
};

DynamicTable.prototype.deleteColumn = function (col_num) {
  this.getTdsForColumn(col_num).remove();
  this.getHeading(col_num).remove();
  this.renewDOM();
};

DynamicTable.prototype.setSelectableHeadings = function (possible_columns) {
  var self = this;
  // Before creating dropdown, should set active all existing headers
  this.headings.each(function (i, th) {
    var col_name = jQuery(th).text();
    possible_columns.setState(col_name, true);
  });
  
  this.headings.each(function (i, col) {
    var jcol = jQuery(col);
    
    var col_name = jcol.text();
    
    var selectableHeading = new DropdownSelectable(i, {
      options : possible_columns,
      selected: col_name,
      table   : self
    });
    
    jcol.html(selectableHeading);
  });
  
  jQuery('input[data-event-onchange=1]').on('input', function () {
    Events.emit('input_change.' + this.id, this.value);
  });
};

DynamicTable.prototype.getColumnNumForName = function (name) {
  
  for (var i = 0; i < this.headings.length; i++) {
    var dropdown = jQuery(this.headings[i]).find('div.dropdown').data('dropdown_selectable');
    if (dropdown && dropdown.value && dropdown.value === name) {
      return i;
    }
  }
  
  throw new Error("Can't find column for : " + name);
};

DynamicTable.prototype.getInputsForName = function (name) {
  var col_num = this.getColumnNumForName(name);
  var tds     = this.getTdsForColumn(col_num);
  
  return tds.map(function (i, td) {
    return jQuery(td).find('input');
  });
};

DynamicTable.prototype.getAddColumnButton = function () {
  var self = this;
  
  return jQuery('<button></button>')
      .text('+')
      .addClass('form-control btn-success')
      .on('click', function (e) {
        cancelEvent(e);
        self.appendColumn();
      });
};

DynamicTable.prototype.getAddRowButton = function () {
  var self = this;
  
  return jQuery('<button></button>')
      .text('+')
      .addClass('form-control btn-success')
      .on('click', self.appendRow.bind(self));
};

var PossibleColumns = function (columns) {
  var self = this;
  
  this.columns   = columns;
  this.col_names = Object.keys(columns);
  
  // Holds register for used columns (to prevent duplicates)
  this.registry = {};
  
  this.setState = function (column, state) {
    this.registry[column] = state;
    Events.emit('PossibleColumns.column_state_change', {column: column, state: state});
  };
  
  this.isColumnActive = function (column) {
    return this.registry.hasOwnProperty(column) && this.registry[column] === true;
  };
  
  this.hasColumn = function (column) {
    return this.columns.hasOwnProperty(column);
  };
  
  this.getColumnName = function (column) {
    return this.columns[column];
  };
  
  this.getView = function (current, onclick) {
    var self = this;
    var menu = jQuery('<ul/>', {'class': 'dropdown-menu'});
    
    this.col_names.forEach(function (col_name) {
      var new_a  = jQuery('<a/>', {'data-target': '#', 'data-value': col_name});
      var new_li = jQuery('<li>');
      
      if (col_name === current) {
        new_li.addClass('active');
      }
      else if (self.registry[col_name] === true) {
        new_li.addClass('disabled');
      }
      
      new_a.on('click', onclick);
      
      menu.append(
          new_li
              .html(new_a.text(self.getColumnName(col_name)))
      )
      
    });
    
    var delete_a  = jQuery('<a/>', {'data-target': '#', 'data-value': 'delete'})
        .css("color", "#fff")
        .text(importTranslate('REMOVE'));
    var delete_li = jQuery('<li>').addClass('bg-red');
    
    delete_a.on('click', onclick);
    menu.append(delete_li.html(delete_a));
    
    Events.off('PossibleColumns.column_state_change');
    Events.on('PossibleColumns.column_state_change', function (col_changed) {
      var state    = col_changed.state;
      var col_name = col_changed.column;
      
      var column_li = menu.find('a[data-value=' + col_name + ']').parent();
      
      if (col_name === current) {
        state
            ? column_li.addClass('active')
            : column_li.removeClass('active');
      }
      
      state
          ? column_li.addClass('disabled')
          : column_li.removeClass('disabled');
      
    });
    
    return menu;
  }
};

function DropdownSelectable(num, attr) {
  var self = this;
  
  this.all_options = attr.options;
  this.all_values  = Object.keys(attr.options);
  this.num         = num;
  this.value       = attr.selected;
  
  this.table    = attr.table;
  this.tds      = attr.table.getTdsForColumn(num);
  this.dropdown = jQuery('<div/>', {'class': 'dropdown'}).data('dropdown_selectable', self);
  
  var hasValue = this.all_options.hasColumn(this.value);
  this.button  = this.createButtonHTML(hasValue);
  this.setValue(this.value);
  
  // Update button after select was made
  this.dropdown.on('hidden.bs.dropdown', function () {
    if (self.all_options.hasColumn(self.value) && self.button.hasClass('btn-warning')) {
      self.button.addClass('btn-primary');
      self.button.removeClass('btn-warning');
    }
  });
  
  // Writes this.menu as side effect
  this.dropdownRenew();
  
  this.dropdown.empty()
      .append(this.button)
      .append(this.menu);
  
  return this.dropdown;
}

DropdownSelectable.prototype.createButtonHTML = function (hasSelected) {
  return jQuery('<button/>', {
    'class'      : 'dropdown-toggle form-control btn-' + (hasSelected ? 'primary' : 'warning'),
    'type'       : 'button',
    'data-toggle': 'dropdown'
  });
  
};

DropdownSelectable.prototype.renewButtonHTML = function (html) {
  if (!html) {
    html = importTranslate('CHOOSE');
  }
  
  this.button.html(html + '<span class="caret"></span>');
};

DropdownSelectable.prototype.setValue = function (value) {
  this.value     = value;
  var translated = this.all_options.getColumnName(value);
  
  this.renewButtonHTML(translated);
  
  this.renewTds();
  
  // Set listeners for table inputs
  this.tds.each(function (i, e) {
    var input = jQuery(e).find('input');
    
    input.data('original-column-name', value);
    var row_num = input.data('original-column-row');
    
    input.attr('name', row_num + '_' + value);
    input.attr('placeholder', translated);
  });
  
};

DropdownSelectable.prototype.optionClicked = function (clicked) {
  
  var new_value = clicked.data('value');
  
  // Tell other dropdowns that previous value is now free
  if (this.value && typeof (this.value) !== 'undefined') {
    this.all_options.setState(this.value, false);
  }
  
  if (new_value === 'delete') {
    this.table.deleteColumn(this.num);
    return true;
  }
  
  // Tell other dropdowns that value is used now
  this.all_options.setState(new_value, true);
  
  // Change active
  this.setValue(new_value);
  
};

DropdownSelectable.prototype.renewTds = function (e) {
  this.tds = this.table.getTdsForColumn(this.num);
};

DropdownSelectable.prototype.dropdownRenew = function (e) {
  var self = this;
  
  this.menu = this.all_options.getView(this.value, function (e) {
    var clicked = jQuery(this);
    
    // Cancel click on disabled element
    if (clicked.parent().hasClass('disabled')) return cancelEvent(e);
    
    self.optionClicked(clicked);
  });
  this.menu.data('dropdown_selectable', self);
};

function importTranslate(lang_var) {
  if (isDefined(IMPORT_LANG[lang_var])){
    return IMPORT_LANG[lang_var];
  }
  else if (isDefined(lang_var)){
    return lang_var.capitalizeFirst();
  }
  else {
    return lang_var;
  }
}

/**
 * Set table inputs update value when template values has been changed
    Exceptions are:
     1. Already have value and it was not assigned from template
     2. Has flag indicating it was changed by hands
 * @param dynamic_table
 * @param inputs
 */
function initTemplateInputsLogic(dynamic_table, inputs) {
  inputs.on('input', function () {
    var new_val = this.value;
    
    dynamic_table.getInputsForName(this.name.toLowerCase()).each(function (i, t_inp) {
      var table_input = jQuery(t_inp);
      
      if (table_input.val() && table_input.data('hand_changed')) {
        return;
      }
      
      // Edit in any case if don't have value
      if (!table_input.val() || table_input.data('auto_changed') === true) {
        t_inp.val(new_val);
        table_input.data('auto_changed', true);
        table_input.data('hand_changed', false);
      }
      
      table_input.off('input');
      table_input.on('input', function () {
        
        if (!table_input.data('hand_changed') && table_input.data('auto_changed')) {
          table_input.data('hand_changed', true);
          table_input.data('auto_changed', false);
        }
        
      });
      
    });
    
  })
}

function initFormSubmitLogic(dynamic_table, form_id){
  var form = jQuery('#' + form_id);
  
  form.on('submit', function (e) {
    cancelEvent(e);
  
    try {
      for (var i = 0; i < dynamic_table.headings.length; i++) {
        var dropdown = jQuery(dynamic_table.headings[i]).find('div.dropdown').data('dropdown_selectable');
    
        if (!dynamic_table.headings_selectable.hasColumn(dropdown.value)) {
          aTooltip.displayError('<h1>' + importTranslate('YOU HAVE UNCHOSEN COLUMNS') + '</h1>', 4000);
          location.hash = "#" + form_id;
          return;
        }
      }
  
      // Count rows
      form.find('input[name="rows"]').val(dynamic_table.rows.length);
  
      form.off('submit');
      form.submit();
    }
    catch (Error){
      alert(Error);
    }
    
  })
  
}