<!--Begin of DHCP Routes-->
    <div class='card card-primary card-outline box-form'>
      <div class='card-body'>
        <form action='$SELF_URL' method='post'>
        <input type='hidden' name='index' value='$index' />
        <input type='hidden' name='NET_ID' value='$FORM{NET_ID}' />
        <input type='hidden' name='ID' value='$FORM{chg}' />
        <div class='form-group'>
          <div class='row'>
            <label for='SRC' class='control-label col-md-4'>_{HOSTS_SRC}_:</label>
            <div class='col-md-8'>
              <input class='form-control' type='text' name='SRC' value='%SRC%' />
            </div>
          </div>
        </div>
        <div class='form-group'>
          <div class='row'>
            <label for='MASK' class='control-label col-md-4'>NETMASK:</label>
            <div class='col-md-8'>
              <input class='form-control' type='text' name='MASK' value='%MASK%' />
            </div>
          </div>
        </div>
        <div class='form-group'>
          <div class='row'>
            <label for='ROUTER' class='control-label col-md-4'>_{HOSTS_ROUTER}_:</label>
            <div class='col-md-8'>
              <input class='form-control' type='text' name='ROUTER' value='%ROUTER%' />
            </div>
          </div>
        </div>
        <div class='form-group'>
          <div class='row'>

          </div>
        </div>
           </div>
         <div class='card-footer'>
           <div class='row'>
           <div class='col-md-12'>
              <input class='btn btn-primary' type='submit' name='%ACTION%' value='%ACTION_LNG%' />
               </div>
          </div>
          </div>
     </form>
    </div>
<!--End of DHCP Routes-->
