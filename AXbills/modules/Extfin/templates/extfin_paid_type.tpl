<div class='d-print-none'>
<form action='$SELF_URL' id='paid_type' METHOD='POST'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>

<div class='card card-primary card-outline card-form'>
  <div class='card-header'>
    <div class='card-title'>_{TARIF_PLAN}_</div>
  </div>

  <div class='card-body'>

    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{NAME}_:</label>
      <div class='col-md-9'>
        <input class='form-control' type=text name=NAME value='%NAME%'>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{SUM}_</label>
      <div class='col-md-9'>
        <input class='form-control' type='number' step='0.01' name='SUM' value='%SUM%'>
      </div>
    </div>


    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{PERIOD}_</label>
      <input type='checkbox' name='PERIODIC' value='1' %PERIODIC%>
    </div>

    <div class='form-group row'>
      <label class='col-md-3 control-label'>_{MONTH_ALIGNMENT}_</label>
      <input type='checkbox' name='MONTH_ALIGNMENT' value='1' %MONTH_ALIGNMENT%>
    </div>

  </div>

  <div class='card-footer'>
    <input class='btn btn-primary' type=submit id='submitbutton' name=%ACTION% value='%ACTION_LNG%'>
  </div>
</div>

</form>
</div>

<script>
    jQuery('#paid_type').on('submit', function(){
        renameAndDisable('submitbutton', '_{IN_PROGRESS}_...' );
    });
</script>