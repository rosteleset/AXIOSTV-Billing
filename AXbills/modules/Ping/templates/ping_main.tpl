
<form action='$SELF_URL' class='form-horizontal'>

  <fieldset>
   <input type=hidden  name=index value='$index'>

   <div class="card card-primary card-outline ">
    <div class="card-header with-border">
      <h3 class="card-title">_{THE_SYSTEMOF_LAST_MILE}_</h3>
      <div class="card-tools float-right">
        <button type="button" class="btn btn-secondary btn-xs" data-card-widget="collapse"><i class="fa fa-minus"></i>
        </button>
      </div>
    </div>
    <div class="card-body">

      <div class='form-group'>
        <label class='control-label col-md-3' for='PACKET_NUM_ID'>_{PACKET_NUM}_</label>
        <div class='col-md-9'>
            <input type="number" min='0' class='form-control' value='%PACKET_NUM%'  name='PACKET_NUM'  id='PACKET_NUM_ID'   />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PACKET_SIZE_ID'>_{PACKET_SIZE}_</label>
        <div class='col-md-9'>
            <input type='number' min='0' class='form-control' value='%PACKET_SIZE%'  name='PACKET_SIZE'  id='PACKET_SIZE_ID'    />
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='PERIODIC_ID'>_{PERIODIC}_</label>
        <div class='col-md-9'>
            <input class='form-control' value='%PERIODIC%'  name='PERIODIC'  id='PERIODIC_ID'  />
        </div>
      </div>

    <div class='form-group'>
        <label class='control-label col-md-3' for='ACCEPTABLE_LOSS_RATEIC_ID'>_{ACCEPTABLE_LOSS_RATE}_</label>
        <div class='col-md-9'>
            <input type='number' min='0' class='form-control' value='%ACCEPTABLE_LOSS_RATE%'  name='ACCEPTABLE_LOSS_RATE'  id='ACCEPTABLE_LOSS_RATEIC_ID'   />
        </div>
      </div>

    <div class='form-group'>
        <label class='control-label col-md-3' for='CRITICAL_RATE_LOSSES'>_{CRITICAL_RATE_LOSSES}_</label>
        <div class='col-md-9'>
            <input type='number' min='0' class='form-control' value='%CRITICAL_RATE_LOSSES%'  name='CRITICAL_RATE_LOSSES'  id='CRITICAL_RATE_LOSSES_ID'    />
        </div>
      </div>

    <div class='form-group'>
        <label class='control-label col-md-3' for='TIMEOUT'>_{TIMEOUT}_</label>
        <div class='col-md-9'>
            <input type='number' min='0' class='form-control' value='%TIMEOUT%'  name='TIMEOUT'  id='TIMEOUT'   />
        </div>
      </div>

    <div class='form-group'>
        <label class='control-label col-md-3' for='PING_PERIODIC'>_{PING_PERIODIC}_</label>
        <div class='col-md-9'>
            <input type='number' min='0' class='form-control' value='%PING_PERIODIC%'  name='PING_PERIODIC'  id='PING_PERIODIC'   />
        </div>
    </div>

    <div class='form-group'>
        <label class='control-label col-md-3' for='THREADS'>_{THREADS}_</label>
        <div class='col-md-9'>
            <input type='number' min='0' class='form-control' value='%THREADS%'  name='THREADS'  id='THREADS'   />
        </div>
    </div>

    <input name="ACCEPT" value="_{ACCEPT}_"  class="btn btn-primary" type="submit">


    </div>
  </div>
</fieldset>
</form>