<script>
  document.addEventListener('save-plan-time', (e) => {
    let id = e.detail.id;
    let aid = e.detail.aid;
    let plan_time = e.detail.planTime;
    if (!id || !plan_time) return;

    sendRequest(`/api.cgi/crm/progressbar/messages/${id}`, {plan_time: plan_time, aid: aid}, 'PUT');
  });

  document.addEventListener('save-plan-interval', (e) => {
    let id = e.detail.id;
    let plan_interval = e.detail.planInterval;
    if (!id || !plan_interval) return;

    sendRequest(`/api.cgi/crm/progressbar/messages/${id}`, {plan_interval: plan_interval}, 'PUT');
  });

  document.addEventListener('save-plan-date', (e) => {
    let id = e.detail.id;
    let plan_date = e.detail.planDate;
    if (!id || !plan_date) return;

    sendRequest(`/api.cgi/crm/progressbar/messages/${id}`, {planned_date: plan_date}, 'PUT');
  });

</script>