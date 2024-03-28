<div class='%FORM_CLASS%'>
  <form class='form-inline'>
    <input type='hidden' name='index' value='%index%'>
    <input type='hidden' name='DATE' value='%DATE%'>

    <div class='form-group mb-2'>
      %ADMIN_SEL%
    </div>
    <div class='form-group mx-sm-3 mb-2'>
      %STATUS_SEL%
    </div>
    <button type='submit' class='btn btn-primary mb-2'>_{APPLY}_</button>
  </form>
  <hr class='m-1'>
</div>

<script>
  document.addEventListener('save-plan-time', (e) => {
    let id = e.detail.id;
    let aid = e.detail.aid;
    let plan_time = e.detail.planTime;
    if (!id || !plan_time) return;

    sendRequest(`/api.cgi/msgs/${id}`, {plan_time: plan_time, resposible: aid}, 'PUT');
  });

  document.addEventListener('save-plan-interval', (e) => {
    let id = e.detail.id;
    let plan_interval = e.detail.planInterval;
    if (!id || !plan_interval) return;

    sendRequest(`/api.cgi/msgs/${id}`, {plan_interval: plan_interval}, 'PUT');
  });

  document.addEventListener('save-plan-date', (e) => {
    let id = e.detail.id;
    let plan_date = e.detail.planDate;
    if (!id || !plan_date) return;

    sendRequest(`/api.cgi/msgs/${id}`, {plan_date: plan_date}, 'PUT');
  });

</script>