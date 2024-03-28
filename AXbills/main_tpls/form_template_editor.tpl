<link rel='stylesheet' href='/styles/codemirror/lib/codemirror.css'>
<link rel='stylesheet' href='/styles/codemirror/theme/darcula.css'>
<link rel='stylesheet' href='/styles/codemirror/addon/hint/show-hint.css'>

<script src='/styles/codemirror/lib/codemirror.js'></script>
<script src='/styles/codemirror/mode/xml/xml.js'></script>
<script src='/styles/codemirror/mode/css/css.js'></script>
<script src='/styles/codemirror/mode/javascript/javascript.js'></script>
<script src='/styles/codemirror/mode/htmlmixed/htmlmixed.js'></script>
<script src='/styles/codemirror/addon/hint/show-hint.js'></script>
<script src='/styles/codemirror/addon/hint/xml-hint.js'></script>
<script src='/styles/codemirror/addon/hint/html-hint.js'></script>

<form id='template_form' action='$SELF_URL' method='post'>

  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='tpl_name' value='%TPL_NAME%'>
  <input type='hidden' name='change' value='1'>
  <input type='hidden' name='new_editor' value='1'>

  <input type='hidden' id='template_result' name='template'/>

  <div style='border: 1px solid silver'>
    <textarea id='a_code_editor'>__TEMPLATE__</textarea>
  </div>

  <iframe id='preview' style='width: 100%; height: 0'></iframe>
  <div class='axbills-form-main-buttons pb-3'>
    <button role='button' id='preview_template_btn' class='btn btn-secondary'>_{PREVIEW}_</button>
    <input type='submit' value='_{SAVE}_' class='btn btn-primary'/>
  </div>
</form>

<script>

  var ACodeEditor = document.getElementById('a_code_editor');

  let myDarkMode;
  // if variable exist

  if (typeof IS_DARK_MODE !== 'undefined') {
    myDarkMode = IS_DARK_MODE;
  }

  const CODEMIRROR_PARAMS = {
    mode: 'htmlmixed',
    value: ACodeEditor.value,
    smartIndent: true,
    lineNumbers: true,
    autofocus: true,
    extraKeys: {"Ctrl-Space": "autocomplete"},
    hint: CodeMirror.hint.html,
  };

  if (myDarkMode) {
    CODEMIRROR_PARAMS.theme = 'darcula';
  }

  var myCodeMirror = CodeMirror(
    function (elt) {
      ACodeEditor.parentNode.replaceChild(elt, ACodeEditor);
    },
    CODEMIRROR_PARAMS,
  );

  jQuery('.CodeMirror').css('resize', 'vertical');

  jQuery(function () {
    var _form = jQuery('#template_form');

    _form.on('submit', function () {
      jQuery('#template_result').val(myCodeMirror.getValue());
    });

    jQuery('#preview_template_btn').on('click', fillPreview);

    jQuery('#preview').on('load', function () {
      setIframeHeight(this.id)
    });

    function fillPreview(e) {
      e.preventDefault();

      var previewFrame = document.getElementById('preview');
      var preview      = previewFrame.contentDocument || previewFrame.contentWindow.document;

      var bootstrapStyles =
              '<link href=/styles/default/css/adminlte.min.css rel=stylesheet>'
              + '<link href=/styles/default/css/style.css rel=stylesheet>';

      preview.open();

      preview.write(
          '<!DOCTYPE html>' +
          '<html>' +
          '<head>' + bootstrapStyles + '</head>' +
          '<body>' +
          '<div class=\'container\' id=\'preview_container\'>' +
          '</div></body>' +
          '</html>'
      );

      var script = document.createElement('script');
      script.src = '/styles/default/js/jquery.min.js';
      preview.getElementsByTagName('head')[0].appendChild(script);

//        var script2     = document.createElement('script');
//        script2.src = '/styles/default/js/bootstrap.bundle.min.js';
//        preview.getElementsByTagName('head')[0].appendChild(script2);

      preview.addEventListener('DOMContentLoaded', function (event) {

        preview.getElementById('preview_container').innerHTML = myCodeMirror.getValue();

      });

      preview.close();
    }

    function getDocHeight(doc) {
      doc        = doc || document;
      // stackoverflow.com/questions/1145850/
      var body   = doc.body, html = doc.documentElement;
      var height = Math.max(body.scrollHeight, body.offsetHeight,
          html.clientHeight, html.scrollHeight, html.offsetHeight);
      return height;
    }

    function setIframeHeight(id) {
      var ifrm              = document.getElementById(id);
      var doc               = ifrm.contentDocument ? ifrm.contentDocument : ifrm.contentWindow.document;
      ifrm.style.visibility = 'hidden';
      ifrm.style.height     = '10px'; // reset to minimal height ...
      // IE opt. for bing/msn needs a bit added or scrollbar appears
      ifrm.style.height     = getDocHeight(doc) + 4 + 'px';
      ifrm.style.visibility = 'visible';
    }
  });

</script>