<form name="login" action="%HOTSPOT_AUTO_LOGIN%" method="post">
  <div class='form-group col-xs-12 col-md-2' style="display: none;">
    <input class='form-control' type="text" name="username" value="%LOGIN%">
  </div>
  <div class='form-group col-xs-12 col-md-2' style="display: none;">
    <input class='form-control' type="password" name="password" value="%PASSWORD%">
  </div>
  <input type="hidden" name="domain" value="">
  <input type="hidden" name="dst" value="%DST%">
  <div class='form-group col-xs-12 col-md-2'>
    <input type="submit" name="login" value="log in" class='btn btn-primary' style="display: none;">
  </div>
</form>

<iframe src="%ADVERTISEMENT%" style="width: 100vw; height: 100vh; margin-top: -25px" frameborder="0"></iframe>
<style>
  #timer {
    background: #0e94f6;
    position: fixed;
    bottom: 20px;
    right: 20px;
    width: 270px;
    height: 50px;
    color: white;
    text-align: center;
    line-height: 49px;
  }
</style>
<div id="timer">_{WAIT}_ <span id="time">%TIME%</span> _{SECONDS}_</div>

<script language="JavaScript">
  var time = %TIME% * 1000,
  timer = setInterval(function () {
    document.getElementById('time').innerHTML = time / 1000;
    time -= 1000;
  }, 1000);
  setTimeout(function () {
    clearInterval(timer);
    document.getElementById('timer').innerHTML = "_{CONTINUE}_";
    document.getElementById('timer').setAttribute('onclick', 'submit()');
  }, time + 1000);
  function submit() {
    document.login.submit();
  }
</script>
