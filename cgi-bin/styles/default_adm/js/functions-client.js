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
    form_info                    : 'fa fa-user',
    form_payments                :  CURRENCY_ICON,
    form_finance                 :  CURRENCY_ICON,
    dv_user_info                 : 'fa fa-globe',
    docs_invoices_list           : 'fa fa-briefcase',
    msgs_user                    : 'fa fa-comment',
    cards_user_payment           : 'fa fa-credit-card',
    logout                       : 'fa fa-sign-out',
    voip_user_info               : 'fa fa-phone',
    ureports_user_info           : 'fa fa-file',
    iptv_user_info               : 'fa fa-television',
    abon_client                  : 'fa fa-list',
    form_passwd                  : 'fa fa-lock',
    ipn_user_activate            : 'fa fa-road',
    bonus_service_discount_client: 'fa fa-gift',
    bonus_user                   : 'fa fa-gift',
    mail_users_list              : 'fa fa-envelope',
    poll_user                    : 'fa fa-bar-chart',
    megogo_user_interface        : 'fa fa-maxcdn',
    o_user                       : 'fa fa-book',
    sharing_user_main            : 'fa fa-share',
    cams_clients_streams         : 'fa fa-video-camera'
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
  
  // Load custom icons
  $.getJSON('/images/client_menu_icons.js', function(custom_icons){
    
    $.each(Object.keys(custom_icons), function(i, id){
      var $a = $sidebar.find('a#' + id);
    
      // Removes default icon
      $a.find('.fa.fa-circle').remove();
    
      // Inserts icon <span> saving .chevron-left if have one
      $a.html('<i class="' + custom_icons[id] + '"></i><span>' +  $a.html() + '</span>');
    });
    
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
      + (document['DOMAIN_ID'] ? '?DOMAIN_ID=' + document['DOMAIN_ID'] : '')
      + '&language=' + sLanguage;
  location.replace(sLocation);
}

function set_referrer() {
  document.getElementById('REFERER').value = location.href;
}

$(setIcons);


