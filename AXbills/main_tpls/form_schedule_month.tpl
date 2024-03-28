<link rel='stylesheet' type='text/css' href='/styles/default/css/schedule.css'>
<script src='/styles/default/js/schedule.js'></script>

<div class='card card-primary card-outline'>
  <div class='card-header'>
    <h4 class='card-title'>
      <a href='/admin/index.cgi?index=%index%&DATE=%PREV_MONTH_DATE%'>
        <button type='submit' class='btn btn-default btn-sm'>
          <span class='fa fa-arrow-left' aria-hidden='true'></span>
        </button>
      </a>
      <label class='control-label' style='margin: 0 20px'>%MONTH_NAME% %YEAR%</label>
      <a href='/admin/index.cgi?index=$index&DATE=%NEXT_MONTH_DATE%'>
        <button type='submit' class='btn btn-default btn-sm'>
          <span class='fa fa-arrow-right' aria-hidden='true'></span>
        </button>
      </a>
    </h4>
  </div>
  <div class='card-body p-2'>
    %FILTERS%
    <div class='d-flex flex-wrap' id='new-tasks'>
    </div>
  </div>
</div>


%TABLE%

<script>
  var table = jQuery('table.work-table-month');
  var table_tds = table.find('td');

  table_tds.find('a.weekday').parent().addClass('bg-danger');
  table_tds.find('span.disabled').parent().addClass('active');

  table_tds.find('a.mday').parent().addClass('dayCell');

  let TASKS = JSON.parse('%TASKS%');
  var NO_RESPONSIBLE = '_{NO_RESPONSIBLE}_' || 'no responsible';
  let scheduleMonthTable = new ScheduleMonthTable();

  console.log(TASKS)
  TASKS.forEach(task => scheduleMonthTable.addTask(task));
</script>