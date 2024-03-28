<form id='msgs_tags' method='POST' action='$SELF_URL'>
  <input type='hidden' name='index' value='%INDEX%'/>
  <input type='hidden' name='chg' value='%MSGS_ID%'/>
  <input type='hidden' name='UID' value='%UID%'/>

  <div class='card-header' style='display: none'>
    <h5 class='card-title'>_{SET_TAGS}_</h5>
  </div>

  <div class='col d-flex justify-content-end'>
    <button type='button' id='accordion_open_all' class='btn btn-default btn-xs' >_{OPEN_ALL}_</button>
  </div>

  <div class='pt-1'>
    <ul class='list-unstyled' id='accordion'>
     %LIST%
    </ul>
  </div>
  %SUMBIT_BTN%
</form>


<style type='text/css'>
  #accordion .card {
    border-top: none;
    margin-bottom: 0;
  }
</style>

<script type='text/javascript'>
  jQuery('#accordion_open_all').on('click', function () {
    jQuery('#accordion .collapse').collapse('toggle');
  });
</script>