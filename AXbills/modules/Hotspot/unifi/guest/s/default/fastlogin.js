/**
 * Created by Anykey on 29.12.2015.
 */
/**
 * Created by Anykey on 08.07.2015.
 */

var QueryString = function () {
    // This function is anonymous, is executed immediately and
    // the return value is assigned to QueryString!
    var query_string = {};
    var query = window.location.search.substring(1);
    var vars = query.split("&");
    for (var i=0;i<vars.length;i++) {
        var pair = vars[i].split("=");
        // If first entry with this name
        if (typeof query_string[pair[0]] === "undefined") {
            query_string[pair[0]] = pair[1];
            // If second entry with this name
        } else if (typeof query_string[pair[0]] === "string") {
            var arr = [ query_string[pair[0]], pair[1] ];
            query_string[pair[0]] = arr;
            // If third or later entry with this name
        } else {
            query_string[pair[0]].push(pair[1]);
        }
    }
    return query_string;
} ();

function doFastLogin() {

    var user_login = QueryString.username || '';
    var user_pass = QueryString.password || '';
    var fastLogin = 'false';

    try {
        fastLogin = QueryString.fastlogin;
    } catch ( e ) {
        console.log('not a fastlogin');
        /* do nothing */
    }


    if (fastLogin == 'true') {
        if (user_login && user_pass) {
            var $userField = $('#username');
            var $passField = $('#password');

            if ($userField && $passField){
                $userField.val(user_login);
                $passField.val(user_pass);
            }
            $('#login-submit').click();
        }
    }
}