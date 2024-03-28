%SEL_TYPE%

<form action='$SELF_URL' METHOD='GET' name='form_search' id='form_search' class='pb-4 pt-4'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='search_form' value='1'>
  %HIDDEN_FIELDS%
  <fieldset>

    <button class='btn btn-primary btn-block' type='submit' name='search' value=1>
      <i class='fa fa-search'></i> _{SEARCH}_
    </button>
    <br/>
    <div class='row'>
      <div class='col-md-6'>
        <div class='card card-primary card-outline '>
          <div class='card-header with-border'>
            <h3 class='card-title'>_{USER}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-minus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>

            <div class='form-group row'>
              <label class='col-md-4 col-form-label text-md-right' for='LOGIN'>_{LOGIN}_ (*,):</label>
              <div class='col-md-6'>
                <input id='LOGIN' name='LOGIN' value='%LOGIN%' placeholder='%LOGIN%'
                  class='form-control' type='text'>
              </div>
              <div class="col-md-2">
                <input placeholder="UID" pattern="\d+\,?\*?" id="UID" name="UID" value="%UID%" type="text" class="form-control" />
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-4 col-form-label text-md-right' for='PAGE_ROWS'>_{ROWS}_:</label>
              <div class='col-md-8'>
                <input id='PAGE_ROWS' name='PAGE_ROWS' value='%PAGE_ROWS%' placeholder='$PAGE_ROWS'
                  class='form-control' type='text'>
              </div>
            </div>

            <div class='form-group row' style='%DISPLAY_GROUP%'>
              <label class='col-md-4 col-form-label text-md-right'>_{GROUP}_:</label>
              <div class='col-md-8'>
                %GROUPS_SEL%
              </div>
            </div>

            <div class='form-group row' style='%DISPLAY_TAGS%'>
              <label class='col-md-4 col-form-label text-md-right' for='TAGS'>_{TAGS}_:</label>
              <div class='col-md-8 row'>
                <div class='col-md-8'>
                  %TAGS_SEL%
                </div>
                <div class='col-md-4'>
                  %TAG_SEARCH_VAL%
                </div>
              </div>
            </div>

            <div class='form-group row' %HIDE_DATE%>
              <label class='col-md-4 col-form-label text-md-right' for='FROM_DATE'>_{PERIOD}_ _{FROM}_:</label>
              <div class='col-md-8'>
                %FROM_DATE%
              </div>
            </div>

            <div class='form-group row' %HIDE_DATE%>
              <label class='col-md-4 col-form-label text-md-right' for='TO_DATE'>_{PERIOD}_ _{TO}_:</label>
              <div class='col-md-8'>
                %TO_DATE%
              </div>
            </div>
            %ADDRESS_FORM%
          </div>
        </div>
      </div>
      %SEARCH_FORM%
    </div>
    <button class='btn btn-primary btn-block' type='submit' name='search' id='go' value=1>
      <i class='fa fa-search'></i> _{SEARCH}_
    </button>

  </fieldset>
</form>
