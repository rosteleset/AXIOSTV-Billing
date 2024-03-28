"use strict";
/**
 * Created by Anykey on 02.09.2015.
 */
var KEYCODE_ENTER = 13;

function keyDown(e) {
  switch (e.keyCode) {
    case KEYCODE_ENTER:
      if (e.ctrlKey) {
        clickButton('go');
      }
      else {
        // #S9801. Should check for textarea
        var target = e.target.localName;
        if (target === 'textarea') return;

        clickButton('save');
        clickButton('search'); //modal-search
      }
  }
}

function clickButton(id) {
  var btn = document.getElementById(id);
  if (typeof (btn) !== 'undefined' && btn !== null) btn.click();
}


//set keyboard listener
$(document).ready(function () {
  
  $('body').on('keydown', function (event) {
    keyDown(event);
  });
  
});