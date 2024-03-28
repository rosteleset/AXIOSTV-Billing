%MENU%

<form action='%SELF_URL%' method='post' name='invoice_add' id='invoice_add'>
  <input type=hidden name=index value=$index>
  <input type=hidden name='UID' value='$FORM{UID}'>
  <input type=hidden name='DOC_ID' value='%DOC_ID%'>
  <input type=hidden name='sid' value='$FORM{sid}'>
  <input type=hidden name='OP_SID' value='%OP_SID%'>
  <input type=hidden name='VAT' value='%VAT%'>
  <input type=hidden name='SEND_EMAIL' value='1'>
  <input type=hidden name=INCLUDE_DEPOSIT value=1>

  <div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
      <h4 class='card-title'>%CAPTION%</h4>
      <span class='float-right'>
        <a href='%SELF_URL%?full=1&get_index=docs_invoice_company&UID=%UID%' class='btn btn-xs btn-success'>_{NEXT_PERIOD_INVOICE}_</a>
      </span>
    </div>
    <div class='card-body'>

      %FORM_INVOICE_ID%

      <div class='form-group row'>
        <label class='control-label col-sm-12 col-md-3' for='DATE'>_{DATE}_:</label>
        <div class='col-sm-12 col-md-9'>
          <div class='input-group'>
            %DATE_FIELD%
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-sm-12 col-md-3' for='CUSTOMER'>_{CUSTOMER}_:</label>
        <div class='col-sm-12 col-md-9'>
          <div class='input-group'>
            <input type='text' id='CUSTOMER' name='CUSTOMER' value='%CUSTOMER%' placeholder='%CUSTOMER%'
                   class='form-control'>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-sm-12 col-md-3' for='PHONE'>_{PHONE}_:</label>
        <div class='col-sm-12 col-md-9'>
          <div class='input-group'>
            <input type='text' id='PHONE' name='PHONE' value='%PHONE%' placeholder='%PHONE%' class='form-control'>
          </div>
        </div>
      </div>

      <div class='form-group'>
        <table class='table table-bordered' id='tab_logic'>
          <thead>
          <tr>
            <th style='width: 10px'>
              #
            </th>
            <th style='width: 300px'>
              _{NAME}_
            </th>
            <th style='width: 200px'>
              _{LIST_OF_CHARGES}_
            </th>
            <th style='width: 75px'>
              _{COUNT}_
            </th>
            <th style='width: 75px'>
              _{SUM}_
            </th>
          </tr>
          </thead>
          <tbody>

          <tr id='addr1'>
            <td>
              <input type=hidden name=IDS value='1'>
              1
            </td>
            <td>
              <input type='text' id='ORDER_1' name='ORDER_1' value='%ORDER_1%' placeholder='_{ORDER}_'
                     class='form-control'/>
            </td>
            <td>
              %TYPES_FEES%
            </td>
            <td>
              <input type='text' id='COUNTS_1' name='COUNTS_1' value='%COUNTS_1%' placeholder='1' class='form-control'/>
            </td>
            <td>
              <input type='text' name='SUM_1' id='SUM_1' value='%SUM_1%' placeholder='0.00' class='form-control'/>
              <input type='hidden' name='FEES_ID_1' id='FEES_ID_1' value='%FEES_ID_1%'/>
            </td>
          </tr>
          <tr id='addr2'></tr>
          </tbody>
        </table>
        <a id='add_row' class='btn btn-sm btn-default float-left'>
          <span class='fa fa-plus'></span>
        </a>
        <a id='delete_row' class='btn btn-sm btn-default float-right'>
          <span class='fa fa-minus'></span>
        </a>

      </div>

    </div>

    <div class='card-footer'>
      <input type=submit name=create value='_{CREATE}_' class='btn btn-primary'>
    </div>

  </div>

</form>

<script>
  jQuery(document).ready(function () {
    checkSelect();
    var i = 2;
    var tp_fs = `%TYPES_FEES%`;
    jQuery('#add_row').click(function () {
      var tp_fs_new = tp_fs.replace(/TYPE_FEES_1/g, "TYPE_FEES_" + i);
      jQuery('#addr' + i).html("<td>" + i + " <input type=hidden name=IDS value='" + i + "'>" + "</td><td><input id='ORDER_" + i + "' name='ORDER_" + i + "' type='text' placeholder='_{ORDER}_' class='form-control input-md'  /> </td><td>" + tp_fs_new + "</td><td><input  name='COUNTS_" + i + "' type='text' placeholder='1'  class='form-control input-md'></td><td><input  name='SUM_" + i + "' id='SUM_" + i + "' type='text' placeholder='0.00'  class='form-control input-md'></td>");
      jQuery('#tab_logic').append('<tr id="addr' + (i + 1) + '"></tr>');
      initChosen();
      checkSelect();
      i++;
    });

    jQuery('#delete_row').click(function () {
      if (i > 1) {
        jQuery("#addr" + (i - 1)).html('');
        i--;
      }
    });

    function checkSelect() {
      jQuery("select[name^='TYPE_FEES_']").on('change', (function () {
        var changedId = jQuery(this).attr('name');
        var patt1 = /(\d+)/g;
        var selId = changedId.match(patt1);
        jQuery.post('/admin/index.cgi', 'header=2&get_index=docs_invoices_list&GET_FEES_INFO=1&ID=' + this.value, function (result) {
          var myFeesData = JSON.parse(result);
          jQuery("input#SUM_" + selId).val(myFeesData.SUM);
          jQuery("input#ORDER_" + selId).val(myFeesData.NAME);
        });

      }));
    }
  });

</script>