<link rel='stylesheet' href='/styles/default/css/modules/msgs/msgs_shedule.css'>
<script src='/styles/default/js/msgs/shedule_table.js'></script>

<div class='card card-primary card-outline center-block'>
  <div class='card-header with-border text-right'>
    <h4 class='card-title'>_{SHEDULE_BOARD}_ (_{HOURS}_)</h4>
  </div>
  <div class='card-body'>
    <div class='text-left'>
      <div class='d-flex flex-wrap' id='new-tasks'></div>
    </div>
    <br/>
    <div>
      <div class='d-flex bd-highlight' id='hour-grid'></div>
    </div>
  </div>
</div>

<script>
  let TASKS = JSON.parse('%TASKS%');
  let ADMINS = JSON.parse('%ADMINS%');
  var NO_RESPONSIBLE = '_{NO_RESPONSIBLE}_' || 'no responsible';

  let sheduleTable = new SheduleTable();
  sheduleTable.setAdmins(ADMINS);
  sheduleTable.generate();

  TASKS.forEach(task => sheduleTable.addTask(task));

</script>