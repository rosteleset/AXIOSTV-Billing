<form action='$SELF_URL' METHOD='POST' class='form-inline' name=admin_form>
    
    <input type=hidden name='DOMAIN_ID' value='%DOMAIN_ID%'>
    <input type=hidden name='PHONE' value='%PHONE%'>
    <input type=hidden name='mac' value='%mac%'>
    <input type=hidden name='server_name' value='%server_name%'>
    <input type=hidden name='link_login_only' value='%link_login_only%'>

    <fieldset>
        <div class='card card-primary card-outline'>
            <div class='card-body'>
                Перезвоните на номер <a href="tel:%AUTH_NUMBER%">%AUTH_NUMBER%</a>
            </div>
        </div>
        %BUTTON%

    </fieldset>

</form>
<script>
jQuery(function(){
  setInterval(function(){ check_call(); }, 3000);
});

function check_call() {
  jQuery.ajax({
    url: '$SELF_URL?ajax=1&mac=%mac%&PHONE=%PHONE%',
    success: function(result){
      if(result == '1') {
        document.location.href = 'http://google.com';
      }
    }
  });
}

</script>
