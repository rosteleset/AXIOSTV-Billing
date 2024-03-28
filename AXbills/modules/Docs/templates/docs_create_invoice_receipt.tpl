<div class='card card-primary card-outline collapsed-card mb-0 border-top'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{DOCS}_</h4>
    <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-plus'></i>
      </button>
    </div>
  </div>
  <div class='card-body'>
    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right required' for='APPLY_TO_INVOICE'>_{APPLY_TO_INVOICE}_</label>
      <div class='col-md-8'>
        <select name='APPLY_TO_INVOICE' ID='APPLY_TO_INVOICE' class='form-control w-100'>
          <option value='1'>_{YES}_</option>
          <option value='0'>_{NO}_</option>
        </select>
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right required' for='INVOICE_ID'>_{INVOICE}_</label>
      <div class='col-md-8'>
        %INVOICE_SEL%
      </div>
    </div>

    <div class='form-group row'>
      <label class='col-md-4 col-form-label text-md-right' for='CREATE_RECEIPT'>_{RECEIPT}_:</label>
      <div class='col-md-8'>
        <div class='form-check'>
          <input type='checkbox' class='form-check-input' id='CREATE_RECEIPT' name='CREATE_RECEIPT' %CREATE_RECEIPT_CHECKED% value='1'>
        </div>
      </div>
    </div>

    <input type='hidden' name='SEND_EMAIL' value='%SEND_MAIL%'>
  </div>
</div>