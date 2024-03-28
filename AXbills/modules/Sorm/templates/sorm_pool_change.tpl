<form name='SORM_DICTIONARIES' class='form form-horizontal hidden-print form-main'>
  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='id' value=%ID%>
  <div class='card card-primary card-outline col-md-8 container'>

    <div class='card-header with-border'>SORM_DICTIONARIES</div>

    <div class='card-body'>
      <div class='form-group align-content-center'>
        <label for='SORM_IP_PLAN'>Справочник IP_PLAN</label>
    <div class='card-body'>
      <div class='form-group align-content-center'>
        <label class='col-sm-12 col-md-12' for='DESCRIPTION'>Справочник IP_PLAN</label>
        <div class='col-md-12'>
          <textarea class='form-control' id='DESCRIPTION' name='DESCRIPTION'>%DESCRIPTION%</textarea>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-sm-12 col-md-12' for='IPV4_START'>IPV4_START</label>
        <div class='col-md-12'>
          <textarea class='form-control' id='IPV4_START' name='IPV4_START'>%IPV4_START%</textarea>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-sm-12 col-md-12' for='SORM_EXTERNAL_ATTEMPTS'>IPV6_START</label>
        <div class='col-md-12'>
          <input type='text' class='form-control' id='IPV6_START' name='IPV6_START' value='%IPV6_START%'>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-sm-12 col-md-12' for='IPV4_END'>IPv4 END</label>
        <div class='col-md-12'>
          <input type='text' class='form-control' id='IPV4_END' name='IPV4_END' value='%IPV4_END%'>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-sm-12 col-md-12' for='IPV4_END'>BEGIN_TIME</label>
        <div class='col-md-12'>
          <input type='text' class='form-control' id='BEGIN_TIME' name='BEGIN_TIME' value='%BEGIN_TIME%'>
        </div>
      </div>
      <div class='form-group'>
        <label class='col-sm-12 col-md-12' for='IPV4_END'>END_TIME</label>
        <div class='col-md-12'>
          <input type='text' class='form-control' id='END_TIME' name='END_TIME' value='%END_TIME%'>
        </div>
      </div>

    </div>

    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LANG%'>
    </div>
  </div>
</form>
