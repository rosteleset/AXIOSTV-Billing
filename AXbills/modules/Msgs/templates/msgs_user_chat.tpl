<style>
  #fixed-form-container {
    position: fixed;
    bottom: 0px;
    right: 3%;
    width: 94%;
    text-align: right;
    margin: 5px;
    opacity: 0.99;
    z-index: 2000;
  }

  #fixed-form-container .button_blue {
    font-size: 1.25em;
    cursor: pointer;
    margin-left: auto;
    margin-right: auto;
    border: 2px solid #0e94f6;
    -moz-border-radius: 5px;
    -webkit-border-radius: 5px;
    border-radius: 5px;
    padding: 5px 20px 5px 20px;
    background-color: #0e94f6;
    color: #fff;
    display: inline-block;
    text-align: center;
    text-decoration: none;
    -webkit-box-shadow: 4px 0px 5px 0px rgba(0, 0, 0, 0.3);
    -moz-box-shadow: 4px 0px 5px 0px rgba(0, 0, 0, 0.3);
    box-shadow: 4px 0px 5px 0px rgba(0, 0, 0, 0.3);

  }

  #fixed-form-container .b_green {
    font-size: 1.25em;
    cursor: pointer;
    margin-left: auto;
    margin-right: auto;
    border: 2px solid #00e055;
    -moz-border-radius: 5px;
    -webkit-border-radius: 5px;
    border-radius: 5px;
    padding: 5px 20px 5px 20px;
    background-color: #00e055;
    color: #fff;
    display: inline-block;
    text-align: center;
    text-decoration: none;
    -webkit-box-shadow: 4px 0px 5px 0px rgba(0, 0, 0, 0.3);
    -moz-box-shadow: 4px 0px 5px 0px rgba(0, 0, 0, 0.3);
    box-shadow: 4px 0px 5px 0px rgba(0, 0, 0, 0.3);

  }

  #fixed-form-container .body {
    background-color: #fff;
    border-radius: 5px;
    border: 2px solid #49c;
    margin-bottom: 16px;
    /*padding: 10px;*/
    -webkit-box-shadow: 4px 4px 5px 0px rgba(0, 0, 0, 0.3);
    -moz-box-shadow: 4px 4px 5px 0px rgba(0, 0, 0, 0.3);
    box-shadow: 4px 4px 5px 0px rgba(0, 0, 0, 0.3);
  }

  @media only screen and (min-width: 768px) {
    #fixed-form-container #open {
      margin: 0;

    }

    #fixed-form-container {
      right: 50px;
      width: 390px;
      text-align: right;
    }

    #fixed-form-container .body {
      /*padding: 30px;*/
      border-radius: 0px 5px 5px 5px;
    }
  }

  .chat_data {
    overflow-y: auto;
    height: 300px;
  }

  .form-control {
    resize: none;
    overflow: hidden;
  }

  .bubble {
    position: relative;
    width: 90%;
    padding: 8px;
    float: left;
    display: inline-block;
    vertical-align: middle;
    word-wrap: break-word;
    font-size: 13px;
    color: #fff;
    text-align: left;
    background-color: #1289fe;
    -webkit-border-radius: 5px;
    -moz-border-radius: 5px;
    border-radius: 5px;
    -webkit-box-shadow: 2px 2px 10px 0px rgba(97, 97, 97, 0.5);
    -moz-box-shadow: 2px 2px 10px 0px rgba(97, 97, 97, 0.5);
    box-shadow: 2px 2px 10px 0px rgba(97, 97, 97, 0.5);
  }

  .bubble2 {
    position: relative;
    width: 90%;
    padding: 8px;
    float: right;
    text-align: right;
    display: inline-block;
    vertical-align: middle;
    font-size: 13px;
    word-wrap: break-word;
    color: #333;
    background-color: #e5e5ea;
    -webkit-border-radius: 5px;
    -moz-border-radius: 5px;
    border-radius: 5px;
    -webkit-box-shadow: 2px 2px 10px 0px rgba(97, 97, 97, 0.5);
    -moz-box-shadow: 2px 2px 10px 0px rgba(97, 97, 97, 0.5);
    box-shadow: 2px 2px 10px 0px rgba(97, 97, 97, 0.5);
  }
