'use strict';

function ContactChooser(admin_mode, contacts_list, type_select, value_wrapper) {
  var self = this;

  this.contacts_list  = contacts_list;
  this.$type_select   = type_select;
  this.type_names     = {};
  this.$value_wrapper = value_wrapper;
  this.current_value  = null;
  this.in_edit_mode   = false;

  if (this.$type_select.length) {
    this.current_type = this.$type_select.val();
  }

  // Sort contacts by type_id
  this.updateContacts = function (contacts_list) {
    var contacts_by_type = {};
    for (var i = 0; i < contacts_list.length; i++) {
      var cont = contacts_list[i];
      if (typeof( contacts_by_type[cont.type_id]) === 'undefined' || !contacts_by_type[cont.type_id]) {
        contacts_by_type[cont.type_id] = [cont];
      }
      else {
        contacts_by_type[cont.type_id].push(cont);
      }
    }
    this.contacts_by_type = contacts_by_type;
  };

  this.findContactForTypeAndValue = function (type_id, value) {
    if (typeof(this.contacts_by_type[type_id]) === 'undefined') {
      return false
    }

    for (var i = 0; i < this.contacts_by_type[type_id].length; i++) {
      if (this.contacts_by_type[type_id][i].value === value) {
        return this.contacts_by_type[type_id][i];
      }
    }

    return false;
  };

  this.setValue = function (new_value) {
    this.current_value = new_value;

    if (this.current_type === null) return;

    this.current_type.forEach(function(type) {
      if (self.current_value[type] !== undefined && self.current_value[type] !== ' ' &&
        !self.findContactForTypeAndValue(type, self.current_value[type])) {
        var new_contact = {type_id: type, value: self.current_value[type]};

        if (typeof (self.contacts_by_type[type]) === 'undefined') {
          self.contacts_by_type[type] = [new_contact];
        }
        else {
          self.contacts_by_type[type].push(new_contact);
        }
      }
    });

    this.updateValueView(this.current_type);
  };

  this.getType = function () {
    return this.$type_select.val();
  };

  this.changeType = function (new_type) {
    this.updateValueView(new_type);
  };

  this.updateValueView = function (type_id) {
    self.is_in_edit_mode = false;
    let wrapper_content = [];

    if (type_id === null) {
      value_wrapper.html('');
      return;
    }

    type_id.forEach(function (type) {
      let contact_type = type === '14' ? 1 : type; //Viber (14) use 1 type (phone)
      self.display = new ContactValueView(self.contacts_by_type[contact_type], type);
      wrapper_content.push(self.display.getInsertView(self.type_names[type]));
    });

    value_wrapper.html('');
    wrapper_content.forEach(function(content, index) {
      if (jQuery(content).data('type') !== 'select') {
        value_wrapper.append(jQuery(content));
        return;
      }

      value_wrapper.append(rowContent(self.type_names[type_id[index]], content, type_id[index]));
      content.select2(typeof CHOSEN_PARAMS !== 'undefined' ? CHOSEN_PARAMS : '');

      if (self.current_value && self.current_value[type_id[index]]) content.val(self.current_value[type_id[index]]).trigger('change');
    });
  };

  this.updateValueInput = function (type_id, value) {
    self.is_in_edit_mode = true;

    value_wrapper.html('');

    if (type_id === null) {
      return;
    }

    type_id.forEach(function (type, index) {
      value_wrapper.append(rowContent(self.type_names[type], jQuery('<input />', {
        name   : "DESTINATION_" + type,
        'class': 'form-control',
        value  : self.contacts_by_type[type] ? self.contacts_by_type[type][0].value : ''
      }), type));
    });
  };

  this.feelTypeNames = function () {
    let self = this;
    jQuery('option', this.$type_select).each(function(index, option) {
      self.type_names[jQuery(option).val()] = jQuery(option).text();
    });
  };

  // Sort contacts by type_id
  this.updateContacts(this.contacts_list);
  this.feelTypeNames();

  this.$type_select.on('change', function () {
    self.current_type = self.$type_select.val();
    self.changeType(self.$type_select.val());
  });

  // Allow admin to change destination manually
  if (admin_mode) {
    $('button#MANUAL_EDIT_CONTACT_BTN').on('click', function (e) {
      cancelEvent(e);

      if (!self.is_in_edit_mode) {

        self.updateValueInput(self.$type_select.val());
        self.is_in_edit_mode = true;
      }
      else {
        self.updateValueView(self.getType());
        self.is_in_edit_mode = false;
      }

    });

  }

}

function ContactValueView(contacts_for_type, selected_type, value) {

  // Save args
  this.contacts_for_type = contacts_for_type;
  this.type              = selected_type;
  this.value             = value;

  this.getHumanizedContactValue = function (type_id, value) {
    switch (type_id) {
      case '6': // Telegram
      case '10': // Push
        return "OK";

      default:
        return value;
    }
  };

  this.getValue = function () {
    return this.value || null;
  };

  this.makeSelect = function (contacts_for_type_id, type_id) {
    var destination_select = jQuery('<select></select>', {
      'name' : 'DESTINATION_' + type_id,
      'class': 'form-control',
      'data-type': 'select'
    });

    for (var i = 0; i < contacts_for_type_id.length; i++) {
      var cont = contacts_for_type_id[i];
      if (cont.value === "") {
        continue;
      }
      destination_select.append('<option value="' + cont.value + '" selected>' + cont.value + '</option>');
    }

    return destination_select;
  };

  this.selectValue = function (select, value) {
    renewChosenValue(select, value);
  };

  this.makeAbsentContactText = function (type_id, label = '') {
    return rowContent(label, LANG["NO_CONTACTS_FOR_TYPE"], type_id);
    // TODO: registration link
  };

  this.makeText = function (type_id, value, label) {
    if (!type_id) return '';

    let result = jQuery('<input type="hidden" name="DESTINATION_' + type_id + '" value="' + value + '"/><p>' + value + '</p>');

    return rowContent(label, result, type_id);
  };

  this.getInsertView = function (type_label) {
    if (typeof(this.contacts_for_type) === 'undefined' || !this.contacts_for_type.length) {
      return this.makeAbsentContactText(this.type, type_label);
    }

    if (this.contacts_for_type.length === 1) {
      /// Value can be absent in contacts
      if (!this.value) this.value = this.contacts_for_type[0].value;
      return this.makeText(this.type, this.value, type_label);
    }

    return this.makeSelect(this.contacts_for_type, this.type);
  }
}

function rowContent(label, value, type_id) {
  let type_container = jQuery('<div class="form-group row">\n' +
    '        <label class="control-label col-md-2 col-sm-3">' + label + ':</label>\n' +
    '        <div class="col-md-9 col-sm-8" id="type_content_' + type_id + '">\n' +
    '        </div>\n' +
    '      </div>');
  jQuery(type_container).find('#type_content_' + type_id).append(typeof value === 'object' ? jQuery(value) : value)
  return jQuery(type_container);
}
