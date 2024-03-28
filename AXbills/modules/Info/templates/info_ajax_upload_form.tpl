<a role='button' data-toggle='modal' class='btn btn-secondary btn-xs btn-primary' data-target='#info_ajax_upload_modal'>
    <span class='fa fa-plus'></span>
</a>

<div class='modal fade' id='info_ajax_upload_modal' tabindex='-1' role='dialog'>
    <div class='modal-dialog'>
        <div class='modal-content'>
            <div class='modal-header'>
                <button type='button' class='close' data-dismiss='modal' aria-label='Close'><span
                        aria-hidden='true'>&times;</span></button>
                <h4 class='modal-title'>_{ADD}_</h4>
            </div>
            <div class='modal-body' id='info_ajax_upload_modal_body'>
                <div class='row'>
                    <form class='form form-horizontal' name='form_ajax_upload' id='form_ajax_upload' method='post'>

                        <input type='hidden' name='OBJ_TYPE' value='%TABLE_NAME%'/>
                        <input type='hidden' name='OBJ_ID' value='%OBJECT_ID%'/>
                        <input type='hidden' name='get_index' value='%CALLBACK_FUNC%'/>
                        <input type='hidden' name='header' value='2'/>

                        <div class='form-group'>
                            <label class='control-label col-md-3' for='UPLOAD_FILE'>_{FILE}_</label>

                            <div class='col-md-9'>
                                <input type='file' name='UPLOAD_FILE' id='UPLOAD_FILE' required/>
                            </div>
                        </div>

                        <div class='form-group'>
                            <div class='col-sm-12'>
                                <div class='checkbox'>
                                    <label class='control-label'>
                                        <input type='checkbox' name='WRITE_TO_DB'> _{WRITE_TO_DB}_ ?
                                    </label>
                                </div>
                            </div>
                        </div>


                    </form>
                </div>
            </div>
            <div class='modal-footer'>
                <button type='button' class='btn btn-secondary' data-dismiss='modal'>_{CANCEL}_</button>
                <button type='submit' class='btn btn-primary' id='go' form='form_ajax_upload'>_{ADD}_</button>
            </div>
        </div> <!-- /.modal-content -->
    </div> <!-- /.modal-dialog -->
</div><!-- /.modal -->

