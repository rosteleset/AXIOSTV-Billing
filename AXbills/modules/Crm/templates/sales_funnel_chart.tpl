<div class='col-md-12 col-lg-12 main_funnel' >
  <div class='card box-primary '>
    <div class='card-header with-border text-center'><h4>_{SALES_FUNNEL}_</h4></div>
    <div class='card-body'>
      <div id="chartdiv"></div>
    </div>
  </div>
</div>

<style>
  .main_funnel {
    padding: 0;
  }
  #chartdiv {
    width: auto;
    height: 500px;
    background-color: white;
  }
</style>
<script src="/styles/default/js/charts/amcharts/amcharts.js"></script>
<script src="/styles/default/js/charts/amcharts/funnel.js"></script>
<script src="/styles/default/js/charts/amcharts/light.js"></script>
<script>
  var chart = AmCharts.makeChart( "chartdiv", {
    "type": "funnel",
    "theme": "light",
    "dataProvider": %DATA%,
    "titleField": "title",
    "labelPosition": "center",
    "funnelAlpha": 0.9,
    "valueField": "value",
    "startX": 0,
    "neckWidth": "30%",
    "startAlpha": 0,
    "outlineThickness": 3,
    "neckHeight": "0%",
    "balloonText": "<b>[[title]]: [[value]]</b>",
    "valueRepresents":"area",
  } );
</script>

