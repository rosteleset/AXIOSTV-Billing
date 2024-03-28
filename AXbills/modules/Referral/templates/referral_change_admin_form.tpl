<div class='card card-primary card-outline box-form container-md'>
  <div class='card-header with-border text-center'><h5>_{ADD_FRIEND}_</h5></div>
  <form name='ADD_FRIEND' id='form_ADD_FRIEND' method='post' class='form form-horizontal'>
    <div class='card-body'>

      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>
      <input type='hidden' name='REFERRER_UID' value='%REFERRER_UID%'/>
      <input type='hidden' name='REFERRAL_UID' value='%REFERRAL_UID%' id='REFERRAL_UID' />
      <div class='form-group row'>
        <label class='control-label col-md-4' for='FIO'>_{FIO}_</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='FIO' value='%fio%'
                 id='FIO'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4' for='PHONE'>_{PHONE}_</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' name='PHONE' value='%phone%'
                 id='PHONE'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4' for='REFERRAL_LOGIN'>_{USER}_</label>
          <div class='input-group col-md-8'>
            <div class='input-group-prepend'>
              %USER_SEARCH%
            </div>
            <input type='text' form='unexistent' class='form-control col-md-3' name='LOGIN' value='%LOGIN%' id='LOGIN'
                   readonly='readonly' style='display: none'/>
            %REFERRAL_BUTTON%
          </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4'> </label>
        <div class='col-md-8'>
          %ADDRESS_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-4'>_{STATUS}_</label>
        <div class='col-md-8'>
          %STATUS_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4'>_{TARIF_PLAN}_</label>
        <div class='col-md-8'>
          %TARIF_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-md-8'>
           <textarea cols="10" style="resize: vertical" class='form-control' name='COMMENTS'
                              id='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>
      <div class='form-group row'>
        <label class='control-label col-md-4' for='INNER_COMMENTS'>_{INNER_COMMENT}_</label>
        <div class='col-md-8'>
           <textarea cols="10" style="resize: vertical" class='form-control' name='INNER_COMMENTS'
                     id='INNER_COMMENTS'>%INNER_COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      %ACTION%
    </div>
  </form>
</div>

<script>

  jQuery(function(){
    Events.on('search_form.value_selected.UID', function(data_str){
      var uid = 0, login = 0;
      var uid_login = data_str.split('#@#');

      uid = uid_login[0].split('::')[1];
      login = uid_login[1].split('::')[1];
      var referralUid = document.querySelector("input[name='REFERRAL_UID']");
      if (referralUid) {
        referralUid.value = uid;
      }

      var referralLogin = document.getElementById("LOGIN");
      referralLogin.style.display = 'block';
    });
  });

  var referralUid = jQuery('#REFERRAL_UID').val();
  if (referralUid > 0){
    var fio = document.getElementById('FIO');
    var phone = document.getElementById('PHONE');
    var district = document.getElementById('DISTRICT_ID') || document.getElementById('DISTRICT_ID0');
    var street = document.getElementById('STREET_ID');
    var build = document.getElementById('BUILD_ID');
    var flat = document.getElementById('ADDRESS_FLAT');

    fio.disabled = true;
    if (phone){
      phone.disabled = true;
    }
    if (district){
      district.disabled = true;
    }
    if (street){
      street.disabled = true;
    }
    if (build){
      build.disabled = true;
    }
    if (flat){
      flat.disabled = true;
    }
  }

</script>