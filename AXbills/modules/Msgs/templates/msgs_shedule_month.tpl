<link rel='stylesheet' href='/styles/default/css/modules/msgs/msgs_shedule.css'>
<script src='/styles/default/js/msgs/shedule_table.js'></script>

<div class='card card-primary card-outline'>
  <div class='card-body'>
    <div class='form-group'>
      <div class='row'>
        <div class='col-md-6'>
          <form class='form form-inline' action=''>
            <input type='hidden' name='index' value='$index'/>
            <div class='row'>
              <div class='col-sm-12 col-md-4'>
                %TASK_STATUS_SELECT%
              </div>
              <div class='col-sm-12 col-md-4'>
                %ADMINS_SELECT%
              </div>
              <div class='col-sm-12 col-md-4'>
                <input type='submit' class='btn btn-primary' value='_{SHOW}_'/>
              </div>
            </div>
          </form>
        </div>
        <div class='col-md-6'>
          <a href='/admin/index.cgi?index=$index&DATE=%PREV_MONTH_DATE%'>
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
        </div>
      </div>
    </div>
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
  let sheduleMonthTable = new SheduleMonthTable();

  TASKS.forEach(task => sheduleMonthTable.addTask(task));

</script>