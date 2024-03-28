<link rel='stylesheet' href='/styles/default/css/modules/cablecat/raphael.context-menu.css'>
<link rel='stylesheet' href='/styles/default/css/modules/cablecat/commutation.css'>
<link rel='stylesheet' href='/styles/default/css/modules/cablecat/jquery.contextMenu.min.css'>
<link rel='stylesheet' type='text/css' href='/styles/default/fonts/google-static/Roboto.css'>

%INFO_TABLE%

<div class='row'>
  <div class='col-md-12'>

    <div class='row text-left'>
      <div id='scheme_controls' class='card bg-light p-2 m-2 mt-0 w-100'>

        <div class='d-flex bd-highlight'>
          <div class='bd-highlight'>
            <div class='btn-group' role='toolbar'>

              <!-- ADD MENU -->
              <div class='btn-group'>
                <button type='button' class='btn btn-success dropdown-toggle' data-toggle='dropdown' aria-haspopup='true'
                        aria-expanded='false'>
                  <span>_{ADD}_</span>
                  <span class='caret'></span>
                </button>
                <ul class='dropdown-menu plus-options' aria-labelledby='dLabel'></ul>
              </div>

              <!-- SPECIAL OPERATIONS BUTTON -->
              <div class='btn-group'>
                <button type='button' role='button' class='btn btn-default dropdown-toggle' title='_{EXTRA}_'
                        data-toggle='dropdown' aria-haspopup='true' aria-expanded='false'>
                  <span>_{EXTRA}_</span>
                  <span class='caret'></span>
                </button>

                <ul class='dropdown-menu advanced-options' aria-labelledby='dLabel'></ul>

              </div>
              <div class='btn-group'>
                <button id='commutation_print' type='button' role='button' class='btn btn-default' title='_{PRINT}_'>
                  _{PRINT}_
                </button>
              </div>
              <div class='btn-group'>
                %BTN%
              </div>
              <div class='btn-group'>
                <button id='SPACE_SIZE_BTN' type='button' role='button' class='btn btn-default' title='_{SIZE}_'>
                  _{SIZE}_
                </button>
              </div>
              <div class='btn-group'>
                <button id='STRAIGHTEN_BTN' type='button' role='button' class='btn btn-default' title='_{STRAIGHTEN}_'>
                  _{STRAIGHTEN}_
                </button>
              </div>
            </div>
          </div>
          <div class='ml-auto bd-highlight'>
            <!-- ZOOM BUTTON GROUP -->
            <div class='btn-group float-right'>
              <button type='button' role='button' class='btn btn-default' title='ZOOM_IN' id='ZOOM_IN'>
                <span class='fa fa-search-minus'></span>
              </button>
              <button type='button' role='button' class='btn btn-default' title='ZOOM_NORMAL' id='ZOOM_NORMAL'>
                <span>100%</span>
              </button>
              <button type='button' role='button' class='btn btn-default' title='ZOOM_OUT' id='ZOOM_OUT'>
                <span class='fa fa-search-plus'></span>
              </button>

            </div>
          </div>
        </div>

      </div>
    </div>
  </div>

  <div class='col-md-12'>
    <div id='canvas_container' class='table-responsive'>
      <div id='drawCanvas' oncontextmenu='return false;'></div>
    </div>
  </div>
</div>


<script>

  try {
    document['COMMUTATION_ID'] = '%ID%';
    document['COMMUTATION_HEIGHT'] = '%HEIGHT%';
    document['CONNECTER_ID'] = '%CONNECTER_ID%';
    document['WELL_ID'] = '%WELL_ID%';

    document['CABLES'] = JSON.parse('%CABLES%');
    document['LINKS'] = JSON.parse('%LINKS%');
    document['SPLITTERS'] = JSON.parse('%SPLITTERS%');
    document['EQUIPMENT'] = JSON.parse('%EQUIPMENT%');
    document['CROSSES'] = JSON.parse('%CROSSES%');
    document['ONUS'] = JSON.parse('%ONUS%');

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
      'ONU'                  : 'ONU',
      'EQUIPMENT'            : '_{EQUIPMENT}_',
      'CROSS'                : '_{CROSS}_',
      'NAME'                 : '_{NAME}_',
      'IP'                   : 'IP',
      'LENGTH'               : '_{LENGTH}_',
      'NO OTHER COMMUTATIONS': '_{NO_OTHER_COMMUTATIONS}_',
      'OTHER COMMUTATIONS'   : '_{OTHER_COMMUTATIONS}_',
      'ROTATE'               : '_{ROTATE}_',
      'HEIGHT_CANNOT_BE_LESS': '_{HEIGHT_CANNOT_BE_LESS}_',
      'YES'                  : '_{YES}_',
      'NO'                   : '_{NO}_',
      'STRAIGHTEN'           : '_{STRAIGHTEN}_'
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
<script src='/styles/default/js/modules/cablecat/raphael.extensions.js'></script>
<script src='/styles/default/js/modules/cablecat/raphael.filters.js'></script>

<script src='/styles/default/js/modules/cablecat/commutation.drag.js'></script>

<!-- Context Menu -->
<script src='/styles/default/js/jquery-ui.min.js'></script>
<script src='/styles/default/js/modules/cablecat/jquery.contextMenu.min.js'></script>

<!-- Touch responsive -->
<script src='/styles/default/js/modules/cablecat/hammer.min.js'></script>

<!-- Zoom -->
<script src='/styles/default/js/modules/cablecat/raphael.pan-zoom.js'></script>

<script src='/styles/default/js/dynamicForms.js'></script>
<script src='/styles/default/js/modules/cablecat/commutation.js'></script>
<script id='maps_print' src='/styles/default/js/maps/html2canvas.min.js' async></script>

