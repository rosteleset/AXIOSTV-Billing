<form METHOD='POST' class='form-inline' name=admin_form>
  <input type=hidden name='PHONE' value='%PHONE%'>
  <input type=hidden name='mac' value='%mac%'>
  <div class='box box-theme'>
    <div class='box-body'>
      <p>Перезвоните на номер <a href="tel:123456789">123456789</a></p>
    </div>
  </div>
</form>
<script src='/styles/default_adm/js/jquery.min.js'></script>
<script>
jQuery(function(){
  setInterval(function(){ check_call(); }, 3000);
});

function check_call() {
  jQuery.ajax({
    url: window.location.href + '?ajax=1&mac=%mac%&PHONE=%PHONE%',
    success: function(result){
      if(result == '1') {
        document.location.href = 'http://google.com';
      }
    }
  });
}

</script>
