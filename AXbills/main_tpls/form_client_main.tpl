<nav class='main-header navbar navbar-expand %NAVBAR_SKIN%'>

  <ul class='navbar-nav'>
    <li class='nav-item'>
      <a class='nav-link' data-widget='pushmenu' data-slide='true' href='#' role='button'>
        <i class='fa fa-th-large'></i>
      </a>
    </li>
  </ul>
  <ul class='navbar-nav ml-auto'>
    <li class='nav-item d-none d-sm-inline-block'>
      <span class='nav-link'><strong>_{DATE}_:</strong> %DATE% %TIME%</span>
    </li>
    <li class='nav-item d-none d-sm-inline-block' %REG_LOGIN%>
      <span class='nav-link'><strong>_{LOGIN}_:</strong> %LOGIN%</span>
    </li>
    <li class='nav-item d-none d-sm-inline-block'>
      <span class='nav-link'><strong>IP:</strong> %IP%</span>
    </li>
    <li class='nav-item d-none d-sm-inline-block' %REG_STATE%>
      <span class='nav-link'><strong>_{STATE}_:</strong> %STATE%</span>
    </li>
  </ul>

  <ul class='navbar-nav ml-auto'>
    <li class='nav-item dropdown'>
      <a href='#'>
        <div class='input-group input-group-sm input-group-custom-select'>
          %SELECT_LANGUAGE%
        </div>
      </a>
    </li>
  </ul>
</nav>
<!-- menu -->
  <aside id='main-sidebar' class='main-sidebar %SIDEBAR_SKIN% elevation-4'>
    <a href='%INDEX_NAME%' class='logo' %S_MENU%>
      <a href='index.cgi' class='brand-link pb-2 text-center' style='font-size: 1.25rem; padding: .55rem .5rem;'>
		<img src='$conf{MINI_LOGO}' class='brand-image-xl logo-xs mt-2'>
		<img src='$conf{FULL_LOGO}' class='brand-text font-weight-light'>
      </a>
    </a>
    <div class='sidebar'>
      %MENU%
    </div>
  </aside>
  <div id='content-wrapper' class='content-wrapper'>
    <section class='content p-2' id='main-content'>
      <br/>
      %BODY%
    </section>
  </div>
</div>

<!-- client_start End -->

<script>
  if(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {
    jQuery('#language_mobile').on('change', selectLanguage);
  } else {
    jQuery('#language').on('change', selectLanguage);
  }


  /* Double click mouse control */
  jQuery('form').submit(() => {
    if (jQuery('input[type=submit]:focus').hasClass('double_click_check')) {
      jQuery('input[type=submit]:focus').addClass('disabled');
      const val = jQuery('input[type=submit]:focus').attr('val') || '1';
      const name = jQuery('input[type=submit]:focus').attr('name');
      jQuery('<input />').attr('type', 'hidden')
        .attr('name', name)
        .attr('value', val)
        .appendTo('form');
      jQuery('input[type=submit]:focus').attr('disabled', true);
    }
    if (jQuery('button[type=submit]:focus').hasClass('double_click_check')) {
      jQuery('button[type=submit]:focus').addClass('disabled');
      const val = jQuery('button[type=submit]:focus').attr('val') || '1';
      const name = jQuery('button[type=submit]:focus').attr('name');
      jQuery('<input />').attr('type', 'hidden')
        .attr('name', name)
        .attr('value', val)
        .appendTo('form');
      jQuery('button[type=submit]:focus').attr('disabled', true);
    }
  });
</script>
%PUSH_SCRIPT%
<script src='/styles/default/js/axbills/control-web-client.js' defer></script>
</body>

%CHECK_ADDRESS_MODAL%