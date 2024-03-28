<form action='$SELF_URL' method='post' id='user_form' name='user_form' role='form'>
  <input type=hidden name=index value='$index'>
  <input type=hidden name=subf value='$FORM{subf}'>
  <input type=hidden name=OP_SID value='%OP_SID%'>
  <input type=hidden name=UID value='%UID%'>
  <input type=hidden name=step value='$FORM{step}'>
  <input type='hidden' name='LEAD_ID' value='$FORM{LEAD_ID}'>
  <input type='hidden' name='LOCATION_ID' value='$FORM{LOCATION_ID}'>
  <input type='hidden' name='DISTRICT_ID' value='$FORM{DISTRICT_ID}'>
  <input type='hidden' name='STREET_ID' value='$FORM{STREET_ID}'>
  <input type='hidden' name='ADDRESS_FLAT' value='$FORM{ADDRESS_FLAT}'>

    <div class='card card-primary card-outline container-md'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{PAYMENTS}_</h4>
        <span class='float-right'>%CARDS_BTN%<span>
      </div>

      <div class='card-body'>
        <div class='form-group row'>
          <label  class='col-md-3 col-form-label text-md-right required' for='SUM'>_{SUM}_:</label>
          <div class='col-md-9'>
            <input  id='SUM' name='SUM' value='$FORM{SUM}' required placeholder='$FORM{SUM}' class='form-control'
                  type='number' step='0.01' min='0' max='%MAX_PAYMENT%' autofocus>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-md-3 col-form-label text-md-right' for='DESCRIBE'>_{DESCRIBE}_:</label>
          <div class='col-md-9'>
            <input id='DESCRIBE' type='text' name='DESCRIBE' value='%DESCRIBE%' class='form-control' maxlength='%MAX_LENGTH_DSC%'>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-md-3 col-form-label text-md-right' for='INNER_DESCRIBE'>_{INNER}_:</label>
          <div class='col-md-9'>
            <input id='INNER_DESCRIBE' type='text' name='INNER_DESCRIBE' value='%INNER_DESCRIBE%' class='form-control' maxlength='%MAX_LENGTH_INNER_DESCRIBE%'>
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-md-3 col-form-label text-md-right'>_{PAYMENT_METHOD}_:</label>
          <div class='col-md-9'>
            %SEL_METHOD%
          </div>
        </div>

     <!--   <div class='form-group row'>
          <label class='col-md-3 col-form-label text-md-right' for='%ID%'>_{DATE}_:</label>
          <div class='col-md-9'>
            <div class='input-group'>
              %VALUE%
              <div class='input-group-append'>
                <div class='input-group-text'>
                  %ADDON%
                </div>
              </div>
            </div>
          </div>
        </div>-->

        <div class='form-group row' %CASHBOX_HIDDEN%>
          <label  class='col-md-3 col-form-label text-md-right' for='EXT_ID'>_{CASHBOX}_:</label>
          <div class='col-md-9'>
            %CASHBOX_SELECT%
          </div>
        </div>

        <div class='form-group row'>
          <label  class='col-md-3 col-form-label text-md-right' for='EXT_ID'>EXT ID:</label>
          <div class='col-md-9'>
            <input id='EXT_ID' type='text' name='EXT_ID' value='%EXT_ID%' class='form-control'
                   maxlength='%MAX_LENGTH_EXT_ID%'>
          </div>
        </div>

        %ER_FORM%
        %DATE_FORM%
        %EXT_DATA_FORM%

        %DOCS_INVOICE_RECEIPT_ELEMENT%
        </div>
      <div class='card-footer'>
        %BACK_BUTTON%
        <input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary double_click_check'>
      </div>
    </div>
</form>
