<form action='$SELF_URL' METHOD='POST' id='admin_form_paranoid' name=admin_form_paranoid>
  <input type=hidden name='index' value='%INDEX%'>
  <input type=hidden name='AID' value='%AID%'>
  <input type=hidden name='subf' value='%subf%'>
  <input type=hidden name='search_form' value='1'>
  <div class='row'>
    <button class='btn btn-primary btn-block m-2 mb-4' type='submit' name='search' id='submitbutton' value=1>
      <i class='fa fa-search'></i> _{SEARCH}_
    </button>
    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'><h4 class='card-title'>_{SEARCH}_ Paranoid log</h4></div>
        <div class='card-body'>
          <div>
            <div class='form-group row'>
              <label class='control-label col-md-3' for='FUNCTION_NAME'>Function name:</label>
              <div class='col-md-9'>
                <input id='FUNCTION_NAME' name='FUNCTION_NAME' value='%FUNCTION_NAME%'
                       class='form-control' type='text'>
              </div>
            </div>

            <div class='form-group row'>
              <label for='FROM_DATE' class='control-label col-sm-3'>_{PERIOD}_ _{FROM}_:</label>
              <div class='col-md-9'>
                %FROM_DATE%
              </div>
            </div>


            <div class='form-group row'>
              <label for='FROM_DATE' class='control-label col-sm-3'>_{PERIOD}_ _{TO}_:</label>
              <div class='col-md-9'>
                %TO_DATE%
              </div>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3' for='PARAMS'>Params:</label>
              <div class='col-md-9'>
                <input id='PARAMS' name='PARAMS' value='%PARAMS%' class='form-control' type='text'>
              </div>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3' for='IP'>IP:</label>
              <div class='col-md-9'>
                <input id='IP' name='IP' value='%IP%' class='form-control' type='text'>
              </div>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3' for='SID'>SID:</label>
              <div class='col-md-9'>
                <input id='SID' name='SID' value='%SID%' class='form-control' type='text'>
              </div>
            </div>

            <div class='form-group row'>
              <label class='control-label col-md-3' for='PARAMS'>Function index:</label>
              <div class='col-md-9'>
                <input id='FUNCTION_INDEX' name='FUNCTION_INDEX' value='%FUNCTION_INDEX%' class='form-control' type='text'>
              </div>
            </div>

          </div>
        </div>
      </div>
    </div>

    <button class='btn btn-primary btn-block m-2' type='submit' name='search' id='submitbutton' value=1>
      <i class='fa fa-search'></i> _{SEARCH}_
    </button>
  </div>
</form>
