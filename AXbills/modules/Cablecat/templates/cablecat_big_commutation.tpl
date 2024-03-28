<link rel='stylesheet' href='/styles/default/css/modules/cablecat/raphael.context-menu.css'>
<link rel='stylesheet' href='/styles/default/css/modules/cablecat/commutation.css'>
<link rel='stylesheet' href='/styles/default/css/modules/cablecat/jquery.contextMenu.min.css'>
<link rel='stylesheet' type='text/css' href='/styles/default/fonts/google-static/Roboto.css'>

<div class='row'>
  <div class='col-md-12'>
    <div id='canvas_container' class='table-responsive'>
      <div id='drawCanvas' style='height: 80vh; background-color: ghostwhite'></div>
    </div>
  </div>
</div>


<script>

    let selfUrl = '$SELF_URL';

    try {
        document['LANG'] = {
            'CABLE'                : '_{CABLE}_',
            'CONNECTER'            : '_{CONNECTER}_',
            'LINK'                 : '_{LINK}_',
            'CONNECT'              : '_{CONNECT}_',
            'CLEAR'                : '_{CLEAR}_',
            'CONNECT BY NUMBER'    : '_{CONNECT_BY_NUMBER}_',
            'DELETE LINK'          : '_{DELETE_LINK}_',
            'DELETE CONNECTION'    : '_{DELETE_CONNECTION}_',
            'ATTENUATION'          : '_{ATTENUATION}_',
            'COMMENTS'             : '_{COMMENTS}_',
            'REMOVE %S FROM SCHEME': '_{REMOVE_FS_FROM_SCHEME}_',
            'GO TO COMMUTATION'    : '_{GO_TO_COMMUTATION}_',
            'MAP'                  : '_{MAP}_',
            'CHANGE'               : '_{CHANGE}_',
            'SET'                  : '_{SET}_',
            'SPLITTER'             : '_{SPLITTER}_',
            'EQUIPMENT'            : '_{EQUIPMENT}_',
            'CROSS'                : '_{CROSS}_',
            'NAME'                 : '_{NAME}_',
            'IP'                   : 'IP',
            'LENGTH'               : '_{LENGTH}_',
            'NO OTHER COMMUTATIONS': '_{NO_OTHER_COMMUTATIONS}_',
            'OTHER COMMUTATIONS'   : '_{OTHER_COMMUTATIONS}_',
            'ADD SCHEME'           : '_{ADD_SCHEME}_',
            'REMOVE SCHEME'        : '_{REMOVE_SCHEME}_'
        }
    }
    catch (Error) {
        alert('Error happened while transfering data to page');
        console.log(Error);
    }

</script>

<!-- Drawing -->
<script src='/styles/default/js/raphael.min.js'></script>

<!-- Draggable -->
<script src='/styles/default/js/modules/cablecat/raphael.drag.set.js'></script>

<!-- Context Menu -->
<!--<script src='/styles/default/js/modules/cablecat/jquery.ui.position.min.js'></script>-->
<script src='/styles/default/js/modules/cablecat/jquery.contextMenu.min.js'></script>

<script src='/styles/default/js/modules/cablecat/big.commutation.js'></script>