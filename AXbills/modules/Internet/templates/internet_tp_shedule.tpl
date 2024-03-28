<div class='row text-left'>
  <div class='col-md-6'>
    %TP_SEL%
  </div>
  <div class='col-md-6' id='div1'>
    <button class='btn btn-default' id='btn1'><i class='far fa-clock'></i></button>
  </div>
  <div class='col-md-4' id='div2' style='display: none;'>
    %DATE_SEL%
  </div>
  <div class='col-md-2' id='div3' style='display: none;'>
    <button class='btn btn-default text-danger' id='btn2'><i class='fa fa-ban'></i></button>
  </div>
</div>


<script>
  jQuery('#btn1').click(function() {
    jQuery('#div1').fadeOut(200);
    jQuery('#div2').delay(201).fadeIn(300);
    jQuery('#div3').delay(201).fadeIn(300);
  });

  jQuery('#btn2').click(function() {
    jQuery('#div3').fadeOut(200);
    jQuery('#div2').fadeOut(200);
    jQuery('#div1').delay(201).fadeIn(300);
    jQuery('#TP_SHEDULE').val('0000-00-00');
  });
</script>
