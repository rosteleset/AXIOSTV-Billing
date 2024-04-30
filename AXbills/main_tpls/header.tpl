<!-- Main container -->
<script src='/styles/default/js/jquery.marcopolo.min.js'></script>
<nav class='main-header navbar navbar-expand %HEADER_FIXED_CLASS% $admin->{SETTINGS}{SKIN}'
    role='navigation'>
  <ul class='navbar-nav'>
    <li class='nav-item'>
      <a class='nav-link' data-widget='pushmenu' href='#' title='_{PRIMARY}_ _{MENU}_'>
        <i class='fa fa-bars'></i>
      </a>
    </li>
    <li class='nav-item'>
      <a class='nav-link' href='%SELF_URL%'>
        <i class='fa fa-home'></i>
      </a>
    </li>
  </ul>

  <ul class='navbar-nav ml-auto'>

    %GLOBAL_CHAT%

    <li class='nav-item dropdown' id='messages-menu' data-meta='{%ADMIN_MSGS%}'>
      <a href='#' class='nav-link dropdown-toggle' data-toggle='dropdown' title='_{MESSAGES}_ _{ALL}_'>
        <i class='far fa-envelope'></i>
        <span id='badge_messages-menu' class='icon-label label label-danger hidden'></span>
      </a>
      <div class='dropdown-menu dropdown-menu-lg dropdown-menu-right' id='dropdown_messages-menu'>
        <span class='dropdown-item dropdown-header' id='header_messages-menu'>
          <h6 class='header_text float-left pt-1'></h6>
            <div class='text-right'>
              <div class='btn-group'>
                <form action='%SELF_URL%'>
                  <div class='btn btn-sm btn-primary' id='dropdown_search_button'>
                    <i class='fa fa-search' role='button'></i>
                  </div>
                </form>
              </div>
              <div class='btn-group'>
                <button class='btn btn-sm btn-success header_refresh'>
                  <i class='fas fa-sync' role='button'></i>
                </button>
              </div>
            </div>
        </span>
        <div class='dropdown-divider'></div>
        <div class='dropdown-item' id='drop_search_form' style='display: none'>
          <form action='%SELF_URL%' style='width: 100%'>
            <input type='hidden' name='get_index' value='msgs_admin'>
            <input type='hidden' name='full' value='1'>
            <div class='input-group'>
              <input type='text' id='search_input' name='chg' class='form-control'/>
              <div class='input-group-append'>
                <button name='search' class='btn btn-default' type='submit'>
                  <i class='fa fa-search'></i>
                </button>
              </div>
            </div>
          </form>
        </div>

        <div class='dropdown-items-list' id='menu_messages-menu'>
          <div class='text-center'>
            <i class='fa fa-spinner fa-pulse fa-2x'></i>
          </div>
        </div>

        <div class='dropdown-divider'></div>
        <a id='footer_messages-menu' class='dropdown-item dropdown-footer' href='%SELF_URL%?get_index=msgs_admin&full=1'>_{SHOW}_
          _{ALL}_</a>
      </div>
    </li>

    <li class='nav-item dropdown' id='responsible-menu' data-meta='{%ADMIN_RESPONSIBLE%}'>
      <a href='#' class='nav-link dropdown-toggle' data-toggle='dropdown' title='_{MESSAGES}_ _{RESPOSIBLE}_'>
        <i class='far fa-flag'></i>
        <span id='badge_responsible-menu' class='icon-label label label-danger hidden'></span>
      </a>

      <div class='dropdown-menu dropdown-menu-lg dropdown-menu-right' id='dropdown_responsible-menu'>
        <span class='dropdown-item dropdown-header' id='header_responsible-menu'>
          <h6 class='header_text float-left pt-1'></h6>
            <div class='text-right'>
              <div class='btn-group'>
                <button class='btn btn-sm btn-success header_refresh'>
                  <i class='fas fa-sync' role='button'></i>
                </button>
              </div>
            </div>
        </span>

        <div class='dropdown-divider'></div>
        <div class='dropdown-items-list' id='menu_responsible-menu'>
          <div class='text-center'>
            <i class='fa fa-spinner fa-pulse fa-2x'></i>
          </div>
        </div>

        <div class='dropdown-divider'></div>
        <a id='footer_responsible-menu' class='dropdown-item dropdown-footer' href='%SELF_URL%?get_index=msgs_admin&STATE=0&RESPOSIBLE=%AID%&full=1'>_{SHOW}_ _{ALL}_</a>
      </div>
    </li>

    <li data-hidden="%EVENTS_DISABLED%" class='nav-item dropdown' id='events-menu' style='display: none' data-meta='{
          "HEADER": "_{EVENTS}_",
          "UPDATE": "?get_index=events_notice&header=2&AJAX=1",
          "AFTER": 30,"REFRESH": 30, "ENABLED": "%EVENTS_ENABLED%"
          }'>

      <a href='#' class='nav-link dropdown-toggle' data-toggle='dropdown' title='_{EVENTS}_'>
        <i class='far fa-bell'></i>
        <span id='badge_events-menu' class='icon-label label label-danger hidden'></span>
      </a>

      <div class='dropdown-menu dropdown-menu-lg dropdown-menu-right' id='dropdown_events-menu'>
        <span class='dropdown-item dropdown-header' id='header_events-menu'>
          <h6 class='header_text float-left pt-1'></h6>
            <div class='text-right'>
              <div class='btn-group'>
                <button class='btn btn-sm btn-success header_refresh'>
                  <i class='fas fa-sync' role='button'></i>
                </button>
              </div>
            </div>
        </span>

        <div class='dropdown-divider'></div>
        <div class='dropdown-items-list' id='menu_events-menu'>
          <div class='text-center'>
            <i class='fa fa-spinner fa-pulse fa-2x'></i>
          </div>
        </div>

        <div class='dropdown-divider'></div>
        <a id='footer_events-menu' class='dropdown-item dropdown-footer' href='%SELF_URL%?get_index=events_profile&full=1'>_{SHOW}_ _{ALL}_</a>
      </div>
    </li>

    <!--Search Menu-->
    <li class='nav-item mr-2 d-md-none d-sm-inline-block dropdown search-menu'>
      <form class='no-live-select UNIVERSAL_SEARCH_FORM' id='SMALL_SEARCH_FORM' action='%SELF_URL%'>
        <input type='hidden' name='index' value='7'>
        <input type='hidden' name='search' value='1'>
      </form>
      <a href='#' class='nav-link' data-toggle='dropdown'>
        <i class='fa fa-search'></i>
      </a>
      <ul class='dropdown-menu dropdown-menu-lg dropdown-menu-right' onClick='cancelEvent(event)'>
        <li class='p-2'>
          <div class='search_selector'>
            %SEL_TYPE_SM%
          </div>
        </li>
        <li class='p-2'>
          <div class='input-group margin'>
            <input type='text' name='LOGIN' class='form-control UNIVERSAL_SEARCH'
                   placeholder='_{SEARCH}_...' form='SMALL_SEARCH_FORM'>
            <div class='input-group-append'>
              <button type='submit' name='search' class='btn btn-default'
                      onclick=jQuery('form#SMALL_SEARCH_FORM').submit()>
                <i class='fa fa-search'></i>
              </button>
            </div>
          </div>
        </li>
      </ul>
    </li>

    <form class='no-live-select UNIVERSAL_SEARCH_FORM d-inline-flex' action='%SELF_URL%'>
      <input type='hidden' name='index' value='7'>
      <input type='hidden' name='search' value='1'>
      <li class='header nav-item mr-2 d-none d-md-inline-block'>
        <div class='input-group input-group-sm input-group-custom-select'>
          %SEL_TYPE%
        </div>
      </li>
      <li class='nav-item search-menu d-none d-md-inline-block'>
        <div class='input-group input-group-sm'>
          <input type='text' name='LOGIN'
                 class='form-control margin search-type-select not-chosen UNIVERSAL_SEARCH'
                 placeholder='_{SEARCH}_...'>
          <div class='input-group-append'>
            <button type='submit' id='search-btn' class='btn btn-default'>
              <i class='fa fa-search'></i>
            </button>
          </div>
        </div>
      </li>
    </form>

    <li id='wiki-link' class='nav-item d-none d-sm-inline-block'>
      <a href='https://support.billing.axiostv.ru/doc.cgi?url=%FUNCTION_NAME%'
          id='wiki_url' target='_blank' rel='noopener' title='ABillS Wiki' class='nav-link'>
        <i class='fa fa-question'></i>
      </a>
    </li>

    <li class='nav-item d-none d-sm-inline-block'>
      <a href='#' class='nav-link' title='QRCode'
          onclick='showImgInModal(\"%SELF_URL%?$ENV{QUERY_STRING}&amp;qrcode=1&amp;qindex=100000&amp;name=qr_code\", \"_{QR_CODE}_\")'>
        <i class='fa fa-qrcode'></i>
      </a>
    </li>

    <li class='nav-item' id='control-sidebar-open-btn'>
      <a class='nav-link' data-widget='control-sidebar' data-slide='true' id='right_menu_btn' href='#'
          role='button' title='_{GUIDE_RIGHT_MENU}_'>
        <i class='fa fa-th-large'></i>
      </a>
    </li>
  </ul>
