<div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{TRAFFIC_CLASS}_</h4></div>
    <div class='card-body'>

        <form name='TRAFFIC_CLASS_FORM' id='form_TRAFFIC_CLASS_FORM' action='$SELF_URL' method='post' class='form form-horizontal'>
            <input type='hidden' name='index' value='$index' />
            <input type='hidden' name='ID' value='$FORM{chg}'>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='NAME_id'>_{NAME}_</label>
                <div class='col-md-9'>
                    <input type='text' class='form-control'  required name='NAME'  value='%NAME%'  id='NAME_id'  />
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3' for='COMMENTS_id'>_{COMMENTS}_</label>
                <div class='col-md-9'>
                    <textarea class='form-control'  rows='3'  name='COMMENTS'  id='COMMENTS_id' >%COMMENTS%</textarea>
                </div>
            </div>

            <div class='form-group'>
                <label class='col-md-12 text-left required' for='NETS_id'>NETS (192.168.101.0/24;10.0.0.0/28)</label>
                <div class='col-md-3'></div>
                <div class='col-md-9'>
                    <textarea class='form-control'  rows='5'  name='NETS'  id='NETS_id' required>%NETS%</textarea>
                </div>
            </div>
        </form>

    </div>
    <div class='card-footer'>
        <input type='submit' form='form_TRAFFIC_CLASS_FORM' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
</div>

