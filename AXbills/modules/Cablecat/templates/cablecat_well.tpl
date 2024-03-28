<style>
	.progress {
		width: 100px;
		height: 20px;
		position: relative;
		background: #e6e6e6;
		border: 1px solid #bcbcbc;
    padding: 2px;
	}

	.progress .progress-inner {
		width: 0;
		height: 100%;
		background-color: #6787e3;
		display: inline-block;
		position: relative;
		-webkit-animation-duration: 1.25s;
		animation-duration: 1.25s;
		-webkit-animation-fill-mode: forwards;
		animation-fill-mode: forwards;
		-webkit-transition: width .6s ease;
		transition: width .6s ease;
	}

	#progress-container {
		background-color: #f5f5f5;
  }

  .dark-mode #progress-container {
		background: rgba(0,0,0,.1);
  }
</style>

<div class='row'>
  <div class='%MAIN_FORM_SIZE%'>
    <div class='card card-primary card-outline'>
      <div class='card-header with-border'><h4 class='card-title'>_{WELL}_</h4></div>
      <div class='card-body'>
        <form name='CABLECAT_WELLS' id='form_CABLECAT_WELLS' method='post' class='form form-horizontal'>
          <input type='hidden' name='index' value='$index'/>
          <input type='hidden' name='ID' value='%ID%'/>
          <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
          <input type='hidden' name='PICTURE' id='PICTURE' value='%PICTURE%'/>
          %EXTRA_INPUTS%

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right required' for='NAME_ID'>_{NAME}_:</label>

            <div class='col-md-8'>
              <input type='text' class='form-control' value='%NAME%' required name='NAME' id='NAME_ID'/>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right required' for='TYPE_ID_SELECT'>_{TYPE}_:</label>
            <div class='col-md-8'>
              %TYPE_ID_SELECT%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='INSTALLED_ID'>_{INSTALLED}_:</label>
            <div class='col-md-8'>
              <input type='text' class='form-control datepicker' value='%INSTALLED%' name='INSTALLED'
                     id='INSTALLED_ID'/>
            </div>
          </div>

          <div class='form-group row should-be-hidden'>
            <label class='col-md-4 col-form-label text-md-right' for='POINT_ID'>_{OBJECT}_:</label>
            <div class='col-md-8'>
              %POINT_ID_SELECT%
            </div>
          </div>

          <div class='form-group row should-be-hidden' data-visible='%ADD_OBJECT_VISIBLE%'>
            <label class='col-md-4 col-form-label text-md-right' for='ADD_OBJECT'>_{CREATE}_ _{OBJECT}_:</label>
            <div class='col-md-8'>
              <div class='form-check'>
                <!-- Here 1 is WELL map type_id -->
                <input type='checkbox' class='form-check-input' id='ADD_OBJECT' name='ADD_OBJECT'
                       %ADD_OBJECT% value='1' data-input-disables='POINT_ID'>
              </div>
            </div>
          </div>

          <hr/>

          %INSTALLATIONS_TABLE%

          <div class='%HIDE_STORAGE_FORM%'>
            <div class='form-group row'>
              <label class='col-md-4 control-label'>_{STORAGE}_: </label>
              <div class='col-md-8'>%STORAGE_STORAGES%
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-4 control-label'>_{TYPE}_:</label>
              <div class='col-md-8'>%ARTICLE_TYPES%</div>
            </div>
            <div class='form-group row'>
              <label class='col-md-4 control-label'>_{NAME}_:</label>

              <div class='col-md-8'>
                <div id='ARTICLES_S'>
                  %ARTICLE_ID%
                </div>
              </div>
            </div>
            <div class='form-group row'>
              <label class='col-md-4 control-label'>_{COUNT}_:</label>
              <div class='col-md-8'>
                <input class='form-control' name='COUNT' type='text'/>
              </div>
            </div>

          </div>

          <hr/>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='PARENT_ID'>_{INSIDE}_:</label>
            <div class='col-md-8'>
              %PARENT_ID_SELECT%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
            <div class='col-md-8'>
              <textarea class='form-control' rows='5' id='COMMENTS' name='COMMENTS'>%COMMENTS%</textarea>
            </div>
          </div>
        </form>

        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right' for='PICTURE'>_{PICTURE}_:</label>
          <div class='col-md-8' id='upload-container'>
            <form id='upload_form' enctype='multipart/form-data' method='post'>
              <input type='file' name='picture_upload' id='picture_upload' onchange='uploadFile()' accept='image/*'>
            </form>
          </div>
          <div class='col-md-8 d-none' id='progress-container'>
            <label class='progress-label mt-2'>Test</label>
            <div class='float-right d-flex'>
              <div class='progress mt-2'>
                <div id='progress-bar' class='progress-inner'></div>
              </div>
              <button type='button' class='close remove-file mt-2 ml-2'>×</button>
            </div>
            <br>
          </div>
        </div>

      </div>
      <div class='card-footer'>
        <input type='submit' form='form_CABLECAT_WELLS' class='btn btn-primary' name='submit'
               value='%SUBMIT_BTN_NAME%'>
      </div>
    </div>
  </div>

  <div class='col-md-6'>
    <div class='card card-primary card-outline' style='display: none' data-visible='%HAS_LINKED%'>
      <div class='card-header with-border'><h4 class='card-title'>_{LINKED}_ _{CABLES}_ -> _{WELLS}_</h4></div>
      <div class='card-body text-left'>
        %LINKED%
      </div>
    </div>
  </div>

  <div class='col-md-6'>
    <div class='card card-primary card-outline' style='display: none' data-visible='%CONNECTERS_VISIBLE%' id='CONNECTERS_BOX'>
      <div class='card-header with-border'><h4 class='card-title'>_{CONNECTERS}_</h4></div>
      <div class='card-body'>
        %CONNECTERS%
      </div>
    </div>
  </div>
