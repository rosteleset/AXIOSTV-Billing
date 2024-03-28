<script>
  jQuery(function () {
    jQuery('#add_uid').on('click', function () {

      let uid = jQuery('#UID_HIDDEN').val();

      if (uid) {
        jQuery.get('?qindex=%index%&header=2&LEAD_ID=$FORM{LEAD_ID}&add_uid=' + uid, function (data) {
          document.location.href = `?get_index=form_users&full=1&UID=${uid}`;
        });
      } else {
        alert('_{USER_NOT_EXIST}_');
      }
    });
  });
</script>

<input type=hidden name=UID id='UID_HIDDEN' value='%UID%'/>
<div class='form-group row mb-2'>
  <div class='col-md-12'>
    <div class='input-group'>
      <div class='input-group-prepend'>
        %USER_SEARCH%
      </div>
      <input type='text' form='unexistent' class='form-control' name='LOGIN' value='%USER_LOGIN%' id='LOGIN'
             readonly='readonly'/>
      <div class='input-group-append'>
        <button type='button' class='btn btn-primary fa fa-plus' id='add_uid' data-tooltip='_{MATCH_USER}_'></button>
        %DELETE_USER_BTN%
      </div>
    </div>
  </div>
</div>
