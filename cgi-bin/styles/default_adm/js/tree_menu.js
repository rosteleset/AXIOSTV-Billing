jQuery('.tree-toggler').on('click', function() {
    jQuery(this).siblings('ul.nav.tree').slideToggle();
});

// if not work return to old code;
// /**
//  * Created by Anykey on 10.03.2017.
//  */
// jQuery(function () {
//     //expand first level
//   jQuery('ul.nav.main.well').find('ul.tree').first().show();
  
//   //expand next level on click
//   jQuery('label.tree-toggler').on('click', function (e) {
//     cancelEvent(e);
//     toggleBranch(this)
//   });
  
//   function toggleBranch(context) {
//     var _this = jQuery(context);
//     var visible = _this.prop('visible');
//     visible
//         ? _this.next('ul.nav.tree').hide(100)
//         : _this.next('ul.nav.tree').show(100);
  
//     _this.prop('visible', !visible);
//   }
  
// });
