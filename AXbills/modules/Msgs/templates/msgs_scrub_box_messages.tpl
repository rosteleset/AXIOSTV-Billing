<div class='form-group message' id='msgs_card_%ID%' user_id='%UID%' draggable='true' ondragstart='return dragStart(event)'>
  <div class='card card-outline %STATUS_COLOR%' id='MSGS_%ID%'>
    <div class='card-header'>
      <h4 class='card-title'>
        <a href='$SELF_URL%USER_CARD%'>%USER%</a>
      </h4>
    </div>
    <div class='card-body pb-2'>
      <a href='$SELF_URL%MSGS_OPEN%'>%SUBJECT%</a>
      <span class='mt-1 d-block text-muted'>_{ADDED}_: %DATE%</span>
    </div>
    <div class='card-footer'>
      %ADMIN%
    </div>
  </div>
</div>
