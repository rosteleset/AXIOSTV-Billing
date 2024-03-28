<link rel='stylesheet' href='/styles/codemirror/lib/codemirror.css'>
<link rel='stylesheet' href='/styles/codemirror/theme/darcula.css'>
<link rel='stylesheet' href='/styles/codemirror/addon/hint/show-hint.css'>

<script src='/styles/codemirror/lib/codemirror.js'></script>
<script src='/styles/codemirror/mode/xml/xml.js'></script>
<script src='/styles/codemirror/mode/htmlmixed/htmlmixed.js'></script>
<script src='/styles/codemirror/addon/hint/show-hint.js'></script>
<script src='/styles/codemirror/addon/hint/xml-hint.js'></script>
<script src='/styles/codemirror/addon/hint/html-hint.js'></script>

<script src='/styles/default/js/modules/portal.js'></script>
<script src='/styles/default/js/beautify-html.js'></script>

<form action=$SELF_URL name='portal_form' method=POST class='form-horizontal' enctype='multipart/form-data'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=ID value=%ID%>

  <div class='row'>
    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
          <h4 class='card-title'>%TITLE_NAME%</h4>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{DATE_PUBLICATE}_:</label>
            <div class='col-md-9'>
              <input required class='form-control datepicker' placeholder='0000-00-00' name='DATE' value='%DATE%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{DATE_END_PUBLICATE}_:</label>
            <div class='col-md-9'>
              <input class='form-control datepicker' placeholder='0000-00-00' name='END_DATE' value='%END_DATE%'>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{MENU}_:</label>
            <div class='col-md-9'>%PORTAL_MENU_ID%</div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label' for='PERMALINK'>_{LINK}_</label>
            <div class='col-md-9'>
              <div class='input-group'>
                <input id='PERMALINK' name='PERMALINK' value='%PERMALINK%' class='form-control' type='text'>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{SHOW}_:</label>
            <div class='col-md-9'>
              <div class='row'>
                <div class='col-md-4'>
                  <div class='custom-control custom-radio'>
                    <input class='custom-control-input' type='radio' id='STATUS' name='STATUS' value='1' %SHOWED%>
                    <label for='STATUS' class='custom-control-label'>_{SHOW}_</label>
                  </div>
                </div>
                <div class='col-md-4'>
                  <div class='custom-control custom-checkbox'>
                    <input class='custom-control-input' type='checkbox' id='ON_MAIN_PAGE' name='ON_MAIN_PAGE'
                           value='1' %ON_MAIN_PAGE_CHECKED%>
                    <label for='ON_MAIN_PAGE' class='custom-control-label'>_{ON_MAIN_PAGE}_</label>
                  </div>
                </div>
                <div class='col-md-4'>
                  <div class='custom-control custom-radio'>
                    <input class='custom-control-input' type='radio' id='STATUS_OFF' name='STATUS' value='0' %HIDDEN%>
                    <label for='STATUS_OFF' class='custom-control-label'>_{HIDE}_</label>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class='card mb-0'>
          <div class='card-header'>
            <h2 class='card-title'>_{CONTENT}_</h2>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-minus'></i>
              </button>
            </div>
          </div>

          <div class='card-body'>
            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{PICTURE}_:</label>
              <div class='col'>
                <div id='file_upload_holder' class='form-file-input'>
                  <div class='form-group m-1'>
                    <input name='PICTURE' type='file' data-number='0' class='fixed'>
                  </div>
                </div>
              </div>
            </div>

            <div class='form-group row'>
              <label class='col-md-3 control-label'>_{TITLE}_:</label>
              <div class='col-md-9'>
                <input required class='form-control' name='TITLE' type='text' value='%TITLE%' size=90 align=%ALIGN%/>
              </div>
            </div>

            <div class='form-group row mb-0'>
              <label class='col-md-3 control-label'>_{SHORT_DESCRIPTION}_:</label>
              <div class='col-md-9'>
                <textarea class='form-control' name='SHORT_DESCRIPTION' cols=90 rows=4>%SHORT_DESCRIPTION%</textarea>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>


    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'><h4 class='card-title'>_{USER_CONF}_</h4></div>
        <div class='card-body'>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{USER_PORTAL}_:</label>
            <div class='col-md-9'>
              <div class='row'>
                <div class='col-md-6'>
                  <div class='custom-control custom-radio'>
                    <input class='custom-control-input' type='radio' id='ARCHIVE' name='ARCHIVE' value='0' %HIDDEN_ARCHIVE%>
                    <label for='ARCHIVE' class='custom-control-label'>_{SHOW}_</label>
                  </div>
                </div>
                <div class='col-md-6'>
                  <div class='custom-control custom-radio'>
                    <input class='custom-control-input' type='radio' id='HIDE_ARCHIVE' name='ARCHIVE' value='1' %SHOWED_ARCHIVE%>
                    <label for='HIDE_ARCHIVE' class='custom-control-label'>_{TO_ARCHIVE}_</label>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{IMPORTANCE}_:</label>
            <div class='col-md-9'>
              %IMPORTANCE_STATUS%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{GROUPS}_:</label>
            <div class='col-md-9'>
              %GROUPS%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-3 control-label'>_{TAGS}_:</label>
            <div class='col-md-9'>
              %TAGS%
            </div>
          </div>

          <!-- its very very very dumb option, but still exist -->
          <div class='form-group row' style='%DOMAIN_STYLE%'>
            <label class='col-md-3 control-label'>_{DOMAINS}_:</label>
            <div class='col-md-9'>
              %DOMAIN_ID%
            </div>
          </div>

          %ADDRESS_FORM%

          <div class='form-group row'>
            <label for='RESET' class='col-md-6 control-label'>_{RESET_ADDRESS}_</label>
            <div class='custom-control custom-checkbox pt-1'>
              <input class='custom-control-input' type='checkbox' id='RESET' name='RESET'
                     value='1' %RESET%>
              <label for='RESET' class='custom-control-label'></label>
            </div>
          </div>

        </div>
        <div class='card'>
          <div class='card-header'>
            <h3 class='card-title'>_{DELIVERY}_</h3>
          </div>
          <div class='card-body'>
            <div class='form-group row %TELEGRAM_NOT_EXIST%'>
              <label for='NEWSLETTER_TELEGRAM' class='col-md-6 control-label'>Telegram</label>
              <div class='custom-control custom-checkbox pt-1'>
                <input class='custom-control-input' type='checkbox' id='NEWSLETTER_TELEGRAM' name='NEWSLETTER_TELEGRAM'
                       value='1' %CURRENTLY_ADDED% %TELEGRAM_SELECTED%>
                <label for='NEWSLETTER_TELEGRAM' class='custom-control-label'></label>
              </div>
            </div>
            <div class='form-group row %VIBER_BOT_NOT_EXIST%'>
              <label for='NEWSLETTER_VIBER_BOT' class='col-md-6 control-label'>Viber</label>
              <div class='custom-control custom-checkbox pt-1'>
                <input class='custom-control-input' type='checkbox' id='NEWSLETTER_VIBER_BOT' name='NEWSLETTER_VIBER_BOT'
                       value='1' %CURRENTLY_ADDED% %VIBER_BOT_SELECTED%>
                <label for='NEWSLETTER_VIBER_BOT' class='custom-control-label'></label>
              </div>
            </div>
            <div class='form-group row %PUSH_NOT_EXIST%'>
              <label for='NEWSLETTER_PUSH' class='col-md-6 control-label'>Push</label>
              <div class='custom-control custom-checkbox pt-1'>
                <input class='custom-control-input' type='checkbox' id='NEWSLETTER_PUSH' name='NEWSLETTER_PUSH'
                       value='1' %CURRENTLY_ADDED% %PUSH_SELECTED%>
                <label for='NEWSLETTER_PUSH' class='custom-control-label'></label>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class='col-12'>
      <div class='card card-outline card-primary'>
        <div class='card-header'>
          <h3 class='card-title'>_{CONTENT_FULL}_</h3>
        </div>
        <div class='card-body'>
          <div class='col-md-12'>
            <textarea class='form-control' name='CONTENT' cols=90 rows=15 id='news-text'>%CONTENT%</textarea>
            <div class='form-group row mt-2 mb-0 justify-content-between'>
              <div class='col-md-6 col-12 mb-2' id='editor-controls'>
                <button type='button' class='btn btn-xs btn-primary' title='_{BOLD}_' data-tag='b'>_{BOLD}_</button>
                <button type='button' class='btn btn-xs btn-primary' title='_{ITALICS}_' data-tag='i'>_{ITALICS}_</button>
                <button type='button' class='btn btn-xs btn-primary' title='_{UNDERLINED}_' data-tag='u'>
                  _{UNDERLINED}_
                </button>
                <button type='button' class='btn btn-xs btn-primary' title='_{LINK}_' data-tag='a'>_{LINK}_</button>
                <button id='portal_reindent_button' type='button' class='btn btn-xs btn-default'>_{FORMAT}_</button>
              </div>

              <div class='form-group col-md-6 col-12'>
                <label>_{COPY_MODE}_</label>
                <div>
                  <div class='custom-control custom-radio d-inline'>
                    <input class='custom-control-input' type='radio' id='rad_HTML_FULL' name='COPY_MODE' value='FULL'>
                    <label for='rad_HTML_FULL' class='custom-control-label'>_{MODE_FULL_HTML}_</label>
                  </div>
                  <div class='custom-control custom-radio d-inline'>
                    <input class='custom-control-input' type='radio' id='rad_HTML_CLEAN' name='COPY_MODE' value='CLEAN' checked>
                    <label for='rad_HTML_CLEAN' class='custom-control-label'>_{MODE_CLEAN_HTML}_</label>
                  </div>
                  <div class='custom-control custom-radio d-inline'>
                    <input class='custom-control-input' type='radio' id='rad_PLAIN' name='COPY_MODE' value='PLAIN'>
                    <label for='rad_PLAIN' class='custom-control-label'>_{MODE_PLAIN}_</label>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class='card-footer'>
          <input class='btn btn-primary' type=submit name=%ACTION% value=%ACTION_LNG%>
        </div>
      </div>
    </div>
  </div>
  <div class='card'>
    <div class='card-header'>
      <h3 class='card-title'>_{PREVIEW}_</h3>
    </div>
    <div id='preview_container'>
      <iframe id='preview' onload="resizeIframe(this)" style='width: 100%; border-width: 1px; border-radius: .25rem'></iframe>
    </div>

  </div>
</form>

<script>
  // Codemirror init
    let myDarkMode;
  // if variable exist

  if (typeof IS_DARK_MODE !== 'undefined') {
    myDarkMode = IS_DARK_MODE;
  }

  const CODEMIRROR_OPTIONS = {
    mode: 'htmlmixed',
    indentWithTabs: true,
    smartIndent: true,
    lineNumbers: true,
    matchBrackets : true,
    autofocus: true,
    extraKeys: {"Ctrl-Space": "autocomplete"},
    tabSize: 2,
    showCursorWhenSelecting: true,
    hint: CodeMirror.hint.html
  };

  if (myDarkMode) {
    CODEMIRROR_OPTIONS.theme = 'darcula';
  }

  let codeMirror = CodeMirror.fromTextArea(
    document.getElementById('news-text'),
    CODEMIRROR_OPTIONS,
  );

  codeMirror.display.wrapper.className += ' border rounded';
  jQuery('.CodeMirror').css('resize', 'vertical');
  // Other work actually in portal.js
</script>
