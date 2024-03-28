<form name='STORAGE_USER_SEARCH' id='form-search' method='post' class='form form-horizontal'>
  <input type='hidden' name='qindex' value='$index'/>
  <input type='hidden' name='install_accountability' value='1'/>
  <input type='hidden' name='user_search_form' value='2'/>
  <input type='hidden' name='LOGIN' id='LOGIN_id'/>

  <div class='form-group'>
    <label class='control-label col-md-2' for='LOGIN_SEARCH_id'>_{LOGIN}_</label>
    <div class='col-md-9'>
      <select name='LOGIN_SEARCH' id='LOGIN_SEARCH_id' class='form-control normal-width'>
        <option>_{SEARCH}_...</option>
      </select>
    </div>
  </div>

  <div class='form-group'>
    <label class='control-label col-md-2' for='FIO_id'>_{FIO}_</label>
    <div class='col-md-9'>
      <input type='text' class='form-control' name='FIO' id='FIO_id'/>
    </div>
  </div>

  %ADDRESS_FORM%

</form>

<script>

  jQuery.getScript('/styles/default/js/ajax-chosen.jquery.min.js', function(){
    jQuery('select#LOGIN_SEARCH_id').ajaxChosen({
      jsonTermKey : 'LOGIN',
      type: 'GET',
      url: '/admin/index.cgi',
      dataType: 'json',
      data : {
        qindex        : 7,
        header        : 1,
        search        : 1,
        type          : 10,
        json          : 1,
        SKIP_FULL_INFO: 1,
        EXPORT_CONTENT: 'USERS_LIST'
      }
    },
        function (data) {
          var results = [];

          if (data['DATA_1']){
            jQuery.each(data['DATA_1'], function (i, val) {
              results.push({
                value: val.login,
                text: val.login
                        + ( val.fio ? ' ' + val.fio : '')
                        + ( val.address_full ? ' (' + val.address_full + ') ' : '')
              });
            });
          }

          return results;
        });
  });

  function storage_setup_search_form() {

    var search_form = jQuery('form#form-search');

    var hidden_login = search_form.find('input#LOGIN_id');
    search_form.find('select#LOGIN_SEARCH_id').on('change', function () {
      hidden_login.val(jQuery(this).val());
    });


    // Set up inner window logic
    var search_button = jQuery('button#search');
    var have_results   = jQuery('.clickSearchResult').length > 0;

    if (search_button.length) {
      search_button.on('click', function () {
        getDataURL(formURL, function () {
          defineSearchResultLogic()
        });
      });
    }

    if (have_results) {
      defineSearchResultLogic()
    }

    if (typeof (should_open_results_tab) !== 'undefined' && should_open_results_tab === '1') {
      enableResultPill();
    }
    console.log('setuop');
  }


  function defineSearchResultLogic() {
    var searchResult = jQuery('.search-result');

    var hiddenInput = jQuery('#UID_HIDDEN');
    var loginInput  = jQuery('#USER_LOGIN');

    searchResult.on('click', function () {
      aModal.hide();

      var login = jQuery(this).text();
      var uid   = jQuery(this).attr('data-uid');

      hiddenInput.val(uid);
      loginInput.val(login);

      aModal.destroy();
    });
  }

  jQuery(function () {
    pageInit(jQuery('form#form-search'));
    storage_setup_search_form();
  })
</script>
