if (!Date.now) {
  Date.now = function() { return new Date().getTime(); }
}

function Stopwatch(display) {
  this.running = null;
  this.display = display;
  this.reset();
  this.print(this.times);
}
Stopwatch.prototype = {
  reset    : function () {
    this.times = [2, 0, 0, 0];
  },
  start    : function () {
    if (!this.time) this.time = performance.now();
    if (!this.running) {
      this.running = setInterval(this.step.bind(this), 1000);
    }
  },
  stop     : function () {
    if (this.running !== null) {
      clearInterval(this.running);
      this.running = null;
    }
    this.time = null;
  },
  restart  : function () {
    if (!this.time) this.time = performance.now();
    this.start();
    this.reset();
  },
  step     : function () {
    if (this.running === null) return;

    var timestamp = Date.now();

    this.calculate(timestamp);
    this.time = timestamp;
    this.print();
  },
  calculate: function (timestamp) {
    var diff = timestamp - this.time;
    // Hundredths of a second are 100 ms
    this.times[2] += diff / 10;
    // Seconds are 100 hundredths of a second
    if (this.times[2] >= 100) {
      this.times[1] += 1;
      this.times[2] -= 100;
    }
    // Minutes are 60 seconds
    if (this.times[1] >= 60) {
      this.times[0] += 1;
      this.times[1] -= 60;
    }

    if (this.times[0] >= 60) {
      this.times[3] += 1;
      this.times[0] -= 60;
    }
  },
  print    : function () {
    this.display.attr('value', this.format(this.times));
  },
  format   : function (times) {
    return pad0(times[3], 2) + ':' + pad0(times[0], 2) + ':'
        + pad0(times[1], 2);
  }
};

function pad0(value, count) {
  var result = value.toString();
  for (; result.length < count; --count)
    result = '0' + result;
  return result;
}

jQuery(function(){
  'use strict';
  var stopwatch = new Stopwatch(
      jQuery('#RUN_TIME')
  );

  var func_btn     = jQuery('#func_btn');
  var func_icon    = jQuery('#func_icon');
  var func_rst_btn = jQuery('#func_rst');

  function startTimer(){
    stopwatch.start();
    func_btn.attr('run_status', '1');
    func_icon.attr('class', 'fa fa-pause');
  }
  function pauseTimer(){
    stopwatch.stop();
    func_btn.attr('run_status', '0');
    func_icon.attr('class', 'fa fa-play');
  }

  function toggleTimer() {
    if (func_btn.attr('run_status') === '0') {
      startTimer();
    }
    else if (func_btn.attr('run_status') === '1') {
      pauseTimer();
    }
  }

  func_btn.click(toggleTimer);
  func_rst_btn.click(function () {
    if (func_btn.attr('run_status') === '0') {
      startTimer();
    }

    stopwatch.restart();
  });

  startTimer();
});
