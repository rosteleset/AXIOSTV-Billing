<div class='card card-primary card-outline card-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{LOG}_</h4></div>
  <div class='card-body'>

    <div class='form-group row'>
      <label class='col-form-label text-md-right col-md-4'>_{INVOICE_NUMBER}_:</label>
      <div class='col-md-8'>
        %INVOICE_SELECT%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right'>_{TYPE}_:</label>
      <div class='col-md-8'>
        %ARTICLE_TYPES_SELECT%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right'>_{NAME}_:</label>
      <div class='col-md-8'>
        <div class='ARTICLES_S'>
          %ARTICLE_ID_SELECT%
        </div>
      </div>
    </div>

    <div class='form-group row'>
      <label for='IP' class='control-label col-md-4'>IP:</label>
      <div class='col-md-8'>
        <input class='form-control' id='IP' placeholder='%IP%' name='IP' value='%IP%'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='ADMIN' class='control-label col-md-4'>_{ADMIN}_:</label>
      <div class='col-md-8'>
        %ADMIN_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label for='FROM_DATE/TO_DATE' class='control-label col-md-4'>_{PERIOD}_:</label>
      <div class='col-md-8'>
        %PERIOD%
      </div>
    </div>

    <div class='form-group row'>
      <label for='ACTION' class='control-label col-md-4'>_{ACTION}_:</label>
      <div class='col-md-8'>
        %ACTION_SEL%
      </div>
    </div>

    <div class='form-group  row'>
      <label class='col-md-4 col-form-label text-md-right' for='COUNT'>_{COUNT}_:</label>
      <div class='col-md-8 '>
        <input type='text' name='COUNT' class='form-control' id='COUNT' value='%COUNT%'>
      </div>
    </div>

    <div class='form-group  row'>
      <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
      <div class='col-md-8 '>
        <input type='text' name='COMMENTS' class='form-control' id='COMMENTS' value='%COMMENTS%'>
      </div>
    </div>

    <div class='form-group row'>
      <label for='STORAGE_ID' class='control-label col-md-4'>_{STORAGE}_:</label>
      <div class='col-md-8'>
        %STORAGE_SEL%
      </div>
    </div>

  </div>
</div>

<script src='/styles/default/js/storage.js'></script>
