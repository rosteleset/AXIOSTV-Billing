!function($) {
  "use strict";
  var EasyPieChart = function() {};
  EasyPieChart.prototype.init = function() {
    //initializing various types of easy pie charts
    $('.easy-pie-chart').easyPieChart({
      barColor : function(percentage){
        if ( percentage <= 0 ) {
          return '#00c0ef';
          //return '#3c8dbc';
        }
        else if (percentage <= 50) {
          return '#00a65a';
        }
        else if (percentage <= 80) {
          return '#f39c12';
        }
        else {
          return '#f56954';
        }
        return '#00a65a';
      },
      lineWidth: 16,
      lineCap : 'butt',
      scaleColor: false,
      animate: 2000,
      size: 120,
      trackColor: '#f0f0f0',
      onStep: function(from, to, percent) {
        $(this.el).find('.percent').text(Math.round(percent));
      }
    });
  },
  //init
  $.EasyPieChart = new EasyPieChart, $.EasyPieChart.Constructor = EasyPieChart
}(window.jQuery),

//initializing
function($) {
  "use strict";
  $.EasyPieChart.init()
}(window.jQuery);
