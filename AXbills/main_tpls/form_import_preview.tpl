<style>
  thead > tr > button.form-control {
    margin-top: 5px
  }
</style>
<form name='form_PREVIEW_IMPORT' id='form_PREVIEW_IMPORT' method='post' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='import' value='1'/>
  <input type='hidden' name='FILE_IMPORT' value='1'/>
  <input type='hidden' name='rows' value=''/>

  <div class='card card-primary card-outline box-form'>
    <div class='card-body' id='import-form-body-wrapper'>

      %FORM_GROUPS%

    </div>
  </div>

  %TABLE%

  <div class='card-footer'>
    <a href='?index=$index' class='btn btn-secondary'>_{BACK}_</a>
    <input type='submit' class='btn btn-primary' name='TABLE_IMPORT' value='_{IMPORT}_'>
  </div>
</form>

<script>
  window['IMPORT_LANG'] = {
    'REMOVE': '_{REMOVE}_',
    'CHOOSE': '_{CHOOSE}_',
    'YOU HAVE UNCHOSEN COLUMNS' : '_{ERR_CHECK_ALL_COLUMNS}_'
  };
</script>

<script src='/styles/default_adm/js/import_preview.js'></script>

<script>
  jQuery(function () {
    'use strict';

    // All existing columns
    var columns_for_import = JSON.parse('%COLUMNS%');
    var table_id           = '%TABLE_ID%';

    var dynamic_table = new DynamicTable(table_id, {
      headings: new PossibleColumns(columns_for_import)
    });

    if (!table_id || !dynamic_table) {
      alert('Import table without id or you passed me wrong id : ' + table_id);
    }

    initTemplateInputsLogic(dynamic_table, jQuery('#import-form-body-wrapper').find('input'));

    initFormSubmitLogic(dynamic_table, 'form_PREVIEW_IMPORT');

  });
</script>