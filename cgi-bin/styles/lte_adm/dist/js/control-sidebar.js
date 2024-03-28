(function ($, AdminLTE) {

  "use strict";

  /**
   * List of all the available skins
   *
   * @type Array
   */

  var my_skins = [
    "navbar-dark navbar-primary",
    "navbar-dark navbar-navy",
    "navbar-dark navbar-danger",
    "navbar-light navbar-warning",
    "navbar-light navbar-white",
    "navbar-dark navbar-indigo",
    "navbar-dark navbar-success",
    "navbar-dark navbar-teal",
    "navbar-light navbar-orange",
    "navbar-dark navbar-pink",
    "navbar-dark navbar-lightblue",
    "navbar-dark"
  ];


  setup();

  /**
   * Toggles layout classes
   *
   * @param cls the layout class to toggle
   * @returns void
   */
  function change_layout(cls) {
    $("body").toggleClass(cls);
  }

  /**
   * Replaces the old skin with the new skin
   * @param cls the new skin class
   * @param body_cls the new body skin class
   * @returns Boolean false to prevent link's default action
   */
  function change_skin(cls, body_cls) {
    $.each(my_skins, function (i) {
      $(".main-header").removeClass(my_skins[i]);
      $("body").removeClass('dark-mode');
    });

    $(".main-header").addClass(cls);
    if (body_cls) $("body").addClass(body_cls);
    return false;
  }

  /**
   * Retrieve default settings and apply them to the template
   *
   * @returns void
   */
  function setup() {
    //Add the change skin listener
    $("[data-skin]").on('click', function (e) {
      if ($(this).hasClass('knob')) return;
      e.preventDefault();
      $(this).addClass("hover");
      $('#skin').val($(this).data('skin'));
      $('#body_skin').val($(this).data('body-skin'));
      change_skin($(this).data('skin'), $(this).data('body-skin'));
    });

    //Add the layout manager
    $("[data-layout]").on('click', function () {
      change_layout($(this).data('layout'));
    });

    $("[data-controlsidebar]").on('click', function () {
      change_layout($(this).data('controlsidebar'));
      var slide = !AdminLTE.options.controlSidebarOptions.slide;
      AdminLTE.options.controlSidebarOptions.slide = slide;
      if (!slide)
        $('.control-sidebar').removeClass('control-sidebar-open');
    });

    $("[data-sidebarskin='toggle']").on('click', function () {
      var sidebar = $(".control-sidebar");
      if (sidebar.hasClass("control-sidebar-dark")) {
        sidebar.removeClass("control-sidebar-dark");
        sidebar.addClass("control-sidebar-light")
      } else {
        sidebar.removeClass("control-sidebar-light");
        sidebar.addClass("control-sidebar-dark")
      }
    });
    
    $("[data-header='fixed']").on('click', function () {
      var $nav =$("nav.navbar.navbar-static-top");
      $(this).prop('checked')
          ? $nav.addClass('navbar-fixed-top')
          : $nav.removeClass('navbar-fixed-top');
          
    });
    

    // Reset options
    if ($('body').hasClass('fixed')) {
      $("[data-layout='fixed']").attr('checked', 'checked');
    }


  }
})(jQuery, $.AdminLTE);