</style>

<section id="fixed-form-container">
  <div id="open" class="btn button_blue">
    _{CHAT}_
    <span id="Chat_count" class="label alert-danger ch_count" style="display: none">0</span>
    <audio preload="auto">
      <source src="/styles/default/bb2_new.mp3" type="audio/mpeg">
    </audio>
  </div>
  <div class="body panel panel-default">
    <div class="panel-body chat_data"></div>
    <div class="panel-footer">
      <div class="input-group">
                <textarea id="chat_message" rows="1" cols="10" type="text" class="form-control" name='MESSAGE'
                          value='%MESSAGE%' placeholder="Type Message ..."></textarea>
        <span class="input-group-btn">
                <button id="btn-subm" class="btn" type="button"
                        style="color: white; background-color: #0e94f6">Send</button>
              </span>
      </div>
    </div>
  </div>
</section>
<script src="/styles/default/js/jquery-ui.min.js"></script>
<script>
  var stop_scroll = 0;
  var mytimeout;

  jQuery("#fixed-form-container .panel").hide();
  jQuery("#fixed-form-container #open").click(function () {
    jQuery(this).next("#fixed-form-container div").slideToggle(400);
    jQuery(this).toggleClass("expanded");
    jQuery("#open").removeClass('b_green');
    jQuery(".ch_count").hide();
    jQuery('#fixed-form-container').css('bottom', '0px');

    change_read();
  });
  update();
  jQuery(function () {
    setInterval(update, 3000);
    jQuery('.chat_data').scroll(function () {
      stop_scroll = 1;
      clearTimeout(mytimeout);
      mytimeout = setTimeout(function () {
        stop_scroll = 0;
      }, 3000);
    });
  });
  jQuery('#btn-subm').click(function () {
    var text = jQuery('#chat_message').val();
    jQuery.post('$SELF_URL', 'header=2&qindex=%F_INDEX%&ADD=1&UID=%UID%&MSG_ID=%NUM_TICKET%&MESSAGE=' + text, function () {
      jQuery('#chat_message').val('');
      update();
    });
  });

  function update() {
    jQuery.post('$SELF_URL', 'header=2&qindex=%F_INDEX%&MSG_ID=%NUM_TICKET%&USER=1&SHOW=1', function (result) {
      jQuery('.chat_data').html(result);
    });
    if (!stop_scroll) {
      jQuery('.chat_data').animate({scrollTop: jQuery('.chat_data')[0].scrollHeight}, 'slow');
    }
    jQuery.post('$SELF_URL', 'header=2&qindex=%F_INDEX%&MSG_ID=%NUM_TICKET%&SENDER=%UID%&COUNT=1', function (count) {
      if (count > jQuery('span.ch_count').text()) {
        jQuery('audio')[0].play();
      }
      jQuery('span.ch_count').text(count);
      if (count > 0 && !jQuery('#fixed-form-container div').hasClass('expanded')) {
        jQuery("#open").addClass('b_green');
        jQuery(".ch_count").show();

        drawJump();
      }
    });
  }

  function drawJump() {
    start = Date.now();

    timer = setInterval(function() {
      let timePassed = Date.now() - start;
      
      if (timePassed >= 1000) {
        clearInterval(timer);
        
        return;
      }

      draw(timePassed, 20);

    }, 20);
  }

  jQuery("#chat_message").keypress(function (event) {
    if (event.which == 13) {
      event.preventDefault();
      jQuery("#btn-subm").trigger("click");
    }
  });

  function change_read() {
    jQuery.post('$SELF_URL', 'header=2&qindex=%F_INDEX%&MSG_ID=%NUM_TICKET%&CHANGE=1');
  }

  function draw(timePassed, px) {
    jQuery('#fixed-form-container').css('bottom', timePassed / px + 'px');
  }
</script>