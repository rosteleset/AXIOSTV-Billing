<script>
  var index     = '$index';
  var map_index = '%MAP_INDEX%';
  var map_edit_index = '%MAP_EDIT_INDEX%';

  var GOOGLE_API_KEY  = '%GOOGLE_API_KEY%';
  var YANDEX_API_KEY  = '%YANDEX_API_KEY%';
  var VISICOM_API_KEY  = '%VISICOM_API_KEY%';

  var MAPS_DEFAULT_TYPE  = '%MAPS_DEFAULT_TYPE%';
  var MAPS_DEFAULT_LATLNG  = '%MAPS_DEFAULT_LATLNG%';
  var MAP_HEIGHT  = '%MAP_HEIGHT%' || 85;

  var MAPS_WATERMARK_URL  = '%MAPS_WATERMARK_URL%' || '';
  var MAPS_WATERMARK_ICON  = '%MAPS_WATERMARK_ICON%' || '';

  var CLIENT_MAP = '%CLIENT_MAP%';

  var _NAVIGATION_WARNING        = '_{NAVIGATION_WARNING}_' || 'You have disabled retrieving your location in browser';

  var _CLICK_ON_A_MARKER_YOU_WANT_TO_DELETE = '_{CLICK_ON_A_MARKER_YOU_WANT_TO_DELETE}_' || 'Click on a marker you want delete';

  var _YES        = '_{YES}_';
  var _NO         = '_{NO}_';
  var _CANCEL     = '_{CANCEL}_';
  var _USER       = '_{USER}_';
  var _BUILD      = '_{BUILD}_';
  var _BUILD2      = '_{BUILD}_ POLYGON';
  var _ROUTE      = '_{ROUTE}_' || 'Route';
  var _ROUTES     = '_{ROUTES}_' || 'Routes';
  var _WIFI       = '_{WIFI}_' || 'Wi-Fi';
  var _DISTRICT   = '_{DISTRICT}_' || 'District';
  var _OBJECT     = '_{OBJECT}_' || 'Object';
  var _ADD        = '_{ADD}_' || 'Add';
  var _NEW        = '_{NEW}_' || 'New';
  var _POINT      = '_{POINT}_' || 'Point';
  var _BUILDS     = '_{BUILDS}_' || 'Builds';
  var _SEARCH     = '_{SEARCH}_' || 'Search';
  var _BY_QUERY   = '_{BY_QUERY}_' || 'By Query';
  var _QUERY      = '_{QUERY}_' || 'Query';
  var _BY_TYPE    = '_{BY_TYPE}_' || 'By Types';
  var _TOGGLE     = '_{TOGGLE}_' || 'Toggle';
  var _POLYGONS   = '_{POLYGONS}_' || 'Polygons';
  var _MARKER     = '_{MARKER}_' || 'Marker';
  var _CLUSTERS   = '_{CLUSTERS}_' || 'Clusters';
  var _REMOVE     = '_{REMOVE}_' || 'Remove';
  var _LOCATION   = '_{LOCATION}_' || 'Location';
  var _DROP       = '_{DROP}_' || 'Drop';
  var _MAKE_ROUTE = '_{MAKE_ROUTE}_' || 'Make Navigation Route';
  var _DISTANCE   = '_{DISTANCE}_' || 'Distance';
  var _DURATION   = '_{DURATION}_' || 'Duration';
  var _END        = '_{END}_' || 'End';
  var _START      = '_{START}_' || 'Start';
  var _FROM       = '_{FROM}_' || 'From';
  var _TO         = '_{TO}_' || 'To';
  var _PERIOD     = '_{PERIOD}_' || 'Period';
  var _SHOW       = '_{SHOW}_' || 'Show';
  var _NO_MOVES_FOUND = '_{NO_MOVES_FOUND}_' || 'No moves found during this period';
  var _DELETE_ITEM_FROM_MAP = '_{DELETE_ITEM_FROM_MAP}_' || 'Delete item from map?';
  var _CHOOSE_ADDRESS = '_{CHOOSE_ADDRESS}_' || 'Choose address';
  var _SAVE = '_{SAVE}_' || 'Save';
  var _CHANGE = '_{CHANGE}_' || 'Change';
  var _ERROR = '_{ERROR}_' || 'Error';
  var _COMPLETE_PREVIOUS_CHANGE = '_{COMPLETE_PREVIOUS_CHANGE}_' || 'Complete previous changes';
  var _DOWNLOAD = '_{DOWNLOAD}_' || 'Download';
  var _SCALE = '_{MAPS_SCALE}_' || 'Scale';
  var _DELETE      = '_{DELETE}_' || 'Delete';
  var _COMMUTATION      = '_{COMMUTATION}_' || 'Commutation';
  var _PREVIOUS = '_{PREVIOUS}_' || 'Prev';
  var _NEXT = '_{NEXT_NEXT}_' || 'Next';

  //ENABLING FEATURES
  var SHOW_MARKERS              = '%SHOW_MARKERS%' || true;
  var CLUSTERING_ENABLED        = '%CLUSTERING_ENABLED%' || true;
  var DISTRICT_POLYGONS_ENABLED = '%DISTRICT_POLYGONS_ENABLED%' || false;

  //CONTROL BLOCK
  var layersCtrlEnabled     = true;
  var searchCtrlEnabled     = true;
  var navigationCtrlEnabled = '%NAVIGATION_BTN%' || false;

  //INPUT PARAMS
  var mapCenter    = '%MAPSETCENTER%';
  var CONF_MAPVIEW = '%MAP_VIEW%' || '';

  var form_query_search  = '%search_query%';
  var form_type_search   = '%search_type%';

  var form_nav_x = '%nav_x%';
  var form_nav_y = '%nav_y%';
  var form_quick = '%QUICK%';

  //Constants
  var BUILD        = 'BUILD';
  var BUILD2       = 'BUILD2';
  var ROUTE        = 'ROUTE';
  var DISTRICT     = 'DISTRICT';
  var WIFI         = 'WIFI';
  var WELL         = 'WELL';
  var NAS          = 'NAS';
  var TRAFFIC      = 'TRAFFIC';
  var CUSTOM_POINT = 'CUSTOM_POINT';
  var EQUIPMENT    = 'EQUIPMENT';

  var POINT            = 'POINT';
  var LINE             = 'LINE';
  var POLYGON          = 'POLYGON';
  var CIRCLE           = 'CIRCLE';
  var POLYLINE_MARKERS = 'POLYLINE_MARKERS';
  var MARKER_CIRCLE    = 'MARKER_CIRCLE';
  var MULTIPLE         = 'MULTIPLE';

  var LAYERS           = JSON.parse('%LAYERS%');
  var LAYER_ID_BY_NAME = JSON.parse('%LAYER_ID_BY_NAME%');
  var FORM             = JSON.parse('%FORM%');
  var OPTIONS          = JSON.parse('%OPTIONS%');
</script>
