<h2>Time expired</h2>

<a href="sms://123456?body=%SMS_CODE%">Send SMS (1 hour internet)</a>
<br>
<a href="sms://123456?body=%SMS_FREE_CODE%" %HIDE_BUTTON%>Send free SMS (30 min internet)</a>

<script src='/styles/default/js/jquery.min.js'></script>
<script>
jQuery(function(){
  setInterval(function(){ check_call(); }, 3000);
});

function check_call() {
  jQuery.ajax({
    url: window.location.href+'?ajax=2&mac=%mac%&date=%date%',
    success: function(result){
      console.log(result);
      if (result == '1') {
        document.location.href = 'http://google.com';
      }
    }
  });
}
</script>