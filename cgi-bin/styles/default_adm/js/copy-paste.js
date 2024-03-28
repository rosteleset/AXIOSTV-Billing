$('<div class="modal fade" id="paste_modal" role="dialog">').appendTo('#main-content');
$('<div class="modal-dialog">').appendTo('#paste_modal');
$('<div class="modal-content">').appendTo('#paste_modal .modal-dialog');
// $('<div class="modal-header">').appendTo('#paste_modal .modal-content');
// $('<button type="button" class="close" data-dismiss="modal">&times;</button>').appendTo('#paste_modal .modal-header');
$('<div class="modal-body">').appendTo('#paste_modal .modal-content');
$('<textarea id="paste_form" name="paste_form" class="form-control" rows="6">').appendTo('#paste_modal .modal-body');
$('<div class="modal-footer">').appendTo('#paste_modal .modal-content');
$('<button id="paste_ok" type="button" class="btn btn-secondary" data-dismiss="modal">OK</button>').appendTo('#paste_modal .modal-footer');

$(function() {
  $('#paste_btn').click(function() {
    $('#paste_modal').modal('show');
  });

  $('#paste_modal').on('shown.bs.modal', function() {
    $('#paste_form').focus();
  })

  $('#copy_btn').click(function() {
    // var inputList = $(this).closest('form').find(':input');
    var jsonObj = {};
    $(this).closest('form').find(':input').each(function() {
      if (this.id) {
        if (this.type == 'checkbox') {
          jsonObj [this.id] = this.checked;
        }
        else {
          jsonObj [this.id] = this.value;
        }
      }
    });
    // var jsonString = JSON.stringify(jsonObj, null, " ");
    var jsonString = JSON.stringify(jsonObj);
    copyToBuffer(jsonString);
  });

  $('#paste_ok').click(function() {
    try {
      var theJson = jQuery.parseJSON($('#paste_form').val());
      if (typeof theJson == 'object') {
        paste_json(theJson);
      }
      else {
        alert("Invalid JSON");
      }
    }
    catch (e) {
      alert("Invalid JSON");
    }
  });

  function paste_json(theJson) {
    for(var k in theJson) {
      if ($('#' + k).prop('type') == 'checkbox') {
        $('#' + k).prop("checked", theJson[k]);
      }
      else if ($('#' + k).prop('nodeName') == 'SELECT') {
        $('#' + k).val(theJson[k]);
        $('#' + k).trigger('change');
      }
      else if ($('#' + k).prop('nodeName') == 'INPUT') {
        $('#' + k).val(theJson[k]);
      }
    }
  }
});