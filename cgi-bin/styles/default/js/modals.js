'use strict';

var MainModal;
var modalContent;
$.fn.modal.Constructor.prototype.enforceFocus = function() {};
var spinner = '<div class="text-center"><i class="fa fa-spinner fa-pulse fa-2x"></i></div>';
var aModal  = new AModal();

$(document).ready(function () {
  MainModal    = $('#PopupModal');
  modalContent = MainModal.find('#modalContent');
});

/*  Modal window open  */
if (modalsArray === undefined) {
  var modalsArray = [];
}

if (modalsSearchArray === undefined) {
  var modalsSearchArray = [];
}

/** Old-fashioned way to load modal windows
 *
 */
function openModal(buttonNumber, type_, size) {
  if (type_ === 'TemplateBased') {
    fillTemplateBasedSearchForm(modalsArray[buttonNumber], size);
  }
  if (type_ === 'ArrayBased') {
    fillOneRowArrayBasedSearchForm(modalsSearchArray[buttonNumber], size);
  }
}

/*  loads content of url in modal and shows it*/
function loadToModal(url, callback, size) {
  url += "&IN_MODAL=1";

  let modal = aModal.clear()
    .setSize(size)
    .setId('CurrentOpenedModal')
    .setBody(spinner);

  // if (typeof size !== 'undefined') {
  //   if (size === 'lg') modal.setLarge(true);
  //   if (size === 'sm') modal.setSmall(true);
  // }

  modal.show(function () {

    $.get(url,
      function (data) {
        var modalBody = $('#CurrentOpenedModal').find('.modal-body');
        modalBody.html(data);

        if (modalBody.find('.card-header').length === 1 && !modalBody.find('.card-header').find('.card-tools').length) {
          var header_inside = modalBody.find('.card-header').first();
          var header_outside = $('#CurrentOpenedModal_header');

          header_inside.remove();

          let header_title = header_inside.children().first();
          header_title.removeClass('card-title').addClass('modal-title');

          if (header_outside) {
            header_outside.prepend(header_title);
          }
        }

        pageInit(modalBody);
        Events.emit('modal_loaded', modalBody);
        if (callback) callback();

      }, 'html')
      .fail(function (error) {
        alert('Fail' + JSON.stringify(error));

        Events.emit('modal_loaded', false);
      });
  });
}

/*  loads content of url in modal and shows it*/
function postAndLoadToModal(url, params, callback, close_callback) {
  params['IN_MODAL'] = 1;

  aModal.clear()
      .setSize()
      .setId('CurrentOpenedModal')
      .setBody(spinner);

      if (close_callback)
        aModal.onClose(close_callback);

      aModal.show(function () {
        $.post(url, $.param(params), function(data){
          var modalBody = $('#CurrentOpenedModal').find('.modal-body');
          modalBody.html(data);
          pageInit(modalBody)
        } , 'html')
            .fail(function (error) {
              alert('Fail' + JSON.stringify(error));
            })
            .done(callback);
      })


}

function loadToModalSmall(url, callback) {
  url += "&IN_MODAL=1";
  $.get(url, function (data) {

    aModal.clear()
        .setSize('sm')
        .setBody(data)
        .show(function(){
          pageInit(data);
        });

    if (callback) callback();

  }, 'html');
}

/*  loads content of url in modal and shows it*/
function loadRawToModal(url, callback, size) {
  url += "&IN_MODAL=1";
  var modal = aModal.clear()
      .setRawMode(true)
      .setBody(spinner)
      .setId('CurrentOpenedModal');

  if (typeof size !== 'undefined') {
    modal.setSize(size);
  }

  modal.show(function () {

    $.get(url, function (data) {
      var modalBody = $('#CurrentOpenedModal').find('.modal-content');
      modalBody.html(data);
      pageInit(modalBody);
      if (callback) callback();
    }, 'html')

        .fail(function (error) {
          alert('Fail' + JSON.stringify(error));
        });

  });
}

function showImgInModal(url, title) {
  let processed_url = url.replace("\n", '');

  loadDataToModal(
  '<img src="' + processed_url + '" class="center-block" alt="Seems like image...">',
  true,
  true,
  title
  );
}

/**
 * get modal body and load it to modal
 * @param data DOM elements to show in modal
 * @param decorated
 * @param withoutButton
 */
