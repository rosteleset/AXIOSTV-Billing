<!--START KTK-39 -->

<form class='form-horizontal' name='users_pi'>

    <div class='card card-primary card-outline box-form'>
      <div class='card-header with-border'><h3 class='card-title'>%LOGIN%</h3>
        <div class='card-tools float-right'>
        <button type='button' class='btn btn-secondary btn-xs' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        <div class='form-group'>
          <label class='control-label' for='PASPORT_DATE'>_{FIO}_</label>
          <input class='form-control' type='text' disabled value='%FIO%' placeholder='_{NO}_'>
        </div>
        <div class='form-group'>
          <label class='control-label' for='PASPORT_DATE'>_{ADDRESS}_</label>
          <input class='form-control' type='text' readonly value='%ADDRESS_FULL%' placeholder='_{NO}_'>
        </div>
        <div class='form-group'>
          <label class='control-label' for='PASPORT_DATE'>_{PHONE}_</label>
          <input class='form-control' type='text' readonly value='%PHONE%' placeholder='_{NO}_'>
        </div>
        <div class='form-group'>
          <label class='control-label' for='PASPORT_DATE'>_{COMMENTS}_</label>
          <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='4' readonly>%COMMENTS%</textarea>
        </div>
      </div>
    
      <div class='card collapsed-box' style='margin-bottom: 0px; border-top-width: 1px;'>
        <div class='card-header with-border'>
          <h3 class='card-title'>_{PASPORT}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-secondary btn-xs' data-card-widget='collapse'><i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body'>
          <div class='form-group'>
            <label class='control-label' for='PASPORT_NUM'>_{NUM}_</label>
            <div>
              <input id='PASPORT_NUM' name='PASPORT_NUM' readonly value='%PASPORT_NUM%'
                     placeholder='%PASPORT_NUM%'
                     class='form-control' type='text'>
            </div>
            <label class='control-label' for='PASPORT_DATE'>_{DATE}_</label>
            <div>
              <input id='PASPORT_DATE' type='text' name='PASPORT_DATE' readonly value='%PASPORT_DATE%'
                     class='form-control'>
            </div>
          </div>
          <div class='form-group'>
            <label class='control-label' for='PASPORT_GRANT'>_{GRANT}_</label>
            <div>
                    <textarea class='form-control' id='PASPORT_GRANT' name='PASPORT_GRANT' readonly>%PASPORT_GRANT%</textarea>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class='card card-primary card-outline box-form'>
      <div class='card-header with-border'><h3 class='card-title'>_{STATUS}_</h3>
        <div class='card-tools float-right'>
        <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
          </button>
        </div>
      </div>
      <div class='card-body'>
        <div class='form-group'>
          <label class='control-label' for='STATUS'>_{STATUS}_</label>
          <div>
            <input class='form-control' type='text' readonly value='%STATUS%' placeholder='_{NO}_'>
          </div>
        </div>
        <div class='form-group'>
          <label for='IP_NUM'>%IP_TEXT%</label>
          <div>
            <input class='form-control' type='text' readonly value='%IP_NUM%' placeholder='_{NO}_'>
          </div>
        </div>
        <div class='form-group' %STATIC_IP_HIDDEN% >
          <label class='control-label' for='STATIC_IP'>%STATIC_IP_TEXT%</label>
          <div>
            <input class='form-control' type='text' readonly value='%STATIC_IP%' placeholder='_{NO}_'>
          </div>
        </div>
        %BUTTON%
      </div>
    </div>  
</form>

<!--END KTK-39 -->