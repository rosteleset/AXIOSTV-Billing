<script>

  jQuery(function () {
    let dataTable = jQuery('#CRM_LEAD_LIST_');
    jQuery('#CHECK_LEADS_BTN').on('click', checkLeads);

    dataTable.on('page.dt', clearUserColumn);
    dataTable.on('length.dt', function () {
      setTimeout(appendColumn, 0, true);
    });
  });

  function checkLeads() {
    let userTableHeader = jQuery('#USER_TABLE_HEADER');

    if (userTableHeader.length > 0) clearUserColumn();
    jQuery('#CRM_LEAD_LIST_>thead>tr').find('th').eq(0).after('<th id="USER_TABLE_HEADER">_{USER}_</th>');

    let ids = appendColumn();
    if (ids.length < 1) userTableHeader.remove();

    jQuery('#CHECK_LEADS_BTN').hide();
    checkLead(ids.pop(), ids);

    function checkLead(id, ids) {
      if (!id) {
        jQuery('#CHECK_LEADS_BTN').show();
        return 0
      }

      fetch('?header=2&get_index=crm_users_by_lead_email&ID=' + id)
        .then(response => {
          if (!response.ok) throw response;

          return response;
        })
        .then(function (response) {
          return response.json();
        })
        .then(result => {
          if (!result.UID || !result.LOGIN) {
            Spinner.off(`column_${id}`, '_{ERROR}_', 'btn-danger');
          }
          else if (result['EXIST']) {
            Spinner.off(`column_${id}`, "_{CRM_USER_LINKED}_", 'btn-success');
          }
          else {
            let btn = '<div class="input-group input-group-sm" style="min-width: 100px;">' +
              '<input name="NAME" disabled class="form-control" value="' + result.LOGIN + '" id="' + id + '_FIELD">' +
              '<div class="input-group-append"><a class="btn input-group-button" id="SAVE_LEAD_' + id + '">' +
              '<span class="fa fa-save"></span></a></div></div>';
            Spinner.off(`column_${id}`, btn, '');

            jQuery('#SAVE_LEAD_' + id).on('click', function () { saveUser(id, result.UID, result.LOGIN) });
          }

          checkLead(ids.pop(), ids);
        })
        .catch(err => {
          Spinner.off(`column_${id}`, '_{CRM_USER_NOT_FOUND}_', 'btn-danger');
          console.log(err);
          checkLead(ids.pop(), ids);
        });

    }
  }

  function clearUserColumn() {
    jQuery('#USER_TABLE_HEADER').remove()
    jQuery("#CRM_LEAD_LIST_ tbody tr").each(function() {
      jQuery(this).find("[name='TEST_TD']").remove();
    });
  }
  function appendColumn(empty = false) {
    if (jQuery('#USER_TABLE_HEADER').length < 1) return;

    let ids = [];
    jQuery('#CRM_LEAD_LIST_ [name="ID"]').each(function () {
      let row = jQuery(this).parent().parent();
      if (row.find("[name='TEST_TD']").length > 0) return;

      let prevColumn = row.find('td').eq(0);
      if (!jQuery(this).prop('checked') || empty) {
        prevColumn.after(`<td name='TEST_TD'></td>`);
        return;
      }

      let id = jQuery(this).val();
      ids.push(id);
      prevColumn.after(`<td name='TEST_TD'><span class='badge' id="column_${id}"></span></td>`);

      Spinner.on(`column_${id}`);
    });

    return ids;
  }
  function saveUser(id, uid, login) {
    Spinner.on(`column_${id}`);
    fetch(`?header=2&get_index=crm_lead_info&LEAD_ID=${id}&add_uid=${uid}&RETURN_JSON=1`)
      .then(response => {
        if (!response.ok) throw response;

        return response;
      })
      .then(function (response) {
        return response.json();
      })
      .then(result => {
        if (result.error) {
          Spinner.off(`column_${id}`, '_{ERROR}_', 'btn-danger');
          return;
        }

        let btn = `<a href='?index=15&UID=${uid}' target='_blank' class='btn btn-default'>${login}</a>`;
        Spinner.off(`column_${id}`, btn, '');
      })
      .catch(err => {
        Spinner.off(`column_${id}`, '_{ERROR}_', 'btn-danger');
        console.log(err);
      });

  }

  let Spinner = {
    spinner: '<div class="fa fa-spinner fa-pulse"><span class="sr-only">Loading...</span></div>',
    on: function (spanElementId) {
      const spanElement = jQuery('#' + spanElementId);
      spanElement.html(Spinner.spinner);

    },
    off: function (spanElementId, status, color) {
      const spanElement = jQuery('#' + spanElementId);
      let contraryClass = color === 'btn-success' ? 'btn-danger' : 'btn-success';

      spanElement.html(status);
      spanElement.removeClass('btn-default');
      spanElement.removeClass(contraryClass);
      spanElement.addClass(color);
    },
  };

</script>
