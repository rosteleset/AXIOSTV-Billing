/**
 * Created by Anykey on 30.07.2015.
 *
 */
'use strict';
//Defaults
var chart = {
  title: {
    text: '',
    enabled: false
  }
};
/**
 * Main function
 */
window['initChart'] = function(chartCategories, chartLines, chartOptions) {
  
  if (typeof chartLines === 'undefined' || chartLines.length === 0) {
    console.log('You have not defined chartLines');
    showErrorToolTip('Nothing to show. Empty Chart Data array');
    return false;
  }
  
  var finalChart = makeChart(chartLines, chartCategories, chartOptions);
  
  $('#' + chartOptions['chart_id']).highcharts(finalChart);
};

function showErrorToolTip(text) {
  new ATooltip('<h1>' + text + '</h1>').setClass('danger').show();
}

function makeChart(chartLines, chartCategories, chartOptions) {
  chart.yAxis = [];
  //chart.zoomType = 'x';
  
  var params = [];
  var singleCompareMode = Number(chartOptions['compare_single']) || false;
  
  if (singleCompareMode) {
    chart.chart = {};
    chart.chart.type = 'column';

    chart.xAxis = { categories :  formNamedCategories('year').unshift('')  } ;
    chart.yAxis = {};

    chart.data = {};
    chart.title = {text: chartLines[0][0]};

    chart.data.columns = chartCategories;

    return chart;
  }
  else {
    try {
      chart.xAxis = {};
      chart.xAxis.categories = chartCategories;
    } finally {
      //do nothing
    }

    params = processLines(chartLines, chartOptions);
    chart.series = params;
  }

  chart.plotOptions = getPlotOptons();

  if (typeof (chartOptions['chart_period']) !== 'undefined') {

    switch (chartOptions['chart_period']) {
      case 'week_stats': //7 days
        chart.xAxis.categories = formNamedCategories('week');
        break;
      case 'month_stats': //31 days
        chart.xAxis.categories = formNumberArray(1, chartOptions['days_in_month'] || 31);
        break;
      case 'year_stats': //12 monthes
        chart.xAxis.categories = formNamedCategories('year');
        break;
      case 'day_stats': // 24 hours
        chart.xAxis.categories = formNamedCategories('day');
        break;
    }
  }

  return chart;
}

/**
 * parses each line of chartLines array
 * @param chartLines - 2-dimensional array containing series
 * @param chartOptions
 * @returns {*[]}
 */
function processLines(chartLines, chartOptions) {

  var seriesArr = [];

  chartLines.forEach(function (entry) {
    var ArrLength = chart.yAxis.length;
    var axisWidth = (ArrLength === 0) ? 0 : 1;

    chart.yAxis[ArrLength] = getAxis(axisWidth);

    seriesArr[ArrLength] = getSeries(
      entry[2], //Data Array
      entry[1], //Type
      ArrLength,//Which yAxis to put
      entry[0], //Name of series
      chartOptions
    );
  });

  return seriesArr;
}

function getAxis(width) {
  return {
    gridLineWidth: width,
    labels: {
      enabled: false
    },
    title: {
      enabled: false
    },
    floor: 0
  };
}
var columnAxis = -1;
var scatterTimeAxis = -1;
var lastPiePosition = 0;

