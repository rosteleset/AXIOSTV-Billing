<link rel='stylesheet' href='/styles/default/css/bootstrap-tourist.css'>
<script src='/styles/default/js/bootstrap-tourist.min.js'></script>

<script>
  jQuery(function () {

//    localStorage.setItem('tour_current_step', '10');

    // Instance the tour
    var tour = new Tour({
//      debug   : true,
//       template: getTemplate,
      backdropOptions: {
        highlightOpacity: 0.2,
      },
      localization: {
        buttonTexts: {
          prevButton: "<span class='fa fa-backward'>",
          nextButton: "<span class='fa fa-forward'>",
          endTourButton: '_{FINISH}_'
        }
      },
      framework: 'bootstrap4',
      steps   : [
// Tutorial welcome
        {
          path    : '/admin/',
          orphan  : true,
          title   : '_{GUIDE_WELCOME}_',
          content : '_{GUIDE_WELCOME_TEXT}_',
          backdrop: true
        },

// Main menu
        {
          element : 'aside.main-sidebar',
          title   : '_{GUIDE_MAIN_MENU}_',
          content : '_{GUIDE_MAIN_MENU_TEXT}_',
          backdrop: true
        },
//Messages
        {
          element  : '#messages-menu',
          title    : '_{GUIDE_MESSAGES_MENU}_',
          content  : '_{GUIDE_MESSAGES_MENU_TEXT}_',
          backdrop : true,
          animation: false,
          placement: 'bottom'
        },

//Responsible
        {
          element  : '#responsible-menu',
          title    : '_{GUIDE_RESPONSIBLE_MENU}_',
          content  : '_{GUIDE_RESPONSIBLE_MENU_TEXT}_',
          backdrop : true,
          animation: false,
          placement: 'bottom'
        },

//Events
        {
          element  : '#events-menu',
          title    : '_{GUIDE_EVENTS_MENU}_',
          content  : '_{GUIDE_EVENTS_MENU_TEXT}_',
          backdrop : true,
          animation: false,
          placement: 'bottom',
          onShown  : function () {
            AMessageChecker.processData(
                {
                  TYPE    : 'EVENT',
                  TITLE   : 'TEST',
                  TEXT    : '_{EVENT}_',
                  EXTRA   : '$SELF_URL',
                  MODULE  : "WEB",
                  GROUP_ID: '1',
                  ID      : '2586'
                }, 1
            );
          }
        },

// Quick search
        {
          element  : 'li.search_form',
          title    : '_{GUIDE_QUICK_SEARCH}_',
          content  : '_{GUIDE_QUICK_SEARCH_TEXT}_',
          backdrop : true,
          animation: false,
          placement: 'auto'
        },

//Documentation
        {
          element  : 'li#wiki-link',
          title    : '_{GUIDE_WIKI_LINK}_',
          content  : '_{GUIDE_WIKI_LINK_TEXT}_',
          backdrop : true,
          animation: false,
          placement: 'bottom'
        },

//Control-sidebar
        {
          element  : '#control-sidebar-open-btn',
          title    : '_{GUIDE_RIGHT_MENU}_',
          content  : '_{GUIDE_RIGHT_MENU_TEXT}_',
          backdrop : true,
          placement: 'left',
          onShown   : function () {
            // jQuery('#control-sidebar-open-btn').on('click', tour.next.bind(tour));
            jQuery('#right_menu_btn').click();
            console.log(jQuery('#control-sidebar-open-btn'));
          }
        },

// Quick menu
        {
          element  : '#admin-quick-menu',
          title    : '_{GUIDE_QUICK_MENU}_',
          content  : '_{GUIDE_QUICK_MENU_TEXT}_',
          backdrop : true,
          placement: 'left',
          onShown   : function () {
            if (!jQuery('body').hasClass('control-sidebar-open')) {
              window['\$'].AdminLTE.controlSidebar.open();
            }
          }
        },

// Interface settings btn
        {
          element  : '#admin_setting_btn',
          title    : '_{GUIDE_INTERFACE_SETTINGS_BTN}_',
          content  : '_{GUIDE_INTERFACE_SETTINGS_BTN_TEXT}_',
          backdrop : true,
          placement: 'left',
          onShown   : function () {
            if (!jQuery('body').hasClass('control-sidebar-open')) {
              window['\$'].AdminLTE.controlSidebar.open();
            }
            jQuery('a#admin_setting_btn').on('click', tour.next.bind(tour));
          }
        },

// Interface settings
        {
          element  : '#admin_setting',
          title    : '_{GUIDE_INTERFACE_SETTINGS_MENU}_',
          content  : '_{GUIDE_INTERFACE_SETTINGS_MENU_TEXT}_',
          backdrop : true,
          placement: 'left',
          onShown   : function () {
            if (!jQuery('body').hasClass('control-sidebar-open')) {
              window['\$'].AdminLTE.controlSidebar.open();
            }
            var openBtn = jQuery('a#admin_setting_btn');
            if (!openBtn.parent('li').hasClass('active')) {
              clickButton('admin_setting_btn');
            }
          }
        },
// Back to start page. finish
        {
          title    : '_{GUIDE_WELCOME}_',
          content  : "_{GUIDE_FINISH_TEXT}_",
          orphan : true,
          backdrop : true
        }
      ],
      onEnd : function () {
        jQuery.post("/admin/index.cgi", { tour_ended : 1 });
      }
    });

    // Start the tour
    tour.start();
  });
</script>
