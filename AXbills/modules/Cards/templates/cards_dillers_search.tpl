<form action='$SELF_URL' method='POST' class='form-horizontal no-live-select UNIVERSAL_SEARCH_FORM'
      id='SMALL_SEARCH_FORM'>
    <input type='hidden' name='index' value="%INDEX%">
    <input type='hidden' name='sid' value="%SID%">
    <input type='hidden' name='search_form' value="1">
    <div class="form-group">
        <div class='card card-primary card-outline box-form'>
            <div class='card-header with-border'>
                <h3 class="card-title">_{SEARCH}_</h3>
                <div class="card-tools float-right">
                    <button type="button" class="btn btn-box-tool" data-card-widget="collapse"><i
                            class="fa fa-minus"></i>
                    </button>
                </div>
            </div>
            <div class='card-body'>
                <div class='form-group'>
                    <label class='control-label col-sm-3 col-md-4'>_{SEARCH_PHRASE}_:</label>
                    <div class='col-sm-9 col-md-8'>
                        <input type='text' name='UNIVERSAL_SEARCH' class='form-control UNIVERSAL_SEARCH'
                               placeholder='_{SEARCH_PHRASE}_...' form='SMALL_SEARCH_FORM'>

                    </div>
                </div>
                <input class='btn btn-primary col-md-12 col-sm-12' type='submit'
                       value='_{SEARCH}_'>
            </div>
        </div>
    </div>
</form>