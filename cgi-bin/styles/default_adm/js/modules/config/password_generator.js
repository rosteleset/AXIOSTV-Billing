/**
 *
 * Created by Anykey and adrii on 12.08.2016.
 *
 */
'use strict';

var CASE_LOW  = 0;
var CASE_UPP  = 1;
var CASE_BOTH = 2;
var CASE_NO   = 3;

var CHARS_NUM  = 0;
var CHARS_SPE  = 1;
var CHARS_BOTH = 2;
var CHARS_NONE = 3;

var PASSWORD_CHARS_UPPERCASE = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];
var PASSWORD_CHARS_LOWERCASE = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"];

var PASSWORD_CHARS_SPECIAL = ["-", "_", "!", "&", "%", "@", "#", ":"];
var PASSWORD_CHARS_NUMERIC = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];


function getRadioValue(name) {
  var $radios = $('input[name="' + name + '"]');
  
  if ($radios.length > 0) {
    var $active_radio = $radios.filter(function (i, e) { return $(e).prop('checked') }).first();
    return $active_radio.val();
  }
  else {
    console.warn(name, ' not found');
  }
  
  return '';
}

function generatePassword(options) {
  
  var password = "";
  console.log(options);

  if (options.SYMBOLS) {
    var parsed_options = getPasswordParamsForSymbols(options.SYMBOLS);
    delete options.SYMBOLS;
    options.CASE  = parsed_options.CASE;
    options.CHARS = parsed_options.CHARS;
  }

  console.log(options);
  
  options.CASE  = options.CASE || 0;
  options.CHARS = options.CHARS || 0;
  
  // Do not allow situation when no case and no chars used
  if (options.CASE === options.CHARS && options.CASE === "3"){
    options.CASE = CASE_BOTH;
    options.CHARS = CHARS_SPE;
  }
  
  var array       = [];
  var check_rules = [];
  
  switch (+options.CASE) {
    case (CASE_UPP) :
      array = array.concat(PASSWORD_CHARS_UPPERCASE);
      check_rules.push(PASSWORD_CHARS_UPPERCASE.join(''));
      break;
    case (CASE_LOW) :
      array = array.concat(PASSWORD_CHARS_LOWERCASE);
      check_rules.push(PASSWORD_CHARS_LOWERCASE.join(''));
      break;
    case (CASE_BOTH):
      array = array.concat(PASSWORD_CHARS_UPPERCASE);
      array = array.concat(PASSWORD_CHARS_LOWERCASE);
      check_rules.push(PASSWORD_CHARS_LOWERCASE.join(''), PASSWORD_CHARS_UPPERCASE.join(''));
      break;
    case (CASE_NO):
      // Do not add any symbols
      break;
    default :
      console.log('WTF case: ' + options.CASE.valueOf());
  }
  
  switch (+options.CHARS) {
    case (CHARS_NUM) :
      array = array.concat(PASSWORD_CHARS_NUMERIC);
      check_rules.push(PASSWORD_CHARS_NUMERIC.join(''));
      break;
    case (CHARS_SPE) :
      array = array.concat(PASSWORD_CHARS_SPECIAL);
      check_rules.push(PASSWORD_CHARS_SPECIAL.join(''));
      break;
    case (CHARS_BOTH) :
      array = array.concat(PASSWORD_CHARS_SPECIAL);
      array = array.concat(PASSWORD_CHARS_NUMERIC);
      check_rules.push(PASSWORD_CHARS_SPECIAL.join(''), PASSWORD_CHARS_NUMERIC.join(''));
      break;
    case (CHARS_NONE) :
      break;
    default :
      console.log('WTF chars: ' + options.CHARS.valueOf());
  }
  
  
  
  for (var i = 0; i < options.LENGTH; i++) {
    var rchar = getRandom(array.length);
    password += array[rchar];
  }
  
  // Check password
  console.log(password);
  for (var i = 0; i < check_rules.length; i++) {
    if (!password.match(new RegExp('[' + check_rules[i] + ']+'))) {
      console.log('password fails, should regenerate', password, check_rules[i]);
      return generatePassword(options);
    }
  }
  
  return password;
}

function getPasswordParamsForSymbols(symbols) {
  // Check for each possible case|chars option in params assign according case|chars constant
  var result = {};
  
  var has_lowercase = symbols.match(new RegExp('[' + PASSWORD_CHARS_LOWERCASE.join() + ']+'));
  var has_uppercase = symbols.match(new RegExp('[' + PASSWORD_CHARS_UPPERCASE.join() + ']+'));
 
  if (has_lowercase && has_uppercase){
    result.CASE = CASE_BOTH;
  }
  else if (has_lowercase){
    result.CASE = CASE_LOW;
  }
  else if (has_uppercase){
    result.CASE = CASE_UPP;
  }
  else if (!has_lowercase && !has_lowercase){
    result.case = CASE_NO;
  }
  
  var has_numbers = symbols.match(new RegExp('[' + PASSWORD_CHARS_NUMERIC.join() + ']+'));
  var has_special = symbols.match(new RegExp('[' + PASSWORD_CHARS_SPECIAL.join() + ']+'));
  
  if (has_numbers && has_special){
    result.CHARS = CHARS_BOTH;
  }
  else if (has_numbers){
    result.CHARS = CHARS_NUM;
  }
  else if (has_special){
    result.CHARS = CHARS_SPE;
  }
  else {
    result.CHARS = CHARS_NONE
  }
  
  return result;
}

function getRandom(mx) {
  var mn = 0;
  mx     = mx - 1;
  return Math.floor(Math.random() * (mx - mn + 1)) + mn;
}
