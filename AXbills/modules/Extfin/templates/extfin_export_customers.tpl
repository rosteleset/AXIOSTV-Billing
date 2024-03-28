<FORM action='$SELF_URL' METHOD='POST' name='extfin'>
  <input type='hidden' name='index' value='$index'>
<div class='card card-primary card-outline card-form'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{EXPORT}_ : _{USERS}_</h4>
  </div>
  <div class='card-body'>
    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{DATE}_ _{FROM}_</label>
      <div class='col-md-9'>
        %FROM_DATE%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{DATE}_ _{TO}_</label>
      <div class='col-md-9'>
        %TO_DATE%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{GROUP}_</label>
      <div class='col-md-9'>
        %GROUP_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{REPORT}_ _{TYPE}_</label>
      <div class='col-md-9'>
        %TYPE_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{USER}_ _{TYPE}_</label>
      <div class='col-md-9'>
        %USER_TYPE_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{ROWS}_</label>
      <div class='col-md-9 input-group'>
        <input type=text class='form-control' name=PAGE_ROWS value='$PAGE_ROWS'>
      </div>
    </div>

    <div class='form-group row'>
      <div class='col-sm-12 col-md-6'>
        <label class='col-md-10 control-label'>_{INFO_FIELDS}_ (_{COMPANIES}_)</label>
        <div class='input-group'>
          %INFO_FIELDS_COMPANIES%
        </div>
      </div>
    </div>

    <div class='form-group row'>
      <div class='col-sm-12 col-md-6'>
        <label class='col-md-10 control-label'>_{INFO_FIELDS}_ (_{USERS}_)</label>
        <div class='input-group'>
          %INFO_FIELDS%
        </div>
      </div>
    </div>

    <!-- <div class='checkbox'>
      <label>
        <input type='checkbox' name=TOTAL_ONLY value=1><strong>_{TOTAL}_</strong>
      </label>
    </div> -->

  </div>

  <div class='card-footer'>
    <input class='btn btn-primary' type=submit name=%ACTION% value=%ACTION_LNG%>
  </div>
</div>
</FORM>