function loadDataToModal(data, decorated, withoutButton, title) {
  if (decorated) {
    getModalDecorated(data, null, withoutButton, title);
  } else {
    modalContent.empty().append(data);
  }
  MainModal.modal('show');
}

function getModalDecorated(data, onclick, withoutButton, title) {

  var formAction = 'getData()';
  if (onclick) formAction = onclick;

  var str_func_close = '$("#PopupModal").modal("hide");';
  if (title === undefined) {
    title = ''
  }
  var s = '';
  s += '<div class="modal-content">';
  s += '<div class="modal-header">';
  s += '<h4 class="modal-title">' + title + '</h4>'
  s += '<button type="button" class="close" onclick=' + str_func_close + '><span aria-hidden="true">&times;</span></button>';
  s += '</div>';
  s += '<div class="modal-body form-horizontal">';
  s += data;
  s += '</div>';
  s += '<div class="modal-footer">';
  if (!withoutButton)
    s += '<button class="btn btn-primary" onclick="' + formAction + '"  href="">Go</button>';
  s += '</div>';
  s += '</div>';

  modalContent.empty().append(s);
}

function AModal() {
  var counter = 0;

  var self = this;

  this.id = 'PopupModal';

  this.mainModal = null;
  this.$modal    = null;

  this.header  = '';
  this.footer  = '';
  this.body    = spinner;
  this.rawMode = false;
  this.is_form = false;
  this.form_url = '';

  this.size = false;

  this.callback = null;

  this.setId = function (id) {
    this.id = id;
    return this;
  };

  this.isForm = function (boolean) {
    this.is_form = boolean;
    return this;
  };

  this.setFormUrl = function (url) {
    this.form_url = encodeURI(url);
    return this;
  };

  this.setRawMode = function (boolean) {
    this.rawMode = boolean;
    return this;
  };

  this.setHeader = function (data) {
    this.header = data;
    return this;
  };

  this.setBody = function (data) {
    this.body = data;
    return this;
  };

  this.setSize = function (size) {
    this.size = size;
    return this;
  };

  this.setFooter = function (data) {
    this.footer = data;
    return this;
  };

  this.updateBody = function (content) {
    if (this.$modal){
      this.$modal.find('.modal-body').html(content);
      this.$modal.modal('handleUpdate')
    }
  };
  this.loadUrl = function (url, callback) {
    this.onShow = function () {
      $.get(url, function (data) {
        var modalBody = $('#' + self.id).find('.modal-content');
        modalBody.html(data);
        pageInit(modalBody);
        if (callback) callback();
      }, 'html')
          .fail(function (error) {
            alert('Fail' + JSON.stringify(error));
          });
    };
    return this;
  };
  this.onClose = function(callback){
    if (callback) this.onClose = callback;
    return this;
  };

  this.addButton = function (text, btnId, class_, type) {
    this.footer += '<button id="' + btnId + '" class="btn btn-' + class_ + ' type="' + type + '">' + text + '</button>';
    return this;
  };

  this.show = function (callback) {
    if (this.mainModal === null) this.mainModal = this.build();

    // Creating jQuery object from HTML
    var $modal = $(this.mainModal);

    var show_callback = this.onShow || callback;
    if (show_callback)
      $modal.on('show.bs.modal', function () {
        show_callback(self);
      });

    // Adding HTML to page
    $('body').prepend($modal);

    // Open modal
    $modal.modal('show');

    $modal.on('hidden.bs.modal', function(){
      if (self.onClose) self.onClose();
      $(this).remove();
    });

    this.$modal = $modal;
  };

  this.hide = function () {
    // If modal is still presnt in body
    if (self.$modal) {
      self.$modal.modal('hide');
      $('#' + this.id).remove();
    }
    // Remove body
    else {
      $('#' + this.id).remove();
    }

    // Remove fade if any
    $('.modal-backdrop').remove();
    $('body')
      .removeClass('modal-open')
      .css('padding-right','0px');

    return this;
  };

  this.build = function () {
    var modalClass = (this.size) ? 'modal-' + this.size : '';

    var str_func_close = '$("#' + this.id + '").modal("hide");';
    if (!this.rawMode) {
      var form = (this.is_form) ? ("<form class='form form-horizontal' " + ((this.form_url) ? ("action='" + this.form_url + "'") : "") + ">") : "";
      var result = "<div class='modal fade' id='" + this.id + "' role='dialog' aria-hidden='true'>" +
          '<div class="modal-dialog ' + modalClass + '" style="z-index : 10000">' +
          '<div class="modal-content">' +
          form +
          '<div class="modal-header" id="'+ this.id +'_header">' +
          '<h4 class="modal-title">' + this.header + '</h4>' +
          '<button type="button" class="close" onclick=' + str_func_close + '>' +
          '<span aria-hidden="true">&times;</span>' +
          '</button>' +
          '</div>' +  //modal-header
          '<div class="modal-body form-horizontal">';

      result += this.body;

      result += '</div>';//modal-body
      if (this.footer) {
        result += '<div class="modal-footer">' +
            this.footer +
            '</div>';//footer
      }

      if (this.is_form) {
        result += "</form>"
      }

      result += '</div>' +//modal-content
          '</div>' + //modal-dialog
          '</div>'; //modal
      return result;
    }
    else {
      return "<div class='modal' id='" + this.id + "' role='dialog' aria-hidden='true'>" +
          '<div class="modal-dialog ' + modalClass + '" style="z-index : 10000">' +
          '<div class="modal-content">' +
          this.body +
          '</div>' +//modal-content
          '</div>' + //modal-dialog
          '</div>'; //modal
    }
  };

  this.clear = function () {
    this.id = 'PopupModal' + ++counter;

    if (this.mainModal !== null){
      this.hide();
    }

    this.header  = '';
    this.footer  = '';
    this.body    = '<h1>Empty</h1>';
    this.rawMode = false;

    this.mainModal = null;

    return this;
  };

  /**
   * @deprecated because of undesired effects
   */
  this.destroy = function () {
    // If modal is still presnt in body
    if (self.$modal) {
      self.$modal.modal('hide');
      $('#' + this.id).remove();
    }
    // Remove body
    else {
      $('#' + this.id).remove();
    }

    // Remove fade if any
    $('.modal-backdrop').remove();

    return this;
  }

}

