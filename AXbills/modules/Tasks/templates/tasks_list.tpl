<ul class='nav nav-tabs'  id='tasks_tab'>
  <li class='nav-item'>
    <a data-toggle='tab' href='#t1' class='nav-link %LI_ACTIVE_1%'>_{UNFULFILLED_TASKS}_ <span class='badge badge-danger'>%U_COUNT%</span></a>
  </li>
  <li class='nav-item'>
    <a data-toggle='tab' href='#t2' class='nav-link %LI_ACTIVE_2%'>_{COMPLETED_TASKS}_ <span class='badge badge-success'>%C_COUNT%</span></a>
  </li>
  <li class='nav-item'>
    <a data-toggle='tab' href='#t3' class='nav-link %LI_ACTIVE_3%'>_{TASK_IN_WORK}_ <span class='badge badge-info'>%W_COUNT%</span></a>
  </li>
  <li class='nav-item'>
    <a data-toggle='tab' href='#t4' class='nav-link %LI_ACTIVE_4%'>_{TASK_IN_QUEUE}_ <span class='badge badge-light'>%Q_COUNT%</span></a>
  </li>
</ul>

<div class='tab-content'>
  <div id='t1' class='tab-pane fade %DIV_ACTIVE_1%'>%U_TASKS%</div>
  <div id='t2' class='tab-pane fade %DIV_ACTIVE_2%'>%C_TASKS%</div>
  <div id='t3' class='tab-pane fade %DIV_ACTIVE_3%'>%W_TASKS%</div>
  <div id='t4' class='tab-pane fade %DIV_ACTIVE_4%'>%Q_TASKS%</div>
</div>

<script>
jQuery(function(){
  jQuery("td").hover(function() {
    jQuery(this).css('cursor','pointer');
  }, function() {
    jQuery(this).css('cursor','auto');
  });


  jQuery("tr").on("click", "td", function() {
  	var table = jQuery(this).closest('table').DataTable();
  	table.search(this.innerText).draw();
  });
})
</script>