<form action='$SELF_URL' method='POST' class='form-horizontal'>
  <input type='hidden' name='index' value='$index'>

  <div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{INVOICE_PAYMENTS}_</h4>
    </div>
    <div class='card-body'>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right'>_{STORAGE_INVOICE}_:</label>
        <div class='col-md-8'>
          %INVOICES_SELECT%
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='SUM'>_{SUM}_:</label>
        <div class='col-md-8'>
          <input name='SUM' id='SUM' value='%SUM%' class='form-control'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='TOTAL_INVOICE_SUM'>_{TOTAL_INVOICE_SUM}_:</label>
        <div class='col-md-8'>
          <input name='ACTUAL_SUM' value='%ACTUAL_SUM%' class='form-control' id='TOTAL_INVOICE_SUM'>
        </div>
      </div>
      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-8'>
          <textarea id='COMMENTS' name='COMMENTS' class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%BTN_NAME%' value='%BTN_VALUE%'>
    </div>
  </div>
</form>

<script>
  jQuery(document).ready(function() {
    jQuery('#INVOICE_ID').on('change', function () {
      var val = jQuery(this).val();

      jQuery.post('/admin/index.cgi', 'header=2&get_index=storage_invoices_payments&invoice_sum=1&INVOICE_ID=' + val, function (result) {
        jQuery('#TOTAL_INVOICE_SUM').val(result);
      });
    });
  });
</script>