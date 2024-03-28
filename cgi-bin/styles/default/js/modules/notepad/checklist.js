'use strict';
function Checklist(wrapper, items, options) {
  var self = this;
  
  this.items   = [];
  this.options = options;
  
  if (typeof wrapper === 'string') {
    this.$wrapper = $('#' + wrapper)
  }
  else {
    this.$wrapper = wrapper;
  }
  
  if (!this.$wrapper.length) {
    throw new Error('Wrapper not found');
  }
  
  this.$notes_wrapper    = this.$wrapper.find('div.notes-wrapper');
  this.$controls_wrapper = this.$wrapper.find('div.notes-controls');
  this.$add_btn          = this.$controls_wrapper.find('button.note-add');
  this.$message          = this.$controls_wrapper.find('span.note-response');
  
  this.$add_btn.on('click', function (e) {
    cancelEvent(e);
    self.addNewItem();
  });
  
  this.item_template = options.item_template;
  
  if (items) {
    for (var i = 0; i < items.length; i++) {
      this.addItem(
          new ChecklistItem(items[i].name, items[i].state,
              {
                template: this.item_template,
                id      : items[i].id,
                note_id : options.note_id
              }
          )
      )
    }
  }
  
}

Checklist.prototype = {
  addItem   : function (item) {
    this.items.push(item);
    this.$notes_wrapper.append(item.render());
    item.activate();
  },
  addNewItem: function () {
    var new_item = new ChecklistItem('', 0, {
      template: this.item_template,
      note_id : this.options.note_id
    });
    this.addItem(new_item);
  }
};

function ChecklistItem(name, state, options) {
  this.name    = name;
  this.state   = state === '1';
  this.id      = options.id || '';
  this.note_id = options.note_id || '';
  
  this.template  = options.template;
  this.$rendered = null;
}

ChecklistItem.prototype = {
  render  : function () {
    if (!this.$rendered) {
      this.$rendered = $(Mustache.render(this.template, this));
      this.$chb      = this.$rendered.find('input[type="checkbox"]');
      this.$text     = this.$rendered.find('input[type="text"]');
      this.$del_btn  = this.$rendered.find('button.note-del');
    }
    return this.$rendered;
  },
  change  : function (newOptions) {
    this.name  = (typeof newOptions.name !== 'undefined' ) ? newOptions.name : this.name;
    this.state = (typeof newOptions.state !== 'undefined' ) ? newOptions.state : this.state;
    
    this.$text.val(this.name);
    this.$text.prop('disabled', this.state);
    this.$chb.prop('checked', this.state);
    
    this.save();
  },
  save    : function () {
    var self = this;
    $.post('?', {
      get_index   : 'notepad_checklist',
      header      : 2,
      json        : 1,
      AJAX        : 1,
      MESSAGE_ONLY: 1,
      
      change : 1,
      ID     : this.id,
      NOTE_ID: this.note_id,
      STATE  : this.state ? '1' : '0',
      NAME   : this.name
    }, function (data) {
      if (data && data.MESSAGE && data.MESSAGE.INSERT_ID) {
        self.id = data.MESSAGE.INSERT_ID;
      }
    });
  },
  remove  : function () {
    var self = this;
    self.$rendered.hide();
    
    if (this.id) {
      $.post('?', {
        get_index   : 'notepad_checklist',
        header      : 2,
        json        : 1,
        AJAX        : 1,
        MESSAGE_ONLY: 1,
        NOTE_ID     : self.note_id || 'CHANGE THIS LOGIC',
        del : this.id
      });
    }
  },
  activate: function () {
    var self = this;
    
    self.$chb.on('change', function () {
      self.change({
        state: self.$chb.prop('checked')
      })
    });
    
    self.$text.on('focusout', function () {
      self.change({
        name: self.$text.val()
      });
    });
    
    self.$del_btn.on('click', function (e) {
      cancelEvent(e);
      self.$text.prop('disabled', true);
      self.$chb.prop('disabled', true);
      self.remove();
    });
  }
};