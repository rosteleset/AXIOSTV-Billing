<link rel='stylesheet' type='text/css' href='/styles/default/css/schedule.css'>
<script src='/styles/default/js/schedule.js'></script>

<div class='card card-primary card-outline center-block'>
  <div class='card-header with-border text-right'>
    <h4 class='card-title'>_{SCHEDULE_BOARD}_ (_{HOURS}_)</h4>
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
  var _SAVE = '_{SAVE}_' || 'Save';
  var _DURATION = '_{DURATION}_' || 'Duration';
  var _SHORT_HOURS = '_{SHORT_HOURS}_' || 'h';
  var _SHORT_MINUTES = '_{SHORT_MINUTES}_' || 'min';

  var scheduleTable = new ScheduleTable();
  scheduleTable.setAdmins(ADMINS);
  scheduleTable.generate();

  TASKS.forEach(task => scheduleTable.addTask(task));
</script>