var aTooltip = new ATooltip();

ATooltip.counter = 0;

function ATooltip(text) {
  var self = this;

  this._id      = 0;
  this._text    = text || '';
  this._class   = 'success';
  this._timeout = 2000;

  this.ready = false;

  this.body = '';

  this.setTimeout = function (milliseconds) {
    this._timeout = milliseconds;
    return this;
  };

  this.setText = function (html) {
    this._text = html;
    return this;
  };

  this.setClass = function (alertClass) {
    this._class = alertClass;
    return this;
  };

  this.build = function () {
    this._id   = ATooltip.counter++;
    this.body = '<div id="modalTooltip_' + this._id + '" class="alert alert-' + this._class +
        '" style="display : none; position: fixed; z-index: 9999; top: 10vh; left: 35vw">' +
        this._text + '</div>';
  };

  this.show = function () {
    this.hide();

    if (!this.ready) {
      this.build();
    }

    $('body').prepend(this.body);
    $('#modalTooltip_' + this._id).fadeIn(500);

    clearTimeout(this._timer_id);
    if (this._timeout > 0)
      this._timer_id = setTimeout(function () {
        self.hide();
      }, this._timeout)

  };

  this.display = function (text, duration) {
    this.setText(text);
    this.setTimeout(duration || 2000);
    this.show();
  };

  this.displayError = function (Error, duration) {
    this.setText('<h3>' + Error + '</h3>');
    this.setTimeout(duration || 5000);
    this.setClass('danger');
    this.show();
  };
  this.displayMessage = function (message, duration) {
    this.setText('<h3>'
        + (message.caption || '')
        + (message.messaga ? ' : ' + message.messaga : '')
        + '</h3>');
    this.setTimeout(duration || 3000);
    this.setClass(
        message.message_type
          ? (message.message_type === 'info')
            ? 'info'
            : (message.message_type === 'warn')
              ? 'warning'
              : (message.message_type === 'err')
                ? 'danger'
                : 'info'
          : 'success'
    );
    this.show();
  };

  this.hide = function () {
    var tooltip = $('body').find('div#modalTooltip_' + this._id);
    tooltip.fadeOut(500, function () {
      tooltip.remove();
    });
  };
}

/** TEST **/
//$(function () {
//    aModal = new AModal();
//
//    aModal
//        .setId('modalTest')
//        .setHeader('Hello')
//        .setBody('<h2>Here I am</h2>')
//        .setFooter('Nothing special here')
//        .show();
//
//});

