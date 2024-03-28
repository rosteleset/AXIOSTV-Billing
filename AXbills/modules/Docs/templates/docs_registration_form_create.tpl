<script>

  function get_hidden_input(name, value) {
    var new_input = jQuery('<input/>');
    new_input.attr('name', name);
    new_input.attr('type', 'hidden');
    new_input.val(value);

    return new_input;
  }

  jQuery(function () {
    var form_to_send = jQuery('#form_DOCS_REGISTRATION');
    var export_btn = jQuery('#EXPORT_BTN');

    var clear_form_html;

    export_btn.on('click', function (e) {
      e.preventDefault();

      clear_form_html = form_to_send.html();

      form_to_send.attr('target', '_blank');

      // Remove and pop the value
      var index = jQuery(form_to_send.find('#INDEX').remove()).val();
      var pdf = form_to_send.find('#OUTPUT_FORM_PDF').prop('checked');

      form_to_send.attr('action', '/admin/index.cgi');
//            form_to_send.attr('method', 'get');

      form_to_send.prepend(get_hidden_input('qindex', index));
      form_to_send.prepend(get_hidden_input('print', 1));

      if (pdf) {
        form_to_send.prepend(get_hidden_input('pdf', 1));
      }

      form_to_send.submit();
      form_to_send.html(clear_form_html);
      form_to_send.attr('target', '');
    });
  });

  jQuery(function () {
    var output_html_radio = jQuery('#OUTPUT_FORM_HTML');
    var output_pdf_radio = jQuery('#OUTPUT_FORM_PDF');
    var textarea = jQuery('#TEXT_id');


    output_html_radio.on('change input', function () {
      textarea.prop('disabled', !output_html_radio.prop('checked'));
    });

    output_pdf_radio.on('change input', function () {
      textarea.prop('disabled', output_pdf_radio.prop('checked'));
    })
  });
</script>

<div class='card card-primary card-outline card-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{REGISTRATION}_ _{TEMPLATE}_</h4></div>
  <div class='card-body'>

    <form name='DOCS_REGISTRATION' id='form_DOCS_REGISTRATION' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' id='INDEX' value='$index'/>

      <div class='form-group row'>
        <label class='col-sm-12 col-md-12' for='NAME_id'>_{NAME}_ _{COMPANY}_</label>
        <div class='col-md-12'>
          <input type='text' class='form-control' name='NAME' value='%NAME%' id='NAME_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-12 col-md-12' for='HEADER_id'>_{HEADER}_</label>
        <div class='col-md-12'>
          <input type='text' class='form-control' name='HEADER' value='%HEADER%' id='HEADER_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-sm-12 col-md-12' for='TEXT_id'>_{TEXT}_</label>
        <div class='col-md-12'>
          <textarea class='form-control' name='TEXT' id='TEXT_id'>%TEXT%</textarea>
        </div>
      </div>

      <div class='radio'>
        <label>
          <input type='radio' name='OUTPUT' id='OUTPUT_FORM_HTML' value='html' %HTML_CHECKED%>
          <strong>HTML</strong>
        </label>
      </div>

      <div class='radio'>
        <label>
          <input type='radio' name='OUTPUT' id='OUTPUT_FORM_PDF' value='pdf' %PDF_CHECKED%>
          <strong>PDF</strong>
        </label>
      </div>

    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' class='btn btn-default' form='form_DOCS_REGISTRATION' name='generate' value='_{PREVIEW}_'>
    <button class='btn btn-primary' id='EXPORT_BTN'><span class='fas fa-print'></span> _{PRINT}_</button>
  </div>
</div>
<div class='row m-1'>
  <a class='btn btn-success'
     href='/admin/index.cgi?get_index=form_templates&header=1&new_editor=1&create=Docs:docs_registration.tpl&full=1'
     target='_blank'>_{CHANGE}_ HTML _{TEMPLATES}_</a>
</div>