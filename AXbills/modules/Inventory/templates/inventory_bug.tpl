<form action='$SELF_URL' name='inventory_form' method=POST>
    <input type=hidden name=index value=$index>
    <input type=hidden name=ID value=$FORM{chg}>

    <div class='card card-danger card-outline'>
        <div class='card-header with-border'>
            <h3 class='card-title'>Bug #%ID%</h3>
        </div>
        <div class='card-body'>
            <div class='form-group row'>
                <div class='col-md-4 bg-success'>_{CUR_VERSION}_: <b>%CUR_VERSION%</b></div>
                <div class='col-md-4 bg-success'>_{DATE}_: <b>%DATETIME%</b></div>
                <div class='col-md-4 bg-success'>IP: <b>%IP%</b></div>
            </div>

            <div class='form-group row'>
                <div class='col-md-4'>_{NUMBER}_: <b>%FN_INDEX%</b></div>
                <div class='col-md-4'>_{FUNCTION}_: <b>%FN_NAME%</b></div>
                <div class='col-md-4'>_{CHECKSUM}_: %CHECKSUM%</div>
            </div>

            <div class='form-group row'>
                <label class='col-md-12 bg-danger'>Error:</label>
                <div class='col-md-6'>
                    <code class='form-control' style='height: auto;'>%ERROR%</code>
                </div>
                <div class='col-md-6'>
                    <pre class='form-control' style='height: auto;'>%INPUTS%</pre>
                </div>
            </div>

            <div class='form-group row'>
                <div class='col-md-10'>
                  <label class='bg-info container-fluid' for='COMMENTS'>Comments</label>
                  <textarea cols='60' rows='5' ID='COMMENTS' id='COMMENTS' class='form-control'>%COMMENTS%</textarea>
                </div>

                <div class='form-group col-md-2'>
                  <label for='FIX_VERSION'>_{FIX_VERSION}_</label>
                  <div>
                    <input type='text' class='form-control' name='FIX_VERSION' id='FIX_VERSION' value='%FIX_VERSION%'>
                  </div>
                  <label>_{STATUS}_</label>
                  <div>%STATUS_SEL%</div>
                  <label>_{RESPONSIBLE}_</label>
                  <div>%RESPONSIBLE_SEL%</div>
                </div>
             </div>
        </div>



        <div class='card-footer'>
            <input type=submit name=change value='_{CHANGE}_' class='btn btn-primary'>
        </div>
    </div>

</form>