</div>

<script>
  let progress_container = jQuery('#progress-container');
  let progress_label = progress_container.find('.progress-label');
  let progress_bar = progress_container.find('.progress');
  let file_name;

  if (jQuery('#PICTURE').val()) {
    jQuery('#upload-container').addClass('d-none');
    progress_container.removeClass('d-none');
    progress_label.text(jQuery('#PICTURE').val());
    progress_bar.addClass('d-none');
    progress_container.append(jQuery('<img class="mb-2 mr-2 well-picture"\>').css('max-width', '100%')
      .attr('src', `/images/cablecat/${jQuery('#PICTURE').val()}`))
  }
  
  jQuery('.remove-file').on('click', function() {
    jQuery('#progress-bar').css('width', 0);
    jQuery('#upload-container').removeClass('d-none');
    jQuery('#picture_upload').val('');
    progress_bar.removeClass('d-none');
    progress_container.addClass('d-none');
    progress_label.text('');
    jQuery('#PICTURE').val('');
    jQuery('.well-picture').remove();
  });

  function uploadFile() {
    let file = document.getElementById('picture_upload').files[0];
    let form_data = new FormData();
    file_name = file.name;
    form_data.append('picture_upload', file);
    let ajax = new XMLHttpRequest();
    ajax.upload.addEventListener('progress', progressHandler, false);
    ajax.addEventListener('load', completeHandler, false);
    ajax.addEventListener('error', errorHandler, false);

    jQuery('#upload-container').addClass('d-none');
    progress_container.removeClass('d-none');
    progress_label.text(file_name);

    ajax.onreadystatechange = () => {
      if (ajax.readyState !== 4) return;

      let data = [];
      try {
        data = JSON.parse(ajax.response);
      }
      catch (e) {
        console.log(e);
        return;
      }

      jQuery('#PICTURE').val(data.files.pop() || '');
    }

    ajax.open('POST', '/api.cgi/cablecat/attachment/');
    ajax.send(form_data);
  }

  function progressHandler(event) {
    let percent = (event.loaded / event.total) * 100;
    jQuery('#progress-bar').css('width', Math.round(percent) + "%");
    progress_label.html(file_name + ` <span class='text-muted text-small'>(` + formatBytes(event.loaded) + `)</span>`);
  }

  function completeHandler(event) {
    setTimeout(function (){
      progress_bar.addClass('d-none');
    }, 1000);
  }

  function errorHandler(event) {}
</script>

<script>
  function selectArticles() {
    let articleTypeId = jQuery('#ARTICLE_TYPE_ID').val();
    if (articleTypeId === null) return;

    let storageId = jQuery('#STORAGE_SELECT_ID').val();
    let searchFields = '&ARTICLE_TYPE_ID=' + articleTypeId;
    if (storageId) searchFields += '&STORAGE_ID=' + storageId;

    jQuery.post('/admin/index.cgi', 'header=2&get_index=storage_hardware&quick_info=1' + searchFields, function (result) {
      jQuery('#ARTICLES_S').empty();
      jQuery('#ARTICLES_S').html(result);
      initChosen();
    });
  }

  function selectStorage() {
    jQuery('#ARTICLE_TYPE_ID').change();
  }

  jQuery(function () {
    var form_id        = 'form_CABLECAT_CONNECTERS';
    var connecters_box = jQuery('div#CONNECTERS_BOX');

    if (connecters_box.length) {
      // Add connecter form opened on modal
      var add_btn = jQuery('#add_connecter');
      modify_add_connecter_btn();

      function modify_add_connecter_btn() {
        if (!add_btn.length) return false;

        add_btn.on('click', function (event) {
          cancelEvent(event);

          var href = add_btn.attr('href');
          href     = href.replace(/\?index=/, '\?qindex=');
          href += '&header=2&TEMPLATE_ONLY=1';

          Events.once('modal_loaded', setup_modal_connecter_add_form);
          loadToModal(href);
        });

        add_btn.addClass('btn btn-secondary');
      }

      function setup_modal_connecter_add_form(modal) {

        var form = modal.find('form#' + form_id);

        // If wrong form was loaded, do nothing
        if (!form.length) return false;

        var holder = modal.find('#CONNECTER_FORM_CONTAINER_DIV');

        // Make form wider
        holder.attr('class', 'col-md-12');

        // Make form submitted via POST
        form.off('submit');
        form.on('submit', ajaxFormSubmit);
      }

      function refreshConnectersView() {
        aModal.hide();

        console.log('card_refresh');
        setBoxRefreshingState(connecters_box, true);
        console.log(connecters_box, true);
        jQuery('#WELL_CONNECTERS_LIST').load(' #WELL_CONNECTERS_LIST', function () {
          setBoxRefreshingState(connecters_box, false);
        });
      }

      // Refresh list each time it has been changed
      Events.on('form_CABLECAT_CONNECTERS', refreshConnectersView);
      Events.on('AJAX_SUBMIT.' + form_id, refreshConnectersView);
    }

    // Auto max_prev_type name
    {
      // Select id
      var select_id     = 'TYPE_ID';
      var count_of_type = JSON.parse('%COUNT_FOR_TYPE%');

      var name_input  = jQuery('input#NAME_ID');
      var type_select = jQuery('select#' + select_id);
      type_select.on('change', function () {
        var name = type_select.find('option[value="' + this.value + '"]').text();
        name_input.val(name + '_' + (+count_of_type[this.value] + 1));
      });
    }
  });

</script>