$(function () {
//Sets logic for User and Guest form tabs
  $('#login-form-link').click(function (e) {
    $("#login-form").delay(100).fadeIn(100);
    $("#guest-form").fadeOut(100);
    $('#guest-form-link').removeClass('active');
    $(this).addClass('active');
    e.preventDefault();
  });
  
  $('#guest-form-link').click(function (e) {
    $("#guest-form").delay(100).fadeIn(100);
    $("#login-form").fadeOut(100);
    $('#login-form-link').removeClass('active');
    $(this).addClass('active');
    e.preventDefault();
  });
  
  $('#logout').click(function (e) {
    e.preventDefault();
    aAuthentificator.logout();
  });
  $('#link').click(function (e) {
    $('#UserUrl').html('');
  });
  $('#guest-submit').on('click', function () {
    $.cookie('hotspot_user_id', mac, cookieOpts);
    $.cookie('hotspot_user_url', userURL, cookieOpts);
  });
  
  $('#buy_card_link').on('click', function (e) {
    $.cookie('hotspot_user_id', mac, cookieOpts);
    $.cookie('hotspot_user_url', userURL, cookieOpts);
    if (DEBUG)
      alert('Writed cookies \'mac\' : ' + mac + ', \'url\' : ' + userURL);
    // e.preventDefault();
  });

// Login form processing
  var loginForm = $('#login-form');
  
  loginForm.submit(function (e) {
    e.preventDefault();
    // Show a loading modal
    showModal();
    
    var pass     = loginForm.find('input[name=password]').val();
    var username = loginForm.find('input[name=username]').val();
    var remember = loginForm.find('input[name=remember]').prop('checked');
    var usertype = loginForm.find('input[name=usertype]').val();
    var userURL  = loginForm.find('input[name=userurl]').val();
    
    if (remember){
      jQuery.cookie('hotspot_username', username);
      jQuery.cookie('hotspot_password', pass);
    }
    
    aAuthentificator.clear();
    
    aAuthentificator
        .setUsername(username)
        .setPassword(pass)
        .setUserType(usertype)
        .setRemember(remember)
        .setUserURL(userURL)
        .logon();
  });
  
  $('#loading').on('hidden.bs.modal', function () {
    $("#status").html("Please wait while your device is being authorized. <img src='/styles/default/img/ajax-loader.gif'/>");
  });
  
  // Try to fill remembered values
  loginForm.find('input[name=password]').val(jQuery.cookie('hotspot_password') || '');
  loginForm.find('input[name=username]').val(jQuery.cookie('hotspot_username') || '');
  
  moment.locale(lang["MOMENT_LOCALE"]);
  doFastLogin();
  
});

function showModal() {
  $('#loading').modal('show');
}

function hideModal() {
  $('#loading').modal('hide');
}

