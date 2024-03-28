<form action='%SELF_URL%' METHOD='post' enctype='multipart/form-data' name=add_district>
  <input type='hidden' name='index' value='%index%'/>
  <input type='hidden' name='ID' value='%ID%'/>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>_{DISTRICTS}_</div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input id='NAME' name='NAME' value='%NAME%' placeholder='%NAME%' class='form-control' type='text'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TYPE_ID'>_{TYPE}_:</label>
        <div class='col-md-8'>
          %TYPE_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='NAME'>_{ADDRESS_PARENT}_:</label>
        <div class='col-md-8'>
          %DISTRICT_SEL%
        </div>
      </div>

<!--      <div class='form-group row'>-->
<!--        <label class='col-md-4 col-form-label text-md-right' for='COUNTRY'>_{COUNTRY}_:</label>-->
<!--        <div class='col-md-8'>-->
<!--          %COUNTRY_SEL%-->
<!--        </div>-->
<!--      </div>-->

<!--      <div class='form-group row'>-->
<!--        <label class='col-md-4 col-form-label text-md-right' for='CITY'>_{CITY}_:</label>-->
<!--        <div class='col-md-8'>-->
<!--          <input id='CITY' name='CITY' value='%CITY%' placeholder='%CITY%' class='form-control' type='text'>-->
<!--        </div>-->
<!--      </div>-->

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='ZIP'>_{ZIP}_:</label>
        <div class='col-md-8'>
          <input id='ZIP' name='ZIP' value='%ZIP%' placeholder='%ZIP%' class='form-control' type='text'>
        </div>
      </div>

<!--      <div class='form-group row'>-->
<!--        <label class='col-md-4 col-form-label text-md-right' for='FILE_UPLOAD'>_{MAP}_ (*.jpg, *.gif, *.png):</label>-->
<!--        <div class='col-md-8'>-->
<!--          <input id='FILE_UPLOAD' name='FILE_UPLOAD' type='file' value='%FILE_UPLOAD%' placeholder='%FILE_UPLOAD%'>-->
<!--        </div>-->
<!--      </div>-->

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
    </div>
  </div>
</form>
