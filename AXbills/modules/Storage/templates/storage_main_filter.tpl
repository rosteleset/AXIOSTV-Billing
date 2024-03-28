<script language='JavaScript'>
  function autoReload() {
    document.depot_form.type.value = 'prihod';
    document.depot_form.submit();
  }
</script>

<script src='/styles/default/js/storage.js'></script>
<form class='form form-horizontal' action='$SELF_URL?index=$index\&storage_status=1' name='depot_form' method=POST>
  <input type=hidden name=index value=$index>
  <input type=hidden name=ID value=$FORM{chg}>
  <input type=hidden name=INCOMING_ID value=%INCOMING_ID%>
  <input type=hidden name='type' value='prihod2'>
  <input type=hidden name='storage_status' value='1'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{SEARCH}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{INVOICE_NUMBER}_:</label>
        <div class='col-md-8'>
          %INVOICE_NUMBER_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{TYPE}_:</label>
        <div class='col-md-8'>
          %ARTICLE_TYPES%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{NAME}_:</label>
        <div class='col-md-8'>
          <div class="ARTICLES_S">
            %ARTICLE_ID%
          </div>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{SUPPLIERS}_:</label>
        <div class='col-md-8'>
          %SUPPLIER_ID%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>_{STORAGE}_:</label>
        <div class='col-md-8'>
          %STORAGE_STORAGES%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-form-label text-md-right col-md-4'>SN:</label>
        <div class='col-md-8'>
          <input class='form-control' type='text' name='SERIAL' value='%SERIAL%'>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type='submit' name='show' value='_{SHOW}_'>
    </div>
  </div>
</form>