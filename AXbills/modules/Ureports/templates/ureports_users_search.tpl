<form action='$SELF_URL' method='POST' class='form-horizontal' id='UREPORTS_SEARCH'>
  <input type='hidden' name='index' value='%INDEX%'>
  <input type='hidden' name='search_form' value='1'>

  <div class='card card-primary card-outline container-md col-md-6'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{SEARCH}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-rightcol-md-10 col-sm-12 control-label' for='DESTINATION'>_{DESTINATION}_:</label>
        <div class='col-md-8'>
          <input type='text' name='DESTINATION_ID' ID='DESTINATION' value='%DESTINATION%' class='form-control'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{STATUS}_:</label>
        <div class='col-md-8'>
          %STATUS_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' FOR='TP_ID'>_{TARIF_PLAN}_ (ID):</label>
        <div class='col-md-8'>
          <input type='text' name='TP_ID' ID='TP_ID' value='%TP_ID%' class='form-control'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{GROUP}_:</label>
        <div class='col-md-8'>
          %GROUP_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='LAST_MESSAGE'>_{LAST_MESSAGE}_ (*):</label>
        <div class='col-md-8'>
          <textarea type='text' name='LAST_MESSAGE' ID='LAST_MESSAGE' class='form-control'>%LAST_MESSAGE%</textarea>
        </div>
      </div>
    </div>
    <button name='search' class='btn btn-primary' type='submit' value='_{SEARCH}_'>
      _{SEARCH}_
    </button>
  </div>
</form>