<div class='card card-form card-primary card-outline'>
  <div class='card-header with-border text-center'>
    <h3 class='card-title'>%TITLE%</h3>
  </div>
  <form name='ADD_FRIEND' id='form_ADD_FRIEND' method='post' class='form form-horizontal'>
    <div class='card-body'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>

      <div class='form-group row'>
        <label class='control-label col-md-3 col-sm-3 required' for='FIO'>_{FIO}_</label>
        <div class='col-sm-9 col-md-9'>
          <input type='text' required class='form-control' name='FIO' value='%FIO%' id='FIO'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3 col-sm-3 required' for='PHONE'>_{PHONE}_</label>
        <div class='col-sm-9 col-md-9'>
          <input type='text' required class='form-control' name='PHONE' value='%PHONE%' id='PHONE'/>
        </div>
      </div>

      %ADDRESS_SEL%

      <div class='form-group row'>
        <label class='control-label col-md-3 col-sm-3' for='COMMENTS'>_{COMMENTS}_</label>
        <div class='col-sm-9 col-md-9'>
          <textarea cols="10" style="resize: vertical" class='form-control' name='COMMENTS' id='COMMENTS'>%COMMENTS%</textarea>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      %ACTION%
    </div>
  </form>
</div>

<div class='card card-form card-primary card-teal card-outline %LINK_SHOW%'>
  <div class='card-header with-border text-center'>
    <h3 class='card-title'>_{INVITE_A_FRIEND}_ URL</h3>
  </div>
  <div class='card-body'>
    <div class='form-group row'>
      <label class='col-sm-3 col-md-3' for='referral-link'>_{OR_SEND_URL}_</label>
      <div class='col-sm-9 col-md-9 input-group'>
        <input type='text' class='form-control' id='referral-link' readonly value='%REFERRAL_LINK%'/>
        <div class='input-group-append'>
          <button class='btn input-group-button' onclick='copyLink()' id='copy-referral-link' type='button'>_{COPY}_</button>
        </div>
      </div>
    </div>
  </div>
</div>

%TABLE%
%GET_BONUS%
<script>
  function copyLink() {
    var copyText = document.getElementById('referral-link');
    copyText.select();
    copyText.setSelectionRange(0, 99999);
    document.execCommand('copy');
  }
</script>
