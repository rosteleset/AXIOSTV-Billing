<div>
  <div class='card card-primary card-outline'>

    <div class='card-header with-border'>
      <div class='card-title section-title'>
        <span>%TITLE%</span>
        <a class='ml-2 text-muted text-small fa fa-pencil-alt cursor-pointer d-none edit-title-btn' data-id='%SECTION_ID%'></a>
      </div>
      <input type='text' class='card-title form-control d-none' value='%TITLE%'/>
      <div class='card-tools float-right'>
        %WATCHING_BUTTON%
        <button type='button' class='btn btn-tool mr-1 change-tool-btn'>_{CRM_CHANGE}_</button>
      </div>
    </div>
    <div class='card-body '>
      %LABEL%

      %CONVERT_DATA_BUTTON%
      %CONVERT_LEAD_BUTTON%
    </div>
    <div class='card-footer'>
      <button type='button' class='btn text-danger btn-tool m-1 delete-section' data-id='%SECTION_ID%'>_{CRM_DELETE_SECTION}_</button>
      <button type='button' class='btn btn-tool m-1 choose-fields' data-id='%SECTION_ID%'>_{CRM_CHOOSE_FIELDS}_</button>
    </div>
  </div>
  <div class='card card-primary card-outline d-none'>
    <div class='card-header with-border'>
      <div class='card-title section-title'>
        <span>%TITLE%</span>
        <a class='ml-2 text-muted text-small fa fa-pencil-alt cursor-pointer d-none edit-title-btn' data-id='%SECTION_ID%'></a>
      </div>
      <input type='text' class='card-title form-control d-none' value='%TITLE%'/>
      <div class='card-tools float-right'>
        %CHANGE_EXTRA_INFO%
        <button type='button' class='btn btn-tool mr-1 change-tool-btn'>_{CRM_CANCEL}_</button>
      </div>
    </div>
    <div class='card-body'>
      <form action='%SELF_URL%' method='POST' id='form-section-%SECTION_ID%'>
        <input type='hidden' name='index' value='%index%'>
        <input type='hidden' name='ID' value='%LEAD_ID%'>
        <input type='hidden' name='LEAD_ID' value='%LEAD_ID%'>
        <input type='hidden' name='DEAL_ID' value='%DEAL_ID%'>

        %INPUT%
      </form>
    </div>
    <div class='card-footer'>
      <button type='submit' class='btn btn-primary' name='change' form='form-section-%SECTION_ID%' value='1'>_{SAVE}_</button>
    </div>
  </div>
</div>