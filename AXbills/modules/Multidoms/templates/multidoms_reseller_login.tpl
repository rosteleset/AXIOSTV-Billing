<script type='text/javascript'>
  function set_referrer() {
    document.getElementById('REFERER').value = location.href;
  }

  jQuery(function () {
    if ('%TECH_WORKS_BLOCK_VISIBLE%' === '1') {
      jQuery('#tech_works_block').css('display', 'block');
    }

    if(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {
      jQuery('#language_mobile').on('change', selectLanguage);
    } else {
      jQuery('#language').on('change', selectLanguage);
    }
  })
</script>
<style>
  .wrapper {
    overflow: visible;
  }
</style>

<nav class='navbar navbar-default' role='navigation'>
  <div class='container-fluid navbar-right'>
    <h1 style='font-weight: 600;'>
      <img src='$conf{FULL_LOGO}' class='brand-text font-weight-light'>
      <small>%TITLE%</small>
      &nbsp;
    </h1>
  </div>
</nav>

<div class='container-fluid'>

  <div class='row'>
    <div class='col-md-6 col-md-offset-3'>
      %ERROR_MSG%
    </div>
  </div>

  <div class='row'>
    <div class='col-md-6 col-md-offset-3'>
      <div class='info-box bg-yellow' style='display: none;' id='tech_works_block'>
        <span class='info-box-icon'><i class='fa fa-wrench'></i></span>
        <!--line height to center text vertical-->
        <div class='info-box-content' style='line-height: 80px'>
          <!--<span class='info-box-text'>_{TECH_WORKS_ARE_RUNNING_NOW}_</span>-->
          <span class='info-box-number text-center'>%TECH_WORKS_MESSAGE%</span>
        </div><!-- /.info-box-content -->
      </div><!-- /.info-box -->
    </div>
  </div>

  <div class='row'>
    <form action='$SELF_URL' METHOD='post' name='frm' id='form_login' class='form-horizontal'>

      <input type=hidden name=DOMAIN_ID value='%DOMAIN_ID%'>
      <input type=hidden ID=REFERER name=REFERER value='%REFERER%'>
      <input type='hidden' name='LOGIN' value='1'/>
      <fieldset>

        <div class='col-xs-12 col-md-4 col-md-offset-4 col-lg-2 col-lg-offset-5'>
          <div class='form-group has-feedback'>
            <div class='input-group'>
              <span class='input-group-addon fa fa-globe'></span>
              %SEL_LANGUAGE%
            </div>
          </div>

          <div class='form-group'>
            <div class="input-group">
             <span class="input-group-addon fa fa-user"></span>
             <input type='text' id='user' name='user' value='%user%' class='form-control' placeholder='_{LOGIN}_'>
            </div>
          </div>

          <div class='form-group'>
            <div class="input-group">
              <span class="input-group-addon fa fa-lock"></span>
            <input type='password' id='passwd' name='passwd' value='%password%' class='form-control'
                   placeholder='_{PASSWD}_'>
            </div>
          </div>

          <div class='row'>
            <!-- /.col -->

              <button type='submit' name='logined' class='btn btn-success btn-block btn-flat form-control'
                      onclick='set_referrer()'>_{ENTER}_
              </button>

            <!-- /.col -->
          </div>
        </div>
      </fieldset>
    </form>
  </div>
</div>

