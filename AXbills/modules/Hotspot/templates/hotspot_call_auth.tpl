<form METHOD='POST' class='form-inline'>
  <input type=hidden name='PHONE' value='%PHONE%'>
  <input type=hidden name='mac' value='%mac%'>
  <div class='card card-primary card-outline'>
    <div class='card-body'>
      <p>Перезвоните на номер <a href="tel:%AUTH_NUMBER%">%AUTH_NUMBER%</a></p>
    </div>
  </div>
</form>
<script src='/styles/default/js/jquery.min.js'></script>
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
