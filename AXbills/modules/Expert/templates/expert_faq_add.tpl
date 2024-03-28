<script src='/styles/default/js/modules/portal.js'></script>

<form name='expert_faq' method='POST' class='form-horizontal'>
  <input type=hidden name='index' value=$index>
  <input type=hidden name='ID' value=%ID%>

  <div class='card card-primary card-outline container col-md-6'>
    <div class='card-header with-border'><h4 class='card-title'>_{FAQ}_ %LNG_ACTION%</h4></div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-3 control-label'>_{TYPE}_:</label>
        <div class='col-md-9'>%FAQ_TYPES%</div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 required control-label' for='TITLE'>_{HEADER}_:</label>
        <div class='col-md-9'>
          <input class='form-control' required id='TITLE' name='TITLE' type='text' value='%TITLE%'>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 required control-label' for='ICON'>_{ICON}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <input class='form-control'required id='ICON' name='ICON' type='text' value='%ICON%'>
            <div class='input-group-append'>
              <a id='link' class='btn input-group-button' href='%ICON_DOCS%' target='_blank'>
                <i class='fa fa-book'></i>
              </a>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-3 control-label' for='news-text'>_{TEXT}_:</label>
        <div class='col-md-9'>
          <textarea class='form-control' name='BODY' cols=90 rows=15 id='news-text'>%BODY%</textarea>
          <div class='form-group row' style='margin-top: 5px;'>
            <div class='col-md-12' id='editor-controls'>
              <button type='button' class='btn btn-xs btn-primary' title='_{BOLD}_' data-tag='b'>_{BOLD}_</button>
              <button type='button' class='btn btn-xs btn-primary' title='_{ITALICS}_' data-tag='i'>_{ITALICS}_</button>
              <button type='button' class='btn btn-xs btn-primary' title='_{UNDERLINED}_' data-tag='u'>
                _{UNDERLINED}_
              </button>
              <button type='button' class='btn btn-xs btn-primary' title='_{LINK}_' data-tag='link'>_{LINK}_</button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class='col-md-12'>
      <div class='card-footer'>
        <input class='btn btn-primary' type='submit' name='%ACTION%' value='%LNG_ACTION%'>
      </div>
    </div>
  </div>
</form>
