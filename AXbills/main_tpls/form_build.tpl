<form action='$SELF_URL' METHOD='post' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='BUILDS' value='$FORM{BUILDS}'/>

  <div class='row'>
    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{ADDRESS_BUILD}_</h4>
        </div>
        <div class='card-body'>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='NUMBER'>_{NUM}_:</label>
            <div class='col-md-8'>
              <input id='NUMBER' name='NUMBER' value='%NUMBER%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='TYPE_ID'>_{TYPE}_:</label>
            <div class='col-md-8'>
              %TYPE_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='BLOCK'>_{BLOCK}_:</label>
            <div class='col-md-8'>
              <input id='BLOCK' name='BLOCK' value='%BLOCK%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='STREET_SEL'>_{ADDRESS_STREET}_:</label>
            <div class='col-md-8'>
              %STREET_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='ENTRANCES'>_{ENTRANCES}_:</label>
            <div class='col-md-8'>
              <input id='ENTRANCES' name='ENTRANCES' value='%ENTRANCES%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='FLORS'>_{FLORS}_:</label>
            <div class='col-md-8'>
              <input id='FLORS' name='FLORS' value='%FLORS%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='FLATS'>_{FLATS}_:</label>
            <div class='col-md-8'>
              <input id='FLATS' name='FLATS' value='%FLATS%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='START_NUMBERING_FLAT'>_{START_NUMBERING_FLAT}_:</label>
            <div class='col-md-8'>
              <input id='START_NUMBERING_FLAT' name='START_NUMBERING_FLAT' value='%START_NUMBERING_FLAT%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='BUILD_SCHEMA'>_{BUILD_SCHEMA}_:</label>
            <div class='col-md-8'>
              <textarea id='BUILD_SCHEMA' name='BUILD_SCHEMA' class='form-control' rows='2'>%BUILD_SCHEMA%</textarea>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='NUMBERING_DIRECTION'>_{NUMERATION_ROOMS}_:</label>
            <div class='col-md-8'>
              <div class='form-check'>
                <input type='checkbox' class='form-check-input' id='NUMBERING_DIRECTION' name='NUMBERING_DIRECTION'
                       %NUMBERING_DIRECTION_CHECK% value='1'>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='CONNECT'>_{PLANNED_TO_CONNECT}_:</label>
            <div class='col-md-8'>
              <div class='form-check'>
                <input type='checkbox' class='form-check-input' id='CONNECT' name='PLANNED_TO_CONNECT'
                       %PLANNED_TO_CONNECT_CHECK% value='1'>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>

    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{EXTRA}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-minus'></i>
            </button>
          </div>
        </div>

        <div id='builds_misc' class='card-body'>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='CONTRACT_ID'>_{CONTRACT}_:</label>
            <div class='col-md-8'>
              <input id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='CONTRACT_DATE'>_{CONTRACT}_ _{DATE}_:</label>
            <div class='col-md-8'>
              <input id='CONTRACT_DATE' name='CONTRACT_DATE' value='%CONTRACT_DATE%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='CONTRACT_PRICE'>_{PRICE}_:</label>
            <div class='col-md-8'>
              <input id='CONTRACT_PRICE' name='CONTRACT_PRICE' value='%CONTRACT_PRICE%' class='form-control'
                     type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='ZIP'>_{ZIP}_:</label>
            <div class='col-md-8'>
              <input id='ZIP' name='ZIP' value='%ZIP%' class='form-control' type='text'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
            <div class='col-md-8'>
              <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='3'>%COMMENTS%</textarea>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='PUBLIC_COMMENTS'>_{PUBLIC_COMMENTS}_:</label>
            <div class='col-md-8'>
              <textarea class='form-control' id='PUBLIC_COMMENTS' name='PUBLIC_COMMENTS'
                        rows='3'>%PUBLIC_COMMENTS%</textarea>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='ADDED'>_{ADDED}_:</label>
            <div class='col-md-8'>
              %ADDED%
            </div>
          </div>

          <div class='form-group row' data-visible='%MAP_BLOCK_VISIBLE%'>
            <label class='col-md-4 col-form-label text-md-right'>_{MAP}_:</label>
            <div class='col-md-8'>
              %MAP_BTN%
            </div>
          </div>

        </div>
      </div>
    </div>
  </div>
  <div class='card-footer'>
    <div class='col-md-12'>
      <input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>
</form>