var aAuthentificator = new AAuthentificator(SELF_URL);
function AAuthentificator(billingURL) {
  var self = this;
  
  this.URL      = billingURL;
  this.username = '';
  this.password = '';
  this.mac      = mac;
  this.remember = '';
  this.userType = '';
  this.userURL  = '';
  this.apmac    = ap;
  this.timeout  = 10000;
  
  this.clear = function () {
    this.username = '';
    this.password = '';
    this.mac      = mac;
    this.remember = '';
    this.userType = '';
    this.userURL  = '';
    this.apmac    = ap;
  };
  
  this.logon = function () {
    console.log('Logon');
    if ((this.usertype == 'Guest') && (this.username == '')) {
      $("#status").html('Guest mode disabled');
      setTimeout(hideModal, 2000);
    }
    else {
      //send billing auth request
      var parameters = $.param({
        operation_type: 'login',
        username      : this.username,
        password      : this.password,
        id            : this.mac,
        ip            : ip,
        ap            : this.apmac,
        url           : userURL
      });
      // var get_params = "?id=" + this.mac + "&ap=" + this.apmac;
      
      if (!DEBUG)
        $.get(self.URL, parameters)
            .done(console.log('Auth: logon done'));
      else {
        $('#debug').load(self.URL + '?' + parameters);
        alert('finished. close modal and see response in footer');
      }
      //.done(console.log('Auth: logon done'));
    }
  };
  
  this.logout = function () {
    //aStatusUpdater.toggle();
    $('#status').html('Wait a moment...');
    showModal();
    
    //send billing auth request
    var parameters = $.param({
      operation_type: 'logout',
      username      : this.username,
      ap            : ap,
      id            : mac
    });// +
    // '&id=' + mac; //mac is URL encoded if in param
    
    $.get(self.URL + '?' + parameters);
    //.done(console.log('Auth: logoff done'));
  };
  
  this.updateStatus = function (JSONResponse) {
    console.log('Update status');
    console.log(JSONResponse);
    
    var statusDiv = $('#status');
    
    var modalTimeout = 3000;
    try {
      $(function () {
        switch (JSONResponse.status) {
          case '0': //OK
            console.log('Auth: OK');
            //redirect to status page
            statusDiv.html(JSONResponse.message);
              
            // Save values we'll cannot retrieve later
            if (JSONResponse.timeleft) {
              jQuery.cookie('hotspot_timeleft', JSONResponse.timeleft, cookieOpts);
              
              // Save current time to count the difference later
              var timestamp = Math.floor(Date.now() / 1000);
              jQuery.cookie('hotspot_login_time', timestamp, cookieOpts);
              
            }
            if (JSONResponse.speedDown) {
              jQuery.cookie('hotspot_speed_down', JSONResponse.speedDown, cookieOpts);
            }
            if (JSONResponse.speedUp) {
              jQuery.cookie('hotspot_speed_up', JSONResponse.speedUp, cookieOpts);
            }
              
              
            //self.updateContent(JSONResponse);
            setTimeout('location.reload()', 1000);
            break;
          case '1': //Login error
            console.log('Auth: error');
            statusDiv.html(JSONResponse.message);
            modalTimeout = 5000;
            break;
          case '2': //Update
            console.log('Updating Content');
            self.updateContent(JSONResponse);
            break;
          case '-1': //Unauthorized
            console.log('Auth: Unauthorized');
            statusDiv.html(JSONResponse.message);
            modalTimeout = 5000;
            setTimeout('location.reload()', modalTimeout + 1500);
            break;
          default :
            alert('Unknown status in response: ' + JSONResponse.status);
            break;
        }
        setTimeout(hideModal, modalTimeout);
        
      });
    } catch (e) {
      alert(e);
    }
  };
  
  this.updateContent = function (json) {
    console.log("updateContent");
    $('#status-content').html(getStatusForm(json));
  };
  
  this.requestUpdate = function () {
    $.get(self.URL + '?operation_type=update&id=' + this.mac + '&ap=' + this.ap);
  };
  
  this.setUsername = function (value) {
    this.username = value;
    return this;
  };
  
  this.setPassword = function (value) {
    this.password = value;
    return this;
  };
  
  this.setRemember = function (value) {
    this.remember = value;
    return this;
  };
  
  this.setUserType       = function (value) {
    this.userType = value;
    return this;
  };
  
  this.setUserURL        = function (value) {
    this.userURL = value;
    return this;
  };
  
  this.setMac            = function (value) {
    this.mac = value;
    return this;
  };
  
  this.setApMac          = function (value) {
    this.apmac = value;
    return this;
  };
  
  this.setRefreshTimeout = function (seconds) {
    this.timeout = seconds * 1000;
    return this;
  };
  
  this.getRefreshTimeout = function () {
    return this.timeout;
  };
}


