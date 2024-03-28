<form name='login' action='%HOTSPOT_AUTO_LOGIN%' method='post'>
  <div class='form-group col-xs-12 col-md-2' style='display: none;'>
    <input class='form-control' type='text' name='username' value='%LOGIN%'>
  </div>
  <div class='form-group col-xs-12 col-md-2' style='display: none;'>
    <input class='form-control' type='password' name='password' value='%PASSWORD%'>
  </div>
  <input type='hidden' name='domain' value=''>
  <input type='hidden' name='dst' value='%DST%'>
  <div class='form-group col-xs-12 col-md-2'>
    <input type='submit' name='login' value='log in' class='btn btn-primary' style='display: none;'>
  </div>
</form>

<script language='JavaScript'>
<!--
  document.login.submit();
//-->
</script>
