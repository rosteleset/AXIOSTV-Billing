<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{ICONS}_</h4></div>
  <div class='card-body'>

    <form name='MAPS_ICONS' id='form_MAPS_ICONS' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>

      <div class='form-group'>
        <label class='control-label col-md-3' for='NAME_id'>_{NAME}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' name='NAME' value='%NAME%' id='NAME_id'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='FILEPATH'>_{FILE}_</label>
        <div class='col-md-9'>
          <div class="col-md-10">
            %FILENAME_SELECT%
          </div>
          <div class="col-md-2">
            %UPLOAD_BTN%
          </div>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
        <div class='col-md-9'>
          <textarea class='form-control' rows='5' name='COMMENTS' id='COMMENTS_id'>%COMMENTS%</textarea>
        </div>
      </div>
    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_MAPS_ICONS' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>
<style>
  #FILENAME, #FILENAME_chosen, #FILENAME_chosen > .chosen-single {
    min-height: 60px;
  }
  #UPLOAD_BUTTON {
    margin-top: 35%;
  }
</style>
<script>
  /** Anykey : pictures inside select **/

  var BASE_DIR = '%MAPS_ICONS_WEB_DIR%';

  var select = jQuery('#FILENAME');
  var options = select.find('option');

  jQuery.each(options, function (i, option) {
    var _opt = jQuery(option);

    var icon_name = _opt.text();

    var icon_src = BASE_DIR + icon_name;

    var img = document.createElement('img');
    img.src = icon_src;
    jQuery(img).addClass('img-fluid img-thumbnail');

    var strong = document.createElement('strong');
    jQuery(strong).addClass('text-left col-md-6');
    strong.innerText = icon_name;

    _opt.addClass('text-center');
    _opt.html(strong.outerHTML + img.outerHTML);
  });

  updateChosen();

</script>