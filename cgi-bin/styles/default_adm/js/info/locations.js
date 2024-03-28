/**
 * Created by Anykey on 19.02.2016.
 *
 */

{
  var locations_obj_type = $('#OBJECT_TYPE').val();
  var locations_obj_id = $('#OBJECT_ID').val();

  var $addBtn = $('#locationsAdd');
  var $showBtn = $('#locationsShow');

  var locationsLoaded = false;

  $addBtn.on('click', function () {
    enableAddMod()
  });
  $showBtn.on('click', function () {
    loadLocations();
  });

  function enableAddMod() {

    $addBtn.removeClass('btn-primary');
    $addBtn.addClass('btn-danger');

    if (!locationsLoaded) {
      loadLocations(locations_obj_type, locations_obj_id);
    }

    Events.on('mapsClick', processMapClick);

    function processMapClick(context) {

      console.log(context);

      var coordx = context.latLng.lat();
      var coordy = context.latLng.lng();

      disableAddMod();

      var _COMMENT = window['_COMMENT'] || "Comment";

      var modalContent = "<div class='modal-body'><div class='row'><label class='control-label col-md-3'>"+_COMMENT+"</label>" + "<div class='col-md-9'><textarea id='addLocationComment' name='COMMENT' class='form-control'></textarea></div>" + "</div></div>";

      aModal.clear()
        .setBody(modalContent)
        .addButton(_ADD, "addLocationBtn", 'btn btn-primary')
        .show(function () {
          setTimeout(function(){
            $('#addLocationBtn').on('click', function(){

              var comment = $('#addLocationComment').val();
              aModal.destroy();

              console.log(comment);

              var params = {
                get_index : 'info_location_add',
                header : 2,

                OBJ_TYPE : locations_obj_type,
                OBJ_ID : locations_obj_id,

                COORDY : coordx,
                COORDX : coordy,

                COMMENT: comment
              };

              //console.log(params);

              var paramsString = $.param(params);
              console.log(paramsString);

              loadToModal(SELF_URL + '?' + paramsString);

              $addBtn.removeClass('btn-danger');
              $addBtn.addClass('btn-primary');
            });
          }, 500);
        })
    }

    function disableAddMod() {
      Events.off('mapsClick', processMapClick);
    }
  }


  function loadLocations(type, id) {

    type = type || locations_obj_type;
    id = id || locations_obj_id;

    //var $url = "get_index";

    $('#locationsMap').load(SELF_URL,
      {
        get_index: 'info_locations_show_map',
        header: 2,
        OBJ_TYPE: type,
        OBJ_ID: id
      },
      function () {
        locationsLoaded = true;
        $showBtn.remove();
      }
    );
  }

}

function removeLocation(id) {
  var link = "?get_index=info_location_del&header=2&OBJ_ID=" + id;

  console.log(link);

  $.getJSON(link, function (object) {
    if (object.status === 0) {
      new ATooltip(object.message).show();
    }
    else {
      new ATooltip(object.message).setClass('danger').show();
    }
  });
}
