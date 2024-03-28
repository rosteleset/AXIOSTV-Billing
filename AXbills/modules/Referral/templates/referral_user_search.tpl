<form name='REFERRAL_USER_SEARCH' id='form-search' method='post' class='form form-horizontal'>
    <input type='hidden' name='action' value='action'/>
    <input type='hidden' name='USER_ID' value='%REFERRAL_UID%'/>

    <div class='form-group'>
        <label class='control-label col-md-3' for='LOGIN_id'>_{LOGIN}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' name='LOGIN' id='LOGIN_id'/>
        </div>
    </div>

    <div class='form-group'>
        <label class='control-label col-md-3' for='FIO_id'>_{FIO}_</label>
        <div class='col-md-9'>
            <input type='text' class='form-control' name='FIO' id='FIO_id'/>
        </div>
    </div>
</form>

<script>
    function defineSearchResultLogic() {
        var searchResult = jQuery('.search-result');

        searchResult.on('click', function () {
            aModal.hide();

            var link = jQuery(this).attr('data-link');
            loadToModal(link, function () {
                setTimeout(function(){
                    aModal.hide();
                }, 3000);
            });

        });
    }

    setupSearchForm('USER_ID')
</script>
