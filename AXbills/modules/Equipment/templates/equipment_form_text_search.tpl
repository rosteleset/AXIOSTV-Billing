<form action='$SELF_URL' METHOD='GET' name='form_search' class='form form-horizontal'>
  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='visual' value='%VISUAL%'>
  <input type='hidden' name='NAS_ID' value='%NAS_ID%'>

  <div class='card card-primary card-outline'>
    <div class='card-header with-border' style="border-bottom: none; ">
      <div class='row'>
        <div class='col-md-3'>
          <button class='btn btn-primary btn-block' type='submit'>
            <i class='fa fa-search'></i>
            _{SEARCH}_
          </button>
        </div>
        <div class='col-md-9'>
          <div class="input-group">
            <input  name='grep' class='form-control' type='text' value='%grep%'>
            <div class='input-group-append'>
              <div class="input-group-text">
                <input type='checkbox' name='all_logs' value='checked' %all_logs% data-tooltip="_{ALL}_ _{NASS}_">
              </div>
            </div>
          </div>
      </div>
    </div>
    <div class="card-body">
      %LOG_FILE%
    </div>
  </div>
</form>