function getSeries(chartDataArr, type, axNum, name, chartOptions) {
  var result = {};

  // By default don't show any lines and markers
  var objLineWidth = 0;
  var objMarker = {};
  
  // Default opacity to 'solid'
  var opacity = 1;

  // Show label for first category
  chart.yAxis[axNum].labels.enabled = (chart.yAxis.length === 1);

  // Check for additional parameters
  var extraData = getExtraData(type);
  if (extraData) type = type.split(",")[0].trim();

  // Array of xData for storing converted value
  var dataArr = [];
  
  switch (type) {
    case 'line':
      objLineWidth = 4;
      objMarker = {radius: 4};
      opacity = 1;
      dataArr = forceNumeric(chartDataArr);
      break;
    case 'scatter':
      chart.xAxis.categories = formNamedCategories('month');
      opacity = 0.7;
      chart.yAxis[0].startOnTick = true;

      if (extraData === 'time') {

        if (scatterTimeAxis === -1) {
          scatterTimeAxis = axNum;
        }
        axNum = scatterTimeAxis;
        chart.yAxis[axNum] = {
          type: 'linear',
          labels: {
            formatter: function () {
              var seconds = (this.value / 1000) | 0;
              this.value -= seconds * 1000;

              var minutes = (seconds / 60) | 0;
              seconds -= minutes * 60;

              var hours = (minutes / 60) | 0;
              minutes -= hours * 60;
              return getPrettyTime(hours, minutes, seconds);
            },
            min: 1000,
            max: getMilliseconds(23, 59, 59),
            startOnTick: false,
            showFirstLabel: false
          },
          title: {
            text: 'Time',
            enabled: true
          }
        };
        chart.tooltip = {
          formatter: function () {
            return Highcharts.dateFormat('%H:%M:%S', this.y) +
              '. Date is: ' + Highcharts.dateFormat('%Y/%m/%d', this.x);
          },
          xDateFormat: '%Y-%m-%d',
          shared: true
        };

        chart.xAxis = {
          type: 'linear',
          labels: {
            formatter: function () {
              return Highcharts.dateFormat('%Y/%m/%d', this.value);
            },
            startOnTick: true,
            showFirstLabel: true

          }
        };
        dataArr = parseDateTime(chartDataArr);
        //console.log(dataArr);
      }
      else {
        chart.xAxis = {type: 'linear'};
        dataArr = filterForZeroValues(forceNumeric(chartDataArr));
      }
      break;
    case 'column':
      if (columnAxis === -1) {
        columnAxis = axNum;
      }
      axNum = columnAxis;
      opacity = 1;

      dataArr = forceNumeric(chartDataArr);
      result.stackLabels = {
        enabled: true,
        style: {
          fontWeight: 'bold',
          color: (Highcharts.theme && Highcharts.theme.textColor) || 'gray'
        }
      };
      break;
    case 'pie':
      opacity = 1;

      chart.tooltip = {
        pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
      };

      lastPiePosition += 100 / 4 + 25;
      result.center = [lastPiePosition, 25];
      result.size = 100;
      result.showInLegend = false;
      result.dataLabels = {
        enabled: false
      };

      dataArr = arrayToObjectsArray(forceNumeric(chartDataArr));

      break;
    default:
      chart.title.text = 'Unknown series type given';
      dataArr = forceNumeric(chartDataArr);
      break;
  }

  if (chartDataArr.length > 1000) {
    result.turboThreshold = 0;
  }

  if (typeof (chartPeriod) !== 'undefined') {
    switch (chartPeriod) {
      case 'week_stats': //7 days
        dataArr = forceLength(dataArr, 7);
        break;
      case 'month_stats': //31 days
        dataArr = forceLength(dataArr, chartOptions['days_in_month'] || 31);
        break;
      case 'year_stats': //12 monthes
        dataArr = forceLength(dataArr, 12);
        break;
      case 'day_stats': // 24 hours
        dataArr = forceLength(dataArr, 24);
        break;
    }
  }


  result.data = dataArr;
  result.type = type;
  result.yAxis = axNum;
  result.name = name;
  result.color = aColorPalette.getNextColorRGBA(opacity);
  result.lineWidth = objLineWidth;
  result.marker = objMarker;

  return result;
}

function forceNumeric(array) {
  var arrResult = [];
  if (typeof (array[0]) !== Number)
    array.forEach(function (entry) {
      arrResult[arrResult.length] = parseFloat(entry);
    });
  return arrResult;
}

function forceString(array) {
  var arrResult = [];
  if (typeof (array[0]) !== Number)
    array.forEach(function (entry) {
      arrResult[arrResult.length] = String(entry);
    });
  return arrResult;
}


function getMilliseconds(hours, minutes, seconds) {
  var secondsInMinute = 60;
  var minutesInHour = 60;

  var result = seconds;
  result += minutes * secondsInMinute;
  result += hours * minutesInHour * secondsInMinute;

  return result * 1000;
}

function getStringMilliseconds(string) {
  var arr = string.split(":");
  return getMilliseconds(parseInt(arr[0]), parseInt(arr[1]), parseInt(arr[2]));
}