</nav>
<script>

  if('$admin->{RIGHT_MENU_OPEN}' !== '') {
    if(document.body.clientWidth > 992) {
      document.body.classList.add('control-sidebar-slide-open');
    }
  }

  jQuery(function () {
    var EVENT_PARAMS = {
      portal: 'admin',
      link: '/admin/index.cgi?get_index=form_events&even_show=1&AID=$admin->{AID}',
      soundsDisabled: ('$admin->{SETTINGS}{NO_EVENT_SOUND}' == '1'),
      disabled: ('$admin->{SETTINGS}{NO_EVENT}' == '1') || ('%EVENTS_DISABLED%' == '1'),
      interval: parseInt('$conf{EVENTS_REFRESH_INTERVAL}') || 30000
    };
    AMessageChecker.start(EVENT_PARAMS);

    // var urlWiki = jQuery('#wiki_url').attr('href');
    // var pattern = /doc.cgi/
    // if (pattern.test(urlWiki)) {
    //   jQuery('#wiki_url').attr('href', urlWiki);
    // } else {
    //   jQuery('#wiki_url').attr('href', '$ENV{DOC_URL}');
    // }
  });
</script>

<aside class='main-sidebar sidebar-dark-lightblue elevation-4'>
  <a href='index.cgi' class='brand-link pb-2 text-center' style='font-size: 1.25rem; padding: .55rem .5rem;'>
	<img src='$conf{MINI_LOGO}' class='brand-image-xl logo-xs mt-2'>
	<img src='$conf{FULL_LOGO}' class='brand-text font-weight-light'>
  </a>
  <div class='sidebar' style='overflow-y: auto'>
    <div class='user-panel mt-3 pb-3 mb-3 d-flex'>
      <div class='image'>
        <a href='%SELF_URL%?index=9'>
          <img src='%AVATAR_LOGO%' class='img-circle elevation-2' alt='User Image'>
        </a>
      </div>
      <div class='info'>
        <a class='d-block' href='#'>$admin->{A_FIO}</a>
        <a href='#' id='admin-status' data-toggle='tooltip' data-placement='right' data-html='true'
           title='%ONLINE_USERS%'>Online&nbsp;<span class='badge badge-info right'>%ONLINE_COUNT%</span></a>
      </div>
    </div>
    <div class='form-inline' id='search-div'>
      <div class='input-group' data-widget='sidebar-search'>
        <input class='form-control form-control-sidebar' type='search' id='Search_menus' placeholder='_{SEARCH}_'
          aria-label='Search'>
        <div class='input-group-append'>
          <button id='sidebar_button' class='btn btn-sidebar'>
            <i class='fa fa-search fa-fw'></i>
          </button>
        </div>
      </div>
    </div>
    %MENU%
  </div>
</aside>
<div class='content-wrapper' id='content-wrapper' style='min-height: calc(100vh - %CONTENT_OFFSET%)'>
  %ISP_EXPRESSION%

  %BREADCRUMB%
  <section class='content' id='main-content'>
    <!-- Your Page Content Here -->
