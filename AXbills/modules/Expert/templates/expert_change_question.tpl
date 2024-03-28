<form action='$SELF_URL' method='post'>
    <input type='hidden' name='index' value='%INDEX%'>
    <input type='hidden' name='ID' value='%ID%'>
  
    <div class='card'>
        <div class='card-header'>_{CHANGE}_</div>
        <div class='card-body'>
            <b>_{QUESTION}_: </b><input class='form-control' type='text' name='QUESTION' value='%QUESTION%'>
            <b>_{DESCRIBE}_: </b><input class='form-control' type='text' name='DESCRIPTION' value='%DESCRIPTION%'>
        </div>
        <div class='card-footer'>
            <input class='btn btn-primary' type='submit' name='%BUTTON_NAME%' value='%BUTTON_VALUE%'>
        </div>
    </div>
</form>
