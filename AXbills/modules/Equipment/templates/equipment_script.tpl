<link rel='stylesheet' href='/styles/codemirror/lib/codemirror.css'>
<form id='script_form' action='$SELF_URL' method='post'>

  <input type='hidden' name='index' value='$index'>
  <input type='hidden' name='_id' value='%_id%'>

  <input type='hidden' id='script_result' name='script'/>
  <!--
  <!-- Extensions -->
  <script src='/styles/codemirror/lib/codemirror.js'></script>
  <!-- <script src='/styles/codemirror/mode/xml/xml.js'></script> -->
  <script src='/styles/codemirror/mode/javascript/javascript.js'></script>
  <!-- <script src='/styles/codemirror/mode/css/css.js'></script> -->
  <!-- <script src='/styles/codemirror/mode/htmlmixed/htmlmixed.js'></script> -->
 
  <div style='border: 1px solid silver'>
    <textarea id='a_code_editor'>__SCRIPT__</textarea>
  </div>

  <input type='submit' name='save' value='_{SAVE}_' class='btn btn-primary'  style='margin-top: 10px; margin-bottom: 10px'/>
  %DEL_BTN%

</form> 
<style> 
.CodeMirror {
    height: 100%;
}
</style>

<script>

  var ACodeEditor = document.getElementById('a_code_editor');

  var myCodeMirror = CodeMirror(function (elt) {
    ACodeEditor.parentNode.replaceChild(elt, ACodeEditor);
  }, {
    value      : ACodeEditor.value,
    smartIndent: true,
    lineNumbers: true,
    autofocus  : true
  });

  jQuery(function () {

    var _form = jQuery('#script_form');

    _form.on('submit', function () {
      jQuery('#script_result').val(myCodeMirror.getValue());
    });

  });
</script>
