<link rel='stylesheet' href='/styles/codemirror/lib/codemirror.css'>
<link rel='stylesheet' href='/styles/codemirror/theme/darcula.css'>
<link rel='stylesheet' href='/styles/codemirror/addon/hint/show-hint.css'>

<script src='/styles/codemirror/lib/codemirror.js'></script>
<script src='/styles/codemirror/mode/sql/sql.js'></script>
<script src='/styles/codemirror/addon/hint/show-hint.js'></script>
<script src='/styles/codemirror/addon/hint/sql-hint.js'></script>

<form METHOD=POST class='form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=HOST_ID value='$FORM{HOST_ID}'>

  <div class='row'>
    <div class='col-md-7'>
      <div class='card card-primary card-outline'>

        <div class='card-header'>
          <h3 class='card-title'>SQL-_{QUERY}_</h3>
          <div class='card-tools'>
            <button type='button' title='Show/Hide' class='btn btn-tool' data-card-widget='collapse'><i
                class='fa fa-minus'></i></button>
          </div>
        </div>

        <div class='card-body'>
          <div class='form-group'>
            <textarea id='QUERY' name='QUERY' placeholder='_{QUERY}_...' cols=70 rows=10 onkeydown='keyDown(event)'
                      onkeyup='keyUp(event)' class='form-control'>%QUERY%</textarea>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-2'>_{ROWS}_:</label>
            <div class='col-md-2'><input type=text class='form-control' name='ROWS' value='%ROWS%'></div>
            <label class='control-label col-md-3'>_{SAVE}_: <input type=checkbox name='HISTORY' value='1'></label>
            <label class='control-label col-md-2'>XML: <input type=checkbox name='xml' value='1'></label>
          </div>

          <div class='form-group row'>
            <label class='control-label col-md-3'>_{COMMENTS}_:</label>
            <div class='col-md-6'><input type=text name='COMMENTS' value='%COMMENTS%' class='form-control'></div>
          </div>

        </div>

        <div class='card-footer'>
          <input type=submit name=show value='_{QUERY}_' id='go' class='btn btn-primary'>
        </div>
      </div>
    </div>

    <div class='col-md-5'>
      <div class='card card-primary card-outline'>
        <div class='card-header'>
          <h3 class='card-title'>_{QUERIES}_</h3>
          <div class='card-tools float-right'>
            <button type='button' title='Show/Hide' class='btn btn-tool' data-card-widget='collapse'><i
                    class='fa fa-minus'></i>
            </button>
          </div>
        </div>
        <div class='card-body p-0'>
        %SQL_SAVED_QUERIES%
        </div>
      </div>

      <div class='card card-primary card-outline collapsed-card'>
        <div class='card-header'>
          <h3 class='card-title'>_{LOG}_</h3>
          <div class='card-tools float-right'>
            <button type='button' class='btn btn-tool' data-card-widget='collapse'>
              <i class='fa fa-plus'></i>
            </button>
          </div>
        </div>
        <div class='card-body p-0'>
          %SQL_HISTORY_LAST%
        </div>
      </div>

    </div>

  </div>

</form>

<script>
  window.onload = function() {
    let myDarkMode;
    // if variable exist

    if (typeof IS_DARK_MODE !== 'undefined') {
      myDarkMode = IS_DARK_MODE;
    }

    const TABLES = JSON.parse('%TABLES_COLUMNS_JSON%') || {};

    const CODEMIRROR_OPTIONS = {
      mode: 'text/x-mariadb',
      indentWithTabs: true,
      smartIndent: true,
      lineNumbers: true,
      matchBrackets : true,
      autofocus: true,
      extraKeys: {
        'Ctrl-Space': 'autocomplete'
      },
      tabSize: 2,
      showCursorWhenSelecting: true,
      hint: CodeMirror.hint.sql,
      hintOptions: {
        alignWithWord: false,
        completeSingle: false,
        tables: TABLES
      }
    };

    if (myDarkMode) {
      CODEMIRROR_OPTIONS.theme = 'darcula';
    }

    let codeMirror = CodeMirror.fromTextArea(
      document.getElementById('QUERY'),
      CODEMIRROR_OPTIONS,
    );

    const ignoredKeycodes = [
      9, 13, 16, 17, 18, 19, 20, 27, 33, 34, 35, 36, 37, 38, 39, 40, 44, 45, 46, 59
    ];

    codeMirror.on('keyup', function (cm, event) {
      if (!cm.state.completionActive
          && !ignoredKeycodes.includes(event.keyCode)) {
        cm.showHint({ completeSingle: false });
      }
    });

    codeMirror.display.wrapper.className += ' border rounded';
    jQuery('.CodeMirror').css('resize', 'vertical');
  };
</script>