//Подписи для значений. Ключи должны соответсвовать ключам приходящего обьекта
var labels = {
  userIP : lang["IP_ADDRESS"],
  userMAC: lang["MAC"],
  
  speedDown: lang["DOWNLOAD_SPEED"] + ', kBps',
  speedUp  : lang["UPLOAD_SPEED"] + ', kBps',
  
  signal     : lang["SIGNAL"],
  transmitted: lang["TRANSMITTED"] + ', kB',
  received   : lang["RECEIVED"] + ', kB',
  
  timeleft: lang["TIMELEFT"],
};
var lines  = {};


function getStatusForm(object) {
  
  // Retrieve info from cookies
  var timeleft_in_cookies = jQuery.cookie('hotspot_timeleft') || '';
  var login_time          = jQuery.cookie('hotspot_login_time') || '';
  var speed_down          = jQuery.cookie('hotspot_speed_down') || '';
  var speed_up            = jQuery.cookie('hotspot_speed_up') || '';
  
  object.timeleft  = timeleft_in_cookies;
  object.speedDown = speed_down;
  object.speedUp   = speed_up;
  
  // Adding new properties
  for (var incomeObjectkey in object) {
    if (!object.hasOwnProperty(incomeObjectkey) || object[incomeObjectkey] === '') continue;
    
    if (labels[incomeObjectkey]) {
      lines[incomeObjectkey] = object[incomeObjectkey];
    }
    else {
      console.warn("No label for : " + incomeObjectkey);
    }
  }
  
  // Parse numeric values
  if (object.timeleft) {
    var timestamp = Math.floor(Date.now() / 1000);
    var time_difference = (timestamp - login_time) / 60;
    var timeleft = Math.round(object.timeleft / 60 - time_difference);
    
    //if (timeleft <= 0) timeleft = 0;
    if (timeleft <= 0) return aAuthentificator.logout();
    
    lines.timeleft = moment.duration(timeleft, 'minutes').humanize();
  }
  if (object.speedDown) lines.speedDown = Math.round(parseInt(lines.speedDown));
  if (object.speedUp) lines.speedUp = Math.round(parseInt(lines.speedUp));
  
  if (object.transmitted) lines.transmitted = Math.round(parseInt(lines.transmitted) / 1024);
  if (object.received) lines.received = Math.round(parseInt(lines.received) / 1024);
  
  // Make table
  var table = '';
  for (var key in lines) {
    if (!lines.hasOwnProperty(key)) continue;
    table += '<tr><td>' + labels[key] + '</td><td>' + lines[key] + '</td></tr>';
  }
  
  var userUrl = userURL;
  
  var result = '';
  
  if (userUrl != '') {
    result += '<div id="user_url" class="col-md-4 col-md-offset-4">' +
        '<div class="alert alert-warning" role="alert">' +
        '<div id="user_url_link">' +
        '<strong>Info: </strong>' + lang["USER_LINK_LABEL"] + ' </br><a id="link" href="' + userUrl + '" class="alert-link" target="_blank">' + userUrl + '</a>' +
        '</div>' +
        '</div>' +
        '</div>';
  }
  
  result += '<div class="col-md-4 col-md-offset-4">'
      + '<div class="card box-success">'
      + '<div class="card-header with-border logged-user">'
      + '</div>'
      + '<div class="table-logged-user">'
      + '</div>'
      + '<table class="table table-bordered table-logged-user">'
      + '<tbody>'
      
      + table
      
      + '</tbody>'
      + '</table>'
      + '</div>'
      + '</div>'
      + '<div class="col-sm-4 col-sm-offset-4">'
      + '<a href="#" id="logout" class="form-control btn btn-ls btn-danger">' + lang["HANGUP"] + '</a>'
      + '</div>'
      + '<script>'
      + '$("#logout").click(function (e) {'
      + 'e.preventDefault();'
      + 'aAuthentificator.logout();'
      + '});'
      + '</script>';
  
  setTimeout(aAuthentificator.requestUpdate, aAuthentificator.getRefreshTimeout());
  
  return result;
}