<form action=$SELF_URL name='storage_filter_installation' method=POST>
  <input type=hidden name=index value=$index>
  <input type=hidden name=search value=1>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{SEARCH}_:</h4></div>
    <div class='card-body form form-horizontal'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='LOGIN'>_{USER}_:</label>
        <div class='col-md-8'>
          <input type=text name='LOGIN' class='form-control' value='%LOGIN%' id='LOGIN'/>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{NAS}_:</label>
        <div class='col-md-8'>%NAS_SEL%</div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{INSTALLED}_:</label>
        <div class='col-md-8'>%INSTALLED_AID%</div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{RESPOSIBLE}_ _{FOR_INSTALLATION}_:</label>
        <div class='col-md-8'>
          %INSTALLED_AID_SEL%
        </div>
      </div>
      <hr>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{TYPE}_:</label>
        <div class='col-md-8'>
          %ARTICLE_TYPES_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{NAME}_:</label>
        <div class='col-md-8'>
          <div class='ARTICLES_S'>
            %ARTICLE_ID_SELECT%
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ARTICLE_SEARCH_id'>_{ARTICLE}_:</label>
        <div class='col-md-8'>
          <select name='STORAGE_ARTICLE_ID' id='ARTICLE_SEARCH_id' class='form-control normal-width'>
            <option value='' %SEARCH_STORAGE_ARTICLE_EMPTY_STATE%>_{LIVE_SEARCH}_</option>
            <option value='%SEARCH_STORAGE_ARTICLE_ID%' %SEARCH_STORAGE_ARTICLE_STATE%>%SEARCH_STORAGE_ARTICLE_NAME%
            </option>
          </select>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ARTICLE_SEARCH_id'>SN:</label>
        <div class='col-md-8'>
          <input class='form-control' type='text' name='SERIAL' value='%SERIAL%'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{STATUS}_:</label>
        <div class='col-md-8'>
          %STATUS%
        </div>
      </div>
      <hr>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{DATE}_:</label>
        <div class='col-md-8'>
          <div class='input-group'>
            <div class='input-group-prepend'>
              <span class='input-group-text'>
                <input type='checkbox' class='form-control-static' data-input-enables='DATE'/>
              </span>
            </div>
            %DATE_SELECT%
          </div>
        </div>
      </div>
      <hr>
      %ADDRESS_FORM%
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type=submit name=show_installation value='_{SHOW}_'>
    </div>
  </div>
</form>

<script src='/styles/default/js/storage.js'></script>
<script>
  jQuery(document).ready(function () {

    jQuery('select#ARTICLE_SEARCH_id').select2({
      ajax: {
        url: '/admin/index.cgi',
        dataType: 'json',
        type: 'POST',
        quietMillis: 50,
        data: function (term) {
          return {
            quick_search: term.term,
            qindex: '$index',
            header: 2,
            show_installation: 1,
            search_type: 1
          }
        },
        processResults: function (data) {
          var results = [];
          console.log(data);

          if (data) {
            jQuery.each(data, function (i, val) {
              results.push({
                id: val.id,
                text: val.type_name + ' : ' + val.name
              });
            });
          }

          return {results: results};
        }
      }
    });
  });
</script>