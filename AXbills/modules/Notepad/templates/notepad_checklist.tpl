<!-- Mustache.min.js template -->
<script id='note_single_template' type='x-tmpl-mustache'>
<div class='row note' data-id='{{ id }}' data-note-id='{{ note_id }}'>
  <div class='col-xs-1'>
    <input type='checkbox' {{#state}}checked='checked'{{/state}} value='1'>
</div>
  <div class='col-xs-9'>
	  <input type='text' class='form-control' {{#state}}disabled='disabled'{{/state}} value='{{ name }}'  />
  </div>
  <div class='col-xs-2'>
	  <button class='btn btn-danger btn-xs note-del'>
      <span class='fa fa-times'></span>
    </button>
  </div>
</div>

</script>
<script src='/styles/default/js/modules/notepad/checklist.js'></script>
<style>
  #note_submit {
    margin-left: 25px;
  }

  .draggable-handler {
    cursor: move;
  }

  .note {
    padding: 6px 12px;
  }

  .note input[type=checkbox] {
    margin-top: 10px;
  }

  .note button.btn-xs {
    margin-top: 5px;
  }

  #checklist {
    margin-left: 15px;
    margin-right: 15px;
  }

  #checklist .notes-wrapper {
    min-height: 2em;
  }

</style>

<div id='checklist'>
  <div class='row notes-wrapper'></div>
  <div class='row notes-controls'>
    <div class='col-xs-8'>
      <span class='text-success note-response'></span>
    </div>
    <div class='col-xs-4 text-right'>
      <div class='btn-group'>
        <button role='button' class='btn btn-xs btn-success note-add'>
          <span class='text-lowercase'>_{ADD}_ _{ITEM}_</span>
        </button>
      </div>
    </div>
  </div>

</div>


<script>
  var NOTE_LANG = {
    'CANCEL': '_{CANCEL}_',
    'ADD'   : '_{ADD}_',
    'REMOVE': '_{REMOVE}_'
  };

  jQuery(function () {
    var ITEMS = JSON.parse('%JSON%');

    var note_template = jQuery('#note_single_template').html();
    Mustache.parse(note_template);

    var checklist = new Checklist(jQuery('#checklist'), ITEMS, {
      item_template: note_template,
      note_id      : '%NOTE_ID%'
    });

  });

</script>


