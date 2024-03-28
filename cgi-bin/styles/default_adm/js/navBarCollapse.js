/**
 * Created by Anykey on 17.08.2015.
 */

var MENU_AUTO_HIDDEN_WIDTH = 992;
var cookieValue            = Cookies.get('menuHidden');
var menuHidden             = isDefined(cookieValue) && cookieValue === 'false';
var $body                  = $('body');
var MENU_TOGGLE_CLASS      = 'sidebar-collapse';
//console.log('menuhidden: ' + menuHidden);

/* Nav bar */
function toggleNavBar() {
  $body.toggleClass(MENU_TOGGLE_CLASS);
  Cookies.set('menuHidden', !menuHidden);
  menuHidden = !menuHidden;
}