function removeFirstItem(array) {
  var result = array;
  result.shift();
  return result;
}

function forceDate(array, time) {
  var arrResult = [];

  switch (time) {
    case true:
      array.forEach(function (entry) {
        var arrDateTime = entry.split(":");
        if (arrDateTime.length === 1) return ['404', '404', '404', '404', '404', '404', '404', '404'];
        arrResult[arrResult.length] = getMilliseconds(parseInt(arrDateTime[0]), parseInt(arrDateTime[1]), parseInt(arrDateTime[2]));
      });
      break;

    case false:
      array.forEach(function (entry) {
        arrResult[arrResult.length] = Date.parse(entry);
      });
      break;
  }
  return arrResult;
}

function filterForZeroValues(array) {
  var arrResult = [];
  array.forEach(function (entry) {
    if (entry !== 0 || entry !== '0') arrResult[arrResult.length] = entry;
  });
  return arrResult;
}

function getPlotOptons() {
  return {
    column: {
      stacking: 'normal',
      dataLabels: {
        enabled: true,
        color: (Highcharts.theme && Highcharts.theme.dataLabelsColor) || 'white',
        style: {
          textShadow: '0 0 3px black'
        },
        formatter: function () {
          var val = this.y;
          if (val === 0) {
            return '';
          }
          return val;
        }
      }
    },
    scatter: {
      marker: {
        radius: 5,
        states: {
          hover: {
            enabled: true,
            lineColor: 'rgb(100,100,100)'
          }
        }
      },
      states: {
        hover: {
          marker: {
            enabled: false
          }
        }
      },
      tooltip: {
        xDateFormat: '%Y-%m-%d'
      }
    },
    pie: {
      allowPointSelect: true,
      cursor: 'pointer',
      dataLabels: {
        enabled: true,
        format: '<b>{point.name}</b>: {point.percentage:.1f} %',
        style: {
          color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
        }
      }
    }
  }
}

/**
 * return extraData if found. Else returns false
 * @param type
 * @returns {*}
 */
function getExtraData(type) {
  var array = type.split(",");
  if (array.length > 1) {
    return array[1];
  }
  return false;
}

function formNumberArray(lowest, highest) {
  var result = [];
  for (var i = lowest; i <= highest; i++) {
    result[result.length] = i;
  }
  return result;
}

function formNamedCategories(type) {
  switch (type) {
    case 'week':
      return moment.weekdaysMin();
      break;
    case 'year':
      return moment.monthsShort();
      break;
    case 'day':
      var result = [];
      for (var i = 0; i <= 24; i++)
        result[result.length] = getPrettyTime(i, 0, 0);
      return result;
      break;
  }
  return '';
}

function clearCachedValues() {
  chart = {
    title: {
      text: '',
      enabled: false
    }
  };

  currColor = 0;
}

function arrayToObjectsArray(array) {
  var result = [];
  array.forEach(function (entry) {
    result[result.length] = {
      y: entry
    };
  });
  return result;
}

function parseDateTime(array) {
  var result = [];
  array = filterForZeroValues(array);
  if (array.length > 0)
    array.forEach(function (entry) {
      var arr = entry.split(" ");
      //console.log(arr[0]);
      //var dateArr = arr[0].split("-");
      var date = Date.parse(arr[0]);
      var time = getStringMilliseconds(arr[1]);

      result[result.length] = {x: date, y: time};
    });
  return result;
}

function getStringDate(value) {
  var date = new Date(value);
  return date.getDate;
}

/**
 * Returns two-digits time 1,2,3 -> 01:02:03
 * @param hours
 * @param minutes
 * @param seconds
 * @returns {string}
 */
function getPrettyTime(hours, minutes, seconds) {
  return toPrettyFormat(hours) + ":" +
    toPrettyFormat(minutes) + ":" +
    toPrettyFormat(seconds);
}

function toPrettyFormat(integer) {
  var parsedInt = parseInt(integer);
  return (parsedInt < 10) ? "0" + parsedInt : parsedInt;
}

function forceLength(array, desiredLength) {
  if (array.length < desiredLength) {
    for (var i = array.length; i < desiredLength; i++) {
      array[i] = 0;
    }
  }
  return array;
}