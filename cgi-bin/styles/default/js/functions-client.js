/**
 * Created by Anykey on 20.08.2015.
 *
 * Functions that are used in Uportal v5
 */
'use strict';

var CLIENT_INTERFACE = 1;

/**
 * Set's predefined icons for menu items
 *
 * Just add new id and fa to decorate new menu element
 */
function setIcons() {
  var menu_icons = {
    form_info                    : 'fas fa-user',
    form_payments                :  CURRENCY_ICON,
    form_finance                 :  CURRENCY_ICON,
    dv_user_info                 : 'fas fa-globe',
    docs_invoices_list           : 'fas fa-briefcase',
    msgs_user                    : 'fas fa-comment',
    cards_user_payment           : 'fas fa-credit-card',
    logout                       : 'fas fa-sign-out-alt',
    voip_user_info               : 'fas fa-phone',
    ureports_user_info           : 'fas fa-file',
    iptv_user_info               : 'fas fa-tv',
    abon_client                  : 'fas fa-list',
    form_passwd                  : 'fas fa-lock',
    ipn_user_activate            : 'fas fa-road',
    bonus_service_discount_client: 'fas fa-gift',
    bonus_user                   : 'fas fa-gift',
    mail_users_list              : 'fas fa-envelope',
    poll_user                    : 'fas fa-chart-bar',
    megogo_user_interface        : 'fas fa-maxcdn',
    o_user                       : 'fas fa-book',
    sharing_user_main            : 'fas fa-share',
    cams_clients_streams         : 'fas fa-video'
  };

  var $sidebar = $('ul.nav-sidebar').children('li');
  var $menu_items = $sidebar.children('a');
  
  $.each($menu_items, function (i, entry) {
    
    var $entry = $(entry);
    var icon = (typeof (menu_icons[entry.id]) !== 'undefined')
        ? menu_icons[entry.id]
        : 'fa fa-circle';
    var regex_icon = /currency/ig;
    var result = icon.match(regex_icon);
    if (result === "currency" ) {
      $entry.html('<i class="nav-icon ' + icon + '"></i>&nbsp;&nbsp;&nbsp;' +  $entry.html());
    }
    else {
      $entry.html('<i class="nav-icon ' + icon + '"></i>' +  $entry.html());
    }
  });
}

function set_referrer() {
  document.getElementById('REFERRER').value = location.href;
}

function selectLanguage(){
  var sLanguage = '';
  if(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {
    sLanguage = jQuery('#language_mobile').val() || '';
  } else {
    sLanguage = jQuery('#language').val() || '';
  }
  
  var sLocation = document['SELF_URL'] + '?'
      + (document['DOMAIN_ID'] ? 'DOMAIN_ID=' + document['DOMAIN_ID'] : '')
      + '&login_page=1'
      + '&language=' + sLanguage;
  location.replace(sLocation);
}

function set_referrer() {
  document.getElementById('REFERER').value = location.href;
}

jQuery(document).ready(function () {
  jQuery('.hidden_empty_required_filed_check').on('click', function () {
    let form = jQuery(this).closest('form');
    if (form.length < 1) return;

    let hiddenRequiredEmptyFields = form.find("input[required], textarea[required], select[required]");
    hiddenRequiredEmptyFields.each((index, field) => {
      if (jQuery(field).val() || jQuery(field).width() > 1) return;

      jQuery(field).closest('.collapsed-card').find('.btn-tool > .fa-plus').first().click();
    })
  });
});

$(setIcons);


