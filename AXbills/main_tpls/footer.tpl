</section>
<!-- /.content -->
</div>
<!-- /.content-wrapper -->

<!-- Main Footer -->
<footer class='main-footer'>
  %FOOTER_CONTENT%
  %FOOTER_DEBUG%
  <div class='px-1 my-n1 row justify-content-between align-items-center'>
    <div class='d-flex align-items-center' style='column-gap: 4px'>
      <a href='https://billing.axiostv.ru' target='_blank'>
        <img src='$conf{MINI_LOGO}' class='brand-text font-weight-light'>
      </a>
      %VERSION%
    </div>
    <div class='d-inline-block'>
      <button id='feedback_modal_btn' type='button' class='btn btn-primary btn-xs'
              onclick="loadToModal('?POPUP=1&FEEDBACK=1')">
        <span class='fa fa-comment'></span>
      </button>
    </div>
  </div>
</footer>
<!-- Control Sidebar -->
%RIGHT_MENU%
<script src='/styles/default/js/old/control-sidebar.js' defer></script>
<script src='/styles/default/js/axbills/control-web.js' defer></script>

<script>
  /* Closing right sidebar by resize */
  function controlRightMenu() {
    if(mybody.classList.contains('control-sidebar-slide-open')) {
      if(mybody.clientWidth < 1200) {
        rightSidebarButton.click();
      }
    } else {
      if('$admin->{RIGHT_MENU_OPEN}' !== '') {
        if(mybody.clientWidth > 1200) {
          rightSidebarButton.click();
        }
      }
    }
  }
  window.addEventListener('resize', controlRightMenu, false);

  /* Double click mouse control */
  jQuery('form').submit(() => {
    if (jQuery('input[type=submit]:focus').hasClass('double_click_check')) {
      jQuery('input[type=submit]:focus').addClass('disabled').val('_{IN_PROGRESS}_...');
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

