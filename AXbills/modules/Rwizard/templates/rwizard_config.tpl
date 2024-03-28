<link rel='stylesheet' href='/styles/codemirror/lib/codemirror.css'>
<link rel='stylesheet' href='/styles/codemirror/theme/darcula.css'>
<link rel='stylesheet' href='/styles/codemirror/addon/hint/show-hint.css'>

<script src='/styles/codemirror/lib/codemirror.js'></script>
<script src='/styles/codemirror/mode/sql/sql.js'></script>
<script src='/styles/codemirror/addon/hint/show-hint.js'></script>
<script src='/styles/codemirror/addon/hint/sql-hint.js'></script>

<form action='$SELF_URL' METHOD='POST' ENCTYPE='multipart/form-data' id='CARDS_ADD'>
  <input type='hidden' name='index' value=$index>
  <input type='hidden' name='ID' value=$FORM{chg}>

  <div class='card card-outline card-primary form-horizontal'>
      <div class='card-header with-border'>
          <h3 class='card-title'>_{REPORTS_WIZARD}_</h3>
      </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='control-element col-md-6'>_{NAME}_</label>
        <label class='control-element col-md-6'>_{GROUP}_</label>
        <div class='col-md-6'>
          <input type='text' name='NAME' value='%NAME%' class='form-control'>
        </div>
        <div class='col-md-6'>
          %GROUP_SEL%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-element col-md-6'>_{QUERY}_: _{MAIN}_</label>
        <label class='control-element col-md-6'>_{QUERY}_: _{TOTAL}_</label>
        <div class='col-md-6'>
          <textarea class='form-control' id='QUERY' name='QUERY' rows=12 cols=75>%QUERY%</textarea>
        </div>
        <div class='col-md-6'>
          <textarea class='form-control' id='QUERY_TOTAL' name='QUERY_TOTAL' rows=12 cols=75>%QUERY_TOTAL%</textarea>
        </div>
      </div>

      <div class='form-group row'>
        <div class='col-md-6'>
          <label class='control-element col-md-12'>_{FIELDS}_ (_{FIELD}_:_{NAME}_:CHART[LINE]:FILTER)</label>
          <div class='col-md-12'>
            <textarea class='form-control' name='FIELDS' rows=12 cols=75>%FIELDS%</textarea>
          </div>
        </div>
        <div class='col-md-6'>
          <div class='form-group row'>
            <label class='control-element col-md-12'>_{COMMENTS}_</label>
            <div class='col-md-12'>
              <textarea class='form-control' name='COMMENTS' rows=3 cols=75>%COMMENTS%</textarea>
            </div>
          </div>
          <div class='form-group row'>
            <label class='control-element col-md-6'>_{IMPORT}_:</label>
            <div class='col-md-6'>
              <input name=IMPORT id='IMPORT' type='file'>
            </div>
          </div>
          <div class='form-group custom-control custom-checkbox'>
            <input class='custom-control-input' type='checkbox' id='QUICK_REPORT' name='QUICK_REPORT'
                   %QUICK_CHECKED% value='1'>
            <label for='QUICK_REPORT' class='custom-control-label'>_{QUICK_REPORT}_</label>
          </div>
        </div>
      </div>

    </div>
    <div class='card-footer'>
      <input type=submit name=%ACTION% value='%LNG_ACTION%' class='btn btn-primary'>
    </div>
  </div>

</FORM>


<script>
  let myDarkMode;
  // if variable exist

  if (typeof IS_DARK_MODE !== 'undefined') {
    myDarkMode = IS_DARK_MODE;
  }


  const RWIZARD_VARS = JSON.parse('%SPECIAL_VARIABLES%') || [];
  const PARSED_VARS = Object.fromEntries(
    RWIZARD_VARS.map(e => {
      if (e.includes('&')) {
        const key = e.replace(/&/gm, '%');
        return [key, ""];
      }
      const key = "%" + e + "%";
      return [key, '']
    })
  );
  const ORIGINAL_TABLES = JSON.parse('%TABLES_COLUMNS_JSON%') || {};
  const TABLES = Object.assign(PARSED_VARS, ORIGINAL_TABLES);

  window.onload = function() {
    addCodeMirror('QUERY');
    addCodeMirror('QUERY_TOTAL');

    jQuery('.CodeMirror').css('resize', 'vertical');
  };

  function addCodeMirror(id) {
    const CODEMIRROR_OPTIONS = {
      mode: 'text/x-mariadb',
      indentWithTabs: true,
      smartIndent: true,
      lineNumbers: true,
      matchBrackets : true,
      autofocus: true,
      extraKeys: {
        "Ctrl-Space": "autocomplete",
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
      document.getElementById(id), CODEMIRROR_OPTIONS
    );

    codeMirror.on("keyup", function (cm, event) {
      // keyCode 13 = Enter button
      if (!cm.state.completionActive && event.keyCode != 13) {
        CodeMirror.commands.autocomplete(cm, null, { completeSingle: false });
      }
    });

    codeMirror.display.wrapper.className += ' border rounded';
  }
</script>