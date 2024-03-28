<button type='button' class='btn btn-primary' id='show_filter'>Фильтр</button>

<div id='filter_wrapper' style="display:none">
  <div class='filter-body' >
    <div class='row'>
      Много разных фильтров<br><br><br><br><br><br>
    </div>
  </div>
  <div class='filter-footer'>
    <button type='button' class='btn btn-primary' id='hide_filter'>Закрыть</button>
  </div>
</div>

<script type="text/javascript">
  jQuery('#show_filter').click(function() {
    jQuery('#show_filter').fadeOut(200);
    jQuery('#filter_wrapper').delay(201).fadeIn(300);
  });

  jQuery('#hide_filter').click(function() {
    jQuery('#filter_wrapper').fadeOut(200);
    jQuery('#show_filter').delay(201).fadeIn(300);
  });
</script>