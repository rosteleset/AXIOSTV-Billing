%UNREG_TABLE%

<script>
  let url = '$SELF_URL?header=2&get_index=equipment_unreg_report_date';
  let refresh_period = '%PERIOD%' + '000'; // ms

  equipment_unreg_report(url);

  function equipment_unreg_report(url) {

    let box_body = document.createElement('div');
    let unreg_items_body = document.getElementById('p_UNREG_ITEMS');
    box_body.id = 'loading_content';
    box_body.classList.add('card-body');

    let status_loading = document.createElement('div');
    status_loading.id = 'status-loading-content';

    let text_center = document.createElement('div');
    text_center.classList.add('text-center');

    let span = document.createElement('span');
    span.classList.add('fa');
    span.classList.add('fa-spinner');
    span.classList.add('fa-spin');
    span.classList.add('fa-2x');

    text_center.appendChild(span);
    status_loading.appendChild(text_center);
    box_body.appendChild(status_loading);

    unreg_items_body.appendChild(box_body);

    fetch(url)
      .then(function (response) {
        if (!response.ok)
          throw Error(response.statusText);

        return response;
      })
      .then(function (response) {
        return response.text();
      })
      .then(result => {
        contentLoading = false;
        let equipment_unreg_report_div = document.getElementById('Equipment:equipment_unreg_report');
        equipment_unreg_report_div.innerHTML = result;

        setTimeout(function () { //
          equipment_unreg_report(url);
        }, refresh_period);

      });

  }
</script>
