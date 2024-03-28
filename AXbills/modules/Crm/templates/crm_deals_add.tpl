<form action='%SELF_URL%' method='POST' name='CRM_DEALS_ADD' id='CRM_DEALS_ADD'>
  <input type='hidden' name='index' value='%index%'>
  <input type='hidden' name='UID' value='%UID%'>
  <input type='hidden' name='ID' value='%chg%'>
  <div class='row'>
    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{DEAL}_</h4>
        </div>
        <div class='card-body'>
          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4' for='NAME'>_{NAME}_:</label>
            <div class='col-md-8'>
              <input type='text' class='form-control' placeholder='_{NAME}_' name='NAME' id='NAME' value='%NAME%'/>
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4'>_{STEP}_:</label>
            <div class='col-md-8'>
              %STEP_SEL%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-form-label text-md-right col-md-4'>_{CRM_BEGIN_DATE}_:</label>
            <div class='col-md-8'>
              %BEGIN_DATE%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right'>_{CRM_CLOSE_DATE}_:</label>
            <div class='col-md-8'>
              %CLOSE_DATE%
            </div>
          </div>

          <div class='form-group row'>
            <label class='col-md-4 col-form-label text-md-right' for='COMMENTS'>_{DESCRIBE}_:</label>
            <div class='col-md-8'>
              <textarea class='form-control' id='COMMENTS' name='COMMENTS' rows='2'>%COMMENTS%</textarea>
            </div>
          </div>
        </div>
        <div class='card-footer'>
          <input type='submit' class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
        </div>
      </div>
    </div>
    <div class='col-md-6'>
      <div class='card card-primary card-outline'>
        <div class='card-header with-border'>
          <h4 class='card-title'>_{CRM_PRODUCTS}_</h4>
        </div>
        <div class='card-body'>
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
              <tbody id='product-list'>
              </tbody>
            </table>
            <a id='add_row' class='btn btn-sm btn-default float-left'><span class='fa fa-plus'></span></a>
            <a id='delete_row' class='btn btn-sm btn-default float-right'><span class='fa fa-minus'></span></a>
          </div>
        </div>
      </div>
    </div>
  </div>
</form>

<script>
  jQuery('#add_row').on('click', addProduct);
  jQuery('#delete_row').on('click', function () {
    let rows = jQuery('#product-list').children();
    if (rows.length < 2) return;

    jQuery('#product-list').children().last().remove();
  });

  let products;
  try {
    products = JSON.parse('%PRODUCTS_JSON%');
  } catch (e) {
    console.log(e);
  }

  if (products) {
    products.forEach(addProduct);
  } else {
    addProduct();
  }

  function addProduct(product = {}) {
    let table_row = jQuery('<tr></tr>');

    let row_id = jQuery(`[name='IDS']`).length + 1;
    let number_td = jQuery('<td></td>').append(jQuery(`<input type='hidden' name='IDS'/>`).val(row_id)).append(row_id);

    let order_input = jQuery(`<input type='text'/>`).attr('id', `ORDER_${row_id}`).attr('name', `ORDER_${row_id}`)
      .addClass('form-control').attr('placeholder', '_{ORDER}_');
    if (product.name) order_input.val(product.name);
    let order_td = jQuery('<td></td>').append(order_input);

    let types_select = jQuery("%FEES_TYPES%").attr('id', `FEES_TYPE_${row_id}`).attr('name', `FEES_TYPE_${row_id}`);
    let type_td = jQuery('<td></td>').append(types_select);
    if (product.fees_type) types_select.val(product.fees_type);

    let count_input = jQuery(`<input type='text'/>`).attr('id', `COUNT_${row_id}`).attr('name', `COUNT_${row_id}`)
      .addClass('form-control').attr('placeholder', '1');
    if (product.count) count_input.val(product.count);
    let count_td = jQuery('<td></td>').append(count_input);

    let sum_input = jQuery(`<input type='text'/>`).attr('id', `SUM_${row_id}`).attr('name', `SUM_${row_id}`)
      .addClass('form-control').attr('placeholder', '0.00');
    if (product.sum) sum_input.val(product.sum);
    let sum_td = jQuery('<td></td>').append(sum_input);

    table_row.append(number_td).append(order_td).append(type_td).append(count_td).append(sum_td);

    jQuery('#product-list').append(table_row);
    initChosen();
  }
</script